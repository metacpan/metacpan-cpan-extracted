use v5.20;
use utf8;
use open qw(:std :utf8);

use Test::More;
use Data::Dumper;

my $class = require './Makefile.PL';

my $warnings;
$SIG{__WARN__} = sub { $warnings = $_[0] };
my $warning_regex = qr/Possible unintended interpolation of a redactable string/;

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, qw(new placeholder);
	isa_ok my $obj = $class->new('1234'), $class;

	ok defined $obj->placeholder, 'placeholder is defined';
	ok length $obj->placeholder, 'placeholder has a non-zero length';
	};


subtest 'two' => sub {
	my( $first_raw, $second_raw ) = qw( abcg 137 );
	my $first  = $class->new( $first_raw, { key => 'jklo'} );
	my $second = $class->new( $second_raw, { key => '6781'} );

	is $first->to_str_unsafe, $first_raw, 'first one roundtrips';
	is $second->to_str_unsafe, $second_raw, 'second one roundtrips';
	};

done_testing();
