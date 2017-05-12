package Test2;

sub new {
	my $class = shift;

	my $self = {};

	$self->{a} = 9;
	$self->{b} = 8;
	$self->{_private} = 7;

	bless $self, $class;

	return $self;
}

sub a {
	my $self = shift;
	return $self->{a};
}

sub b {
	my $self = shift;
	return $self->{b};
}

sub _private {
	my $self = shift;
	return $self->{_private};
}

1;

package main;

use Test::More tests => 13;
use Scalar::Util qw(blessed);
use Data::Dumper;

use Table::Simple;

my $table = new Table::Simple;
my $test2 = new Test2;

ok($test2->a == 9, "sanity check");
ok(! $table->_is_moose_object($test2), "is not a moose object");
ok($table->extract_columns($test2), "extract columns");
ok($table->type eq "Test2", "column type is Test2");
ok($table->has_columns == 2, "have 2 columns");
ok($table->get_column("a")->name() eq "a", "get column 'a'");
ok($table->get_column("b")->name() eq "b", "get column 'b'");
ok(! $table->get_column("_private"), "don't have column '_private'");
ok(! $table->extract_columns( [ qw( a b c d ) ] ), "arrayref doesn't work");

my $test3 = new Test2;
ok($table->extract_row($test2), "extract 1st row");
ok($table->extract_row($test3), "extract 2nd row");
ok($table->row_count == 2, "row count is 2");
ok(! $table->extract_columns($test2), "extract columns fails after adding rows");

