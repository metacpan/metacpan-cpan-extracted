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

feature '(Precheck that "vampire for" is valid)'
     => q{{ for (;;) {} }};

feature 'Octal constants'
     => q{{ my $x = 0o7777; }};

feature 'Try/catch blocks'
     => q{{
            try {
                do_something_risky();
            }

            catch ($error) {
                do_something_catchy($error);
            }

            for (;;) {}
        }};


done_testing();


sub feature {
    state $STATEMENT = qr{ \A (?&PerlBlock) \s* \Z  $PPR::GRAMMAR }xms;

    my ($desc, $syntax) = @_;
    ok $syntax =~ $STATEMENT => $desc;
}


