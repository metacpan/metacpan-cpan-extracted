use 5.010;
use strict;
use warnings;

use Test::More;

plan tests => 3;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

use PPR;
sub feature;

feature 'Higher upper limit on counted repetions in regexes'
     => q{ / x{2,65534} ) / };

feature 'Can specify unicode properties in a regex via a nested regex'
     => q{ qr( \p{nv=/\A[0-5]\z/} ) };

feature 'Can specify variable-length lookbehinds in regexes'
     => q{ / (?<= colou?r ) (?<! aw{2,5} ) / };


done_testing();


sub feature {
    state $STATEMENT = qr{ \A (?&PerlStatement) \s* \Z  $PPR::GRAMMAR }xms;

    my ($desc, $syntax) = @_;
    ok $syntax =~ $STATEMENT => $desc;
}

