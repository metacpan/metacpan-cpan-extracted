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

$app->get('/', sub {
    my $c = shift;

    # Fetch every row from each of the two tables.
    my $users = $c->db->selectall_arrayref(
        "SELECT id, name, dept_id FROM users ORDER BY id", { Slice => {} });
    my $depts = $c->db->selectall_arrayref(
        "SELECT id, name FROM depts ORDER BY id", { Slice => {} });

    # Build a lookup: department id => department name.
    my %dept_map;
    my $dept;
    for $dept (@$depts) {
        $dept_map{ $dept->{id} } = $dept->{name};
    }

    # Attach the department name to each user (a hand-made JOIN).
    my $user;
    for $user (@$users) {
        my $d_id = $user->{dept_id};
        $user->{dept_name} =
            (defined $d_id && exists $dept_map{$d_id})
            ? $dept_map{$d_id} : 'Unassigned';
    }

    return $c->render('step21_join_list.html', { users => $users });
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
print "Starting server on http://127.0.0.1:8080/ (Step 21: JOIN List)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
