use 5.010;
use strict;
use warnings;

use Test::More;

plan tests => 4;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

use PPR;
sub feature;

feature 'Can now delete via k/v slices'
     => q{ delete %hash{'k', 'v', 'slice'} };

feature 'Can initialize array state variables'
     => q{ state @array = (1,2,3) };

feature 'Can initialize hash state variables'
     => q{ state %hash = (a=>2, b=>4) };

feature 'Named equivalents for various (?X...) regex constructs'
     => q{ m{ (*atomic: x )
              (*negative_lookahead:  X )    (*nla: X )
              (*negative_lookbehind: X )    (*nlb: X )
              (*positive_lookahead:  X )    (*pla: X )
              (*positive_lookbehind: X )    (*plb: X )
              (*sr: X )                     (*asr: X )
            }
         };


done_testing();


sub feature {
    state $STATEMENT = qr{ \A (?&PerlStatement) \s* \Z  $PPR::GRAMMAR }xms;

    my ($desc, $syntax) = @_;
    ok $syntax =~ $STATEMENT => $desc;
}
