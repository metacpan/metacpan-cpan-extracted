use Test::More;

use strict;
use warnings;

use PDL::DSP::Windows;

use lib 't/lib';
use MyTest::Helper qw( warnings );

subtest winpersubs => sub {
    for my $key ( keys %PDL::DSP::Windows::winpersubs ) {
        my @warnings = warnings {
            ok +PDL::DSP::Windows->can("${key}_per"),
                "$key points to defined periodic window";

            is ref $PDL::DSP::Windows::winsubs{$key}, 'CODE',
                "$key is mapped to coderef";

            ok exists $PDL::DSP::Windows::window_definitions{$key},
                "$key has defined metadata";
        };

        is scalar @warnings, 2, 'Caught two warnings';
        like $_, qr/Package variables .* are deprecated .* attempt to read/,
            'window_definitions warned on read' for @warnings;
    }
};

subtest winsubs => sub {
    for my $key ( keys %PDL::DSP::Windows::winsubs ) {
        my @warnings = warnings {
            ok +PDL::DSP::Windows->can($key),
                "$key points to defined symmetric window";

            is ref $PDL::DSP::Windows::winsubs{$key}, 'CODE',
                "$key is mapped to coderef";

            ok exists $PDL::DSP::Windows::window_definitions{$key},
                "$key has defined metadata";
        };

        is scalar @warnings, 2, 'Caught two warnings';
        like $_, qr/Package variables .* are deprecated .* attempt to read/,
            'window_definitions warned on read' for @warnings;

    }
};

subtest window_definitions => sub {
    for my $key ( keys %PDL::DSP::Windows::window_definitions ) {
        my @warnings = warnings {
            ok +PDL::DSP::Windows->can($key),
                "$key points to defined window";

            ok exists $PDL::DSP::Windows::winsubs{$key},
                "$key window is in symmetric map";
        };

        is scalar @warnings, 1, 'Caught a single warning';
        like $_, qr/Package variables .* are deprecated .* attempt to read/,
            'window_definitions warned on read' for @warnings;

        next unless PDL::DSP::Windows->can("${key}_per");

        @warnings = warnings {
            ok exists $PDL::DSP::Windows::winpersubs{$key},
                "$key window is in periodic map";
        };

        is scalar @warnings, 1, 'Caught a single warning';
        like $_, qr/Package variables .* are deprecated .* attempt to read/,
            'window_definitions warned on read' for @warnings;
    }
};

subtest writes => sub {
    my @warnings = warnings {
        $PDL::DSP::Windows::window_definitions{'hamming'} = 1;
        $PDL::DSP::Windows::winsubs{'hamming'} = 1;
        $PDL::DSP::Windows::winpersubs{'hamming'} = 1;
    };

    is scalar @warnings, 3, 'Caught three warnings';
    like $_, qr/Package variables .* are deprecated .* attempt to write/,
        'window_definitions warned on write' for @warnings;
};

done_testing;
