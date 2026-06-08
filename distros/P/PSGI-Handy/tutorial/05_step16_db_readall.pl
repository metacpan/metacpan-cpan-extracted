#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;
use HP::Handy;
use DB::Handy;   # load the database module

# View: HP::Handy reads templates from the 'templates' directory.
my $hp = HP::Handy->new( template_dir => 'templates', auto_escape => 1 );
my $renderer = sub {
    my ($name, $vars) = @_;
    return $hp->render_file($name, $vars);
};

# Model: connect with the DBI-style interface. DB::Handy->connect creates
# the data directory and the 'app' database on first use.
my $dbh = DB::Handy->connect('data', 'app', { RaiseError => 0, PrintError => 0 });
die "DB connect failed\n" unless $dbh;
_bootstrap($dbh);

# Inject both the renderer and the database handle.
my $app = PSGI::Handy->new( renderer => $renderer, db => $dbh );

$app->get('/', sub {
    my $c = shift;
    # Fetch every row from the 'users' table.
    my $users = $c->db->selectall_arrayref(
        "SELECT id, name, age FROM users ORDER BY id", { Slice => {} });
    return $c->render('step16_list.html', { users => $users });
});

# Create the table and seed it once (idempotent, so each example runs
# standalone).
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
print "Starting server on http://127.0.0.1:8080/ (Step 16: DB Read All)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
