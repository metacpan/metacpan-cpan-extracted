#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Sub::QuoteX::Utils qw[ quote_subs ];


# basic test that tests will work

subtest 'tests' => sub {

    # test that using lexicals that are not declared causes an error
    # on Perl < 5.10, the use strict in this context isn't propagated
    # into the quoted sub, so explicitly use strict

    ok( lives { quote_subs( \q{my $xxxx = 33;} )->() }, "declaration" );

    # ignore error message, as that changes between Perl versions.
    # this code is simple enough
    ok(
        ! lives {
            quote_subs( \q{use strict;}, \q{$xxxx = 33;} )->();
        },
        "no declaration"
    ) or bail_out( "can't detect if declaration is required\n" );

};

subtest 'lexicals' => sub {

    ok(
        lives {
            quote_subs( \q{use strict;},
                        \q{$xxxx = 33;},
			{ lexicals => '$xxxx' }
		) ->()
        },
        "scalar"
    );

    ok(
        lives {
            quote_subs( \q{use strict;},
			\q{$xxxx = 33;},
			\q{$yyyy = 44;},
                { lexicals => [ '$xxxx', '$yyyy' ] } )->()
        },
        "array"
    );

};

done_testing;
