#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;
use HP::Handy;
use DB::Handy;

my $hp = HP::Handy->new( template_dir => 'templates', auto_escape => 1 );
my $renderer = sub {
    my ($name, $vars) = @_;
    return $hp->render_file($name, $vars);
};

my $dbh = DB::Handy->connect('data', 'app2', { RaiseError => 0, PrintError => 0 });
die "DB connect failed\n" unless $dbh;
_bootstrap($dbh);

my $app = PSGI::Handy->new( renderer => $renderer, db => $dbh );

# Index page so the step is runnable from "/": the employee list plus a
# link to the dropdown add form this step introduces.
$app->get('/', sub {
    my $c = shift;
    my $users = $c->db->selectall_arrayref(
        "SELECT id, name, dept_id FROM users ORDER BY id", { Slice => {} });
    my $depts = $c->db->selectall_arrayref(
        "SELECT id, name FROM depts ORDER BY id", { Slice => {} });
    my %dept_map;
    my $d;
    for $d (@$depts) { $dept_map{ $d->{id} } = $d->{name}; }
    my $u;
    for $u (@$users) {
        my $d_id = $u->{dept_id};
        $u->{dept_name} =
            (defined $d_id && exists $dept_map{$d_id})
            ? $dept_map{$d_id} : 'Unassigned';
    }
    return $c->render('step23_list.html', { users => $users });
});

$app->get('/add', sub {
    my $c = shift;
    # Fetch the department master so the form can render a dropdown.
    my $depts = $c->db->selectall_arrayref(
        "SELECT id, name FROM depts ORDER BY id", { Slice => {} });
    return $c->render('step23_form_select.html', { depts => $depts });
});

# Insert the submitted employee. DB::Handy has no AUTO_INCREMENT column, so
# the next id is computed as max(id)+1 (formalized as a helper in Step 24).
$app->post('/add', sub {
    my $c = shift;
    my $rows = $c->db->selectall_arrayref("SELECT id FROM users", { Slice => {} });
    my $max = 0;
    my $r;
    for $r (@$rows) {
        $max = $r->{id} if defined $r->{id} && $r->{id} > $max;
    }
    my $id = $max + 1;
    $c->db->do(
        "INSERT INTO users (id, name, dept_id) VALUES (?, ?, ?)",
        $id, $c->param('name'), $c->param('dept_id'));
    return $c->redirect('/');
});

# Create the two tables and seed them once (idempotent).
sub _bootstrap {
    my ($h) = @_;
    my $tables = $h->table_info;
    my %have;
    my $t;
    for $t (@$tables) { $have{ $t->{TABLE_NAME} } = 1; }
    return if $have{users} && $have{depts};

    unless ($have{depts}) {
        $h->do("CREATE TABLE depts (id INT, name VARCHAR(20))");
        my @ds = ([1,'Engineering'], [2,'Sales'], [3,'HR']);
        my $d;
        for $d (@ds) { $h->do("INSERT INTO depts (id, name) VALUES (?, ?)", @$d); }
    }
    unless ($have{users}) {
        $h->do("CREATE TABLE users (id INT, name VARCHAR(40), dept_id INT)");
        my @us = ([1,'Alice',1], [2,'Bob',2], [3,'Charlie',1]);
        my $u;
        for $u (@us) { $h->do("INSERT INTO users (id, name, dept_id) VALUES (?, ?, ?)", @$u); }
    }
}

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 23: Select Form)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
