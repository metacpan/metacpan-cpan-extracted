#!/usr/bin/perl

use strict;
use warnings;

use Carp ();
use Symbol ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 38;

{
    package Symbol::Util::Test10::NoImport;

    eval q{
        require Symbol::Util;
        Symbol::Util->import;
    };
};

is( $@, '', 'use Symbol::Util' );
is_deeply( [ keys %{*Symbol::Util::Test10::NoImport::} ], [], 'no functions imported' );

my @functions = qw(
    delete_glob
    delete_sub
    export_glob
    export_package
    fetch_glob
    list_glob_slots
    stash
    unexport_package
);

{
    package Symbol::Util::Test10::AllImport;

    eval q{
        require Symbol::Util;
        Symbol::Util->import(":all");
    };
};

is( $@, '', 'use Symbol::Util ":all"' );
is_deeply( [ sort keys %{*Symbol::Util::Test10::AllImport::} ], [ @functions ], 'all functions imported' );

{
    package Symbol::Util::Test10::AllImport;

    eval q{
        Symbol::Util->unimport;
    };
};

is( $@, '', 'no Symbol::Util [1]' );
is_deeply( [ sort keys %{*Symbol::Util::Test10::AllImport::} ], [], 'all functions unimported [1]' );

foreach my $function (@functions) {
    {
        eval qq{
            package Symbol::Util::Test10::SomeImport::$function;

            require Symbol::Util;
            Symbol::Util->import("$function");
        };
    };

    is( $@, '', "use Symbol::Util \"$function\"" );
    {
        no strict 'refs';
        is_deeply( [ sort keys %{ *{"Symbol::Util::Test10::SomeImport::${function}::"} } ], [ $function ], "$function function imported" );
    };

    {
        package Symbol::Util::Test10::AllImport;

        eval qq{
            package Symbol::Util::Test10::SomeImport::$function;

            Symbol::Util->unimport;
        };
    };

    is( $@, '', 'no Symbol::Util [2]' );
    {
        no strict 'refs';
        is_deeply( [ sort keys %{*Symbol::Util::Test10::AllImport::} ], [], 'all functions unimported [2]' );
    };

};
