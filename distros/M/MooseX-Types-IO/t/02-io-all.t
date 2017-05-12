#!perl -T

use Test::More tests => 22;
use Test::Exception;

use MooseX::Types::IO::All 'IO_All';
use FindBin qw/$Bin/;

use Moose::Util::TypeConstraints;
isa_ok( find_type_constraint(IO_All), "Moose::Meta::TypeConstraint" );
isa_ok( find_type_constraint('IO::All'), "Moose::Meta::TypeConstraint" );

{
    {
        package Foo;
        use Moose;
	use MooseX::Types::IO::All 'IO_All';

        has io => (
            isa => IO_All,
            is  => "rw",
            coerce => 1,
        );

	# global
        has io2 => (
            isa => 'IO::All',
            is  => "rw",
            coerce => 1,
        );
    }

    for my $accessor (qw/io io2/) {
	my $str = "test for IO::All\n line 2";

	# split on the empty string after newlines
	my @lines = split /(?<=\n)/, $str;

	my $coerced = Foo->new( $accessor => \$str )->$accessor;

	isa_ok( $coerced, "IO::All", "coerced IO::All" );
	ok( $coerced->can('print'), "can print" );
	is( ${ $coerced->string_ref }, $str, 'get string');
	is( $coerced->getline, $lines[0], 'getline 1');
	is( $coerced->getline, $lines[1], 'getline 2');
	is( $coerced->getline, undef, 'getline eof');

	my $filename = "$Bin/00-load.t";
	my $str2 = <<'FC';
#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::Types::IO' );
}

diag( "Testing MooseX::Types::IO $MooseX::Types::IO::VERSION, Perl $], $^X" );
FC
	my $coerced2 = Foo->new( $accessor => $filename )->$accessor;
	isa_ok( $coerced2, "IO::All", "coerced IO::All" );
	ok( $coerced2->can('print'), "can print" );
	is( $coerced2->all, $str2, 'get string');

	throws_ok { Foo->new( $accessor => [\$str2] ) } qr/IO\:\:All/, "constraint";
    }
}


