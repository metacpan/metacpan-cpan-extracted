use 5.010;
use strict;
use warnings;

use Test::More;

plan tests => 1;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

use PPR;
sub feature;

feature 'New binary infix isa operator'
     => q{ $invocant isa $class };

done_testing();


sub feature {
    state $STATEMENT = qr{ \A (?&PerlStatement) \s* \Z  $PPR::GRAMMAR }xms;

    my ($desc, $syntax) = @_;
    ok $syntax =~ $STATEMENT => $desc;
}

