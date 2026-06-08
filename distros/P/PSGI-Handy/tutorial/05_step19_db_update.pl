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
# detail page, which in turn links to the edit form added below.
$app->get('/', sub {
    my $c = shift;
    my $users = $c->db->selectall_arrayref(
        "SELECT id, name, age FROM users ORDER BY id", { Slice => {} });
    return $c->render('step19_list.html', { users => $users });
});

# Show the edit form.
$app->get('/user/:id/edit', sub {
    my $c = shift;
    my $user = $c->db->selectrow_hashref(
        "SELECT id, name, age FROM users WHERE id = ?", {}, $c->param('id'));
    return $c->text('User Not Found', 404) unless $user;
    return $c->render('step19_edit.html', { user => $user });
});

# Update the data.
$app->post('/user/:id/edit', sub {
    my $c = shift;
    my $target_id = $c->param('id');

    # UPDATE ... SET ... WHERE with placeholders.
    $c->db->do(
        "UPDATE users SET name = ?, age = ? WHERE id = ?",
        $c->param('name'), $c->param('age'), $target_id);

    # Redirect to the detail page after the update.
    return $c->redirect("/user/$target_id");
});

# Detail page so the redirect target exists.
$app->get('/user/:id', sub {
    my $c = shift;
    my $user = $c->db->selectrow_hashref(
        "SELECT id, name, age FROM users WHERE id = ?", {}, $c->param('id'));
    return $c->text('User Not Found', 404) unless $user;
    return $c->render('step19_detail.html', { user => $user });
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
print "Starting server on http://127.0.0.1:8080/ (Step 19: DB Update)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
