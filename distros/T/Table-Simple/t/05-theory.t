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

use Test::More tests => 9;

use Table::Simple;
use Table::Simple::Output::Theory;

my $table = new Table::Simple;
my $test1 = Test1->new( a => 1, b => 2 );

ok($test1->a == 1, "sanity check");
ok($table->_is_moose_object($test1), "is a moose object");
ok($table->extract_columns($test1), "extract columns");
ok($table->has_columns == 2, "have 2 columns");
ok($table->get_column("a")->name() eq "a", "get column 'a'");
ok($table->get_column("b")->name() eq "b", "get column 'b'");

my $test4 = Test1->new( a => "foo", b => "bar" );
ok($table->extract_row($test1), "extract 1st row");
ok($table->extract_row($test4), "extract 2nd row");
ok($table->row_count == 2, "row count is 2");

$table->get_column("b")->output_format("right_justify");

my $output = Table::Simple::Output::Theory->new( table => $table );
$table->name("Test");
$output->print_table;

