#! perl

use warnings;
use strict;
use Test::More;

my $tests = 0;

use_ok('String::Interpolate::Named');
$tests++;

my $s = { keypattern => qr/a+/,
	  args => { a       => "one",
		    aa      => "",
		    aaa     => "three",
		    b       => "Eins",
		    bb      => "Zwo",
		    ab      => "yes",
		  },
	};

while ( <DATA> ) {
    next if /^#/;
    next unless /\S/;
    chomp;

    my ( $tpl, $exp ) = split( /\t+/, $_ );
    my $res = interpolate( $s, $tpl );
    is( $res, $exp, "$tpl -> $exp" );

    $tests++;
}

done_testing($tests);

__DATA__
# Valid
ab%{a}def		abonedef
ab%{aa}def		abdef
%{aaa}def		threedef

# Not valid
ab%{b}def		ab%{b}def
ab%{bb}def		ab%{bb}def
%{ab}def		%{ab}def
