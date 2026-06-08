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

# Helper: attach department names to a list of users.
sub _attach_dept_names {
    my ($c, $users) = @_;
    my $depts = $c->db->selectall_arrayref(
        "SELECT id, name FROM depts ORDER BY id", { Slice => {} });
    my %dept_map;
    my $d;
    for $d (@$depts) { $dept_map{ $d->{id} } = $d->{name}; }
    my $u;
    for $u (@$users) {
        $u->{dept_name} =
            (defined $u->{dept_id} && exists $dept_map{ $u->{dept_id} })
            ? $dept_map{ $u->{dept_id} } : 'Unassigned';
    }
}

# Helper: compute the next id (DB::Handy has no AUTO_INCREMENT column).
sub _next_id {
    my ($c) = @_;
    my $rows = $c->db->selectall_arrayref(
        "SELECT id FROM users", { Slice => {} });
    my $max = 0;
    my $r;
    for $r (@$rows) {
        $max = $r->{id} if defined $r->{id} && $r->{id} > $max;
    }
    return $max + 1;
}

# 1. List (Read All).
$app->get('/', sub {
    my $c = shift;
    my $users = $c->db->selectall_arrayref(
        "SELECT id, name, dept_id FROM users ORDER BY id", { Slice => {} });
    _attach_dept_names($c, $users);
    return $c->render('app_list.html', { users => $users });
});

# 2. Show the add form (Create Form).
$app->get('/add', sub {
    my $c = shift;
    my $depts = $c->db->selectall_arrayref(
        "SELECT id, name FROM depts ORDER BY id", { Slice => {} });
    return $c->render('app_form.html',
        { action => '/add', user => {}, depts => $depts });
});

# 3. Perform the insert (Create Action).
$app->post('/add', sub {
    my $c = shift;
    my $id = _next_id($c);
    $c->db->do(
        "INSERT INTO users (id, name, dept_id) VALUES (?, ?, ?)",
        $id, $c->param('name'), $c->param('dept_id'));
    return $c->redirect('/');
});

# 4. Show the detail / update form (Read One & Update Form).
$app->get('/user/:id', sub {
    my $c = shift;
    my $user = $c->db->selectrow_hashref(
        "SELECT id, name, dept_id FROM users WHERE id = ?", {}, $c->param('id'));
    return $c->text('Not Found', 404) unless $user;

    my $depts = $c->db->selectall_arrayref(
        "SELECT id, name FROM depts ORDER BY id", { Slice => {} });
    return $c->render('app_form.html', {
        action => '/user/' . $user->{id} . '/edit',
        user   => $user,
        depts  => $depts,
    });
});

# 5. Perform the update (Update Action).
$app->post('/user/:id/edit', sub {
    my $c = shift;
    $c->db->do(
        "UPDATE users SET name = ?, dept_id = ? WHERE id = ?",
        $c->param('name'), $c->param('dept_id'), $c->param('id'));
    return $c->redirect('/');
});

# 6. Perform the delete (Delete Action).
$app->post('/user/:id/delete', sub {
    my $c = shift;
    $c->db->do("DELETE FROM users WHERE id = ?", $c->param('id'));
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
print "Starting FULL STACK APP on http://127.0.0.1:8080/\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
