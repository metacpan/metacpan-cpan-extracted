#!/usr/bin/perl

use strict;

BEGIN {
	$^W = 1;
}

use Test::More;
use Test::Differences;
use PPI;

BEGIN {
	if ( $PPI::VERSION =~ /_/ ) {
		plan skip_all => "Need released version of PPI. You have $PPI::VERSION";
		exit 0;
	}
}

plan tests => 10;

use PPIx::EditorTools::IntroduceTemporaryVariable;

my $code = <<'END_CODE';
use strict; use warnings;
    my $x = ( 1 + 10 / 12 ) * 2;
    my $y = ( 3 + 10 / 12 ) * 2;
END_CODE

my $new_code = PPIx::EditorTools::IntroduceTemporaryVariable->new->introduce(
	code           => $code,
	start_location => [ 2, 19 ], # or just character position
	end_location   => [ 2, 25 ], # or ppi-style location
	varname        => '$foo',
);
isa_ok( $new_code,          'PPIx::EditorTools::ReturnObject' );
isa_ok( $new_code->element, 'PPI::Token' );
location_is( $new_code->element, [ 2, 5, 5 ], 'temp var location' );
eq_or_diff( $new_code->code, <<'RESULT', '10 / 12' );
use strict; use warnings;
    my $foo = 10 / 12;
    my $x = ( 1 + $foo ) * 2;
    my $y = ( 3 + $foo ) * 2;
RESULT

$new_code = PPIx::EditorTools::IntroduceTemporaryVariable->new->introduce(
	code           => $code,
	start_location => [ 2, 13 ], # or just character position
	end_location   => [ 2, 27 ], # or ppi-style location
	varname        => '$foo',
);

eq_or_diff( $new_code->code, <<'RESULT', '( 1 + 10 / 12 )' );
use strict; use warnings;
    my $foo = ( 1 + 10 / 12 );
    my $x = $foo * 2;
    my $y = ( 3 + 10 / 12 ) * 2;
RESULT

$code = <<'END_CODE2';
use strict; use warnings;
my $x = ( 1 + 10
    / 12 ) * 2;
my $y = ( 3 + 10 / 12 ) * 2;
END_CODE2

$new_code = PPIx::EditorTools::IntroduceTemporaryVariable->new->introduce(
	code           => $code,
	start_location => [ 2, 9 ],  # or just character position
	end_location   => [ 3, 10 ], # or ppi-style location
	                             # varname        => '$foo',
);
eq_or_diff( $new_code->code, <<'RESULT', '( 1 + 10 \n / 12 )' );
use strict; use warnings;
my $tmp = ( 1 + 10
    / 12 );
my $x = $tmp * 2;
my $y = ( 3 + 10 / 12 ) * 2;
RESULT

my $code3 = <<'END_CODE3';
use strict; use warnings;
sub one {
    my $x = ( 1 + 10 / 12 ) * 2;
    my $y = ( 3 + 10 / 12 ) * 2;
}
sub two {
    my $y = ( 3 + 10 / 12 ) * 2;
}
END_CODE3

my $new_code3 = PPIx::EditorTools::IntroduceTemporaryVariable->new->introduce(
	code           => $code3,
	start_location => [ 3, 19 ], # or just character position
	end_location   => [ 3, 25 ], # or ppi-style location
	varname        => '$foo',
);
isa_ok( $new_code3,          'PPIx::EditorTools::ReturnObject' );
isa_ok( $new_code3->element, 'PPI::Token' );
location_is( $new_code3->element, [ 3, 5, 5 ], 'temp var location' );

TODO: {
	local $TODO = 'Bug: RT#60042 - replace does not respect lexical scope';

	eq_or_diff( $new_code3->code, <<'RESULT3', 'lexically scoped' );
use strict; use warnings;
sub one {
    my $foo = 10 / 12;
    my $x = ( 1 + $foo ) * 2;
    my $y = ( 3 + $foo ) * 2;
}
sub two {
    my $y = ( 3 + 10 / 12 ) * 2;
}
RESULT3

}

sub location_is {
	my ( $element, $location, $desc ) = @_;

	my $elem_loc = $element->location;
	$elem_loc = [ @$elem_loc[ 0 .. 2 ] ] if @$elem_loc > 3;
	is_deeply( $elem_loc, $location, $desc );
}
