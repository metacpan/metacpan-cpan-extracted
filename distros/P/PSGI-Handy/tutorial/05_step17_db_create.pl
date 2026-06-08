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

# Show the add form.
$app->get('/add', sub {
    my $c = shift;
    return $c->render('step17_form.html');
});

# Insert the submitted data.
$app->post('/add', sub {
    my $c = shift;

    # Insert one row with an INSERT statement and placeholders.
    $c->db->do(
        "INSERT INTO users (id, name, age) VALUES (?, ?, ?)",
        $c->param('id'), $c->param('name'), $c->param('age'));

    # Redirect to the list page (root) after completion.
    return $c->redirect('/');
});

# List page so the redirect target exists.
$app->get('/', sub {
    my $c = shift;
    my $users = $c->db->selectall_arrayref(
        "SELECT id, name, age FROM users ORDER BY id", { Slice => {} });
    return $c->render('step17_list.html', { users => $users });
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
print "Starting server on http://127.0.0.1:8080/ (Step 17: DB Create)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
