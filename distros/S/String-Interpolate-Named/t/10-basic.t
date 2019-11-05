#! perl

use warnings;
use strict;
use Test::More;

my $tests = 0;

-d "t" && chdir("t");

use_ok('String::Interpolate::Named');
$tests++;

# Using functional interface.
my $s = { args => { title     => "Hi There!",
		    subtitle  => [ "%{capo|CAPO %{}}" ],
		    capo      => [ 1 ],
		    key	      => [ "G" ],
		    h	      => [ "Z" ],
		    head      => [ "yes" ],
		  },
	};

@ARGV = qw( 10-basic.dat );
foreach ( @ARGV ) {
    -s -r $_ ? pass("check $_") : BAIL_OUT("$_ [$!]");
    $tests++;
}

while ( <> ) {
    next if /^#/;
    next unless /\S/;
    chomp;

    my ( $tpl, $exp ) = split( /\t+/, $_ );
    my $res = interpolate( $s, $tpl );
    is( $res, $exp, "$tpl -> $exp" );

    $tests++;
}

done_testing($tests);
