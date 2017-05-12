# -*- perl -*-

# t/03_insert.t - insert tests

use Test::More tests => 2;
use SQLite::Abstract;

my $database = q/__testDATABASE__/;
my $tablename = q/__testTABLE__/;

my @data = ();

my $sql = SQLite::Abstract->new($database);

$sql->table($tablename);

for('a'..'zz'){
	push @data, [undef, $_, 'password_'.$_, 'account_'.$_ ];
}

my @cols = qw(id name password account);

is($sql->insert(\@cols, \@data), scalar @data, "insert test, descr syntax");
is($sql->insert(\@data), scalar @data, "insert test, short syntax");
	 
