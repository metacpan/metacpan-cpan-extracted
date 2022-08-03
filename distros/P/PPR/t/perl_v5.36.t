use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

plan tests => 6;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

use PPR;
sub feature;

feature '(Precheck that "vampire for" is valid)'
     => q{{ for (;;) {} }};

feature 'Try blocks with finally'
     => q{{
            try {
                do_something_risky();
            }

            catch ($error) {
                do_something_catchy($error);
            }

            finally {
                do_something_final();
            }

            for (;;) {}
        }};


feature 'Defer blocks'
     => q{{
            defer {
                do_something_later();
            }

            for (;;) {}
        }};


feature 'Multi-iterator for loops'
     => q{{
            for my ($x, $y) (@list) {
                do_something_with($x, $y);
            }

            for (;;) {}
        }};


feature 'Unicode double-angle bracket delimiters on quotelikes'
     => q{{
            say  q« double angles   »;
        }};

feature 'Other Unicode bracket delimiters on quotelikes'
     => q{{
            say  q» double angles   «;
            say qq❲ tortoise shells ❳;
            say  m｢ corner brackets ｣;
            say  s→ arrows ←↪ swoopy arrows ↩s;
            say  tr꧁  Javanese rerenggan ꧂ 
                 👉 check it out! 👈;
        }};


done_testing();


sub feature {
    state $STATEMENT = qr{ \A (?&PerlBlock) \s* \Z  $PPR::GRAMMAR }xms;

    my ($desc, $syntax) = @_;
    ok $syntax =~ $STATEMENT => $desc;
}



