#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

# Module loading and warning setup are the same as Step 16.
use PSGI::Handy;
use HTTP::Handy;
use HP::Handy;
use DB::Handy;

my $hp = HP::Handy->new( template_dir => 'templates', auto_escape => 1 );
my $renderer = sub {
    my ($name, $vars) = @_;
    return $hp->render_file($name, $vars);
};

my $dbh = DB::Handy->connect('data', 'app', { RaiseError => 0, PrintError => 0 });
die "DB connect failed\n" unless $dbh;
_bootstrap($dbh);

my $app = PSGI::Handy->new( renderer => $renderer, db => $dbh );

# List page so the step is runnable from "/": each name links to its
# /user/:id detail page (the feature this step adds).
$app->get('/', sub {
    my $c = shift;
    my $users = $c->db->selectall_arrayref(
        "SELECT id, name, age FROM users ORDER BY id", { Slice => {} });
    return $c->render('step18_list.html', { users => $users });
});

# Show the detail of a single user.
$app->get('/user/:id', sub {
    my $c = shift;
    my $target_id = $c->param('id');

    # Fetch exactly one row by primary key.
    my $user = $c->db->selectrow_hashref(
        "SELECT id, name, age FROM users WHERE id = ?", {}, $target_id);

    if ($user) {
        return $c->render('step18_detail.html', { user => $user });
    } else {
        return $c->text('User Not Found', 404);
    }
});

# Create the table and seed it once (idempotent).
sub _bootstrap {
    my ($h) = @_;
    my $tables = $h->table_info;
    my %have;
    my $t;
    for $t (@$tables) { $have{ $t->{TABLE_NAME} } = 1; }
    return if $have{users};
    $h->do("CREATE TABLE users (id INT, name VARCHAR(40), age INT)");
    my @seed = ([1,'Alice',20], [2,'Bob',22], [3,'Charlie',25]);
    my $row;
    for $row (@seed) {
        $h->do("INSERT INTO users (id, name, age) VALUES (?, ?, ?)", @$row);
    }
}

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 18: DB Read One)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
