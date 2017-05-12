package Test1;
use Moose;
use namespace::autoclean;

has 'a' => (
	is => 'rw',
);	

has 'b' => (
	is => 'rw'
);

has '_private' => (
	is => 'ro',
	default => q{Please don't see this.},
);

sub foobar {
	my $self = shift;

	return "kweepa";
}

1;

package main;

use Test::More tests => 11;
use Scalar::Util qw(blessed);
use Data::Dumper;

use Table::Simple;

my $table = new Table::Simple;
my $test1 = Test1->new( a => 1, b => 2 );

ok($test1->a == 1, "sanity check");
ok($table->_is_moose_object($test1), "is a moose object");
ok($table->_is_private_attribute("_private_test"), "private method detection");
my $test4 = Test1->new( a => 9, b => 8 );
ok($table->extract_row($test1), "extract 1st row");
ok($table->has_columns == 2, "have 2 columns");
ok($table->get_column("a")->name() eq "a", "get column 'a'");
ok($table->get_column("b")->name() eq "b", "get column 'b'");
ok(! $table->get_column("_private"), "don't have column '_private'");
ok($table->extract_row($test4), "extract 2nd row");
ok($table->row_count == 2, "row count is 2");
ok(! $table->extract_columns($test4), "extract columns fail after adding rows");
