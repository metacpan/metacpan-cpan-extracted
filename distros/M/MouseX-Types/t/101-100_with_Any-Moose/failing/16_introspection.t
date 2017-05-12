#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 2;

use FindBin;
use lib "$FindBin::Bin/lib";

do {
    package IntrospectionTest;
    use IntrospectTypeExports   __PACKAGE__, qw( TwentyThree NonEmptyStr MyNonEmptyStr );
    use TestLibrary             qw( TwentyThree );
    use IntrospectTypeExports   __PACKAGE__, qw( TwentyThree NonEmptyStr MyNonEmptyStr );
    use TestLibrary             NonEmptyStr => { -as => 'MyNonEmptyStr' };
    use IntrospectTypeExports   __PACKAGE__, qw( TwentyThree NonEmptyStr MyNonEmptyStr );

    sub NotAType () { 'just a string' }

    BEGIN {
        eval {
            IntrospectTypeExports->import(__PACKAGE__, qw( NotAType ));
        };
        ::ok(!$@, "introspecting something that's not not a type doesn't blow up");
    }

    BEGIN { 
        no strict 'refs'; 
        delete ${'IntrospectionTest::'}{TwentyThree};
    }
};

use IntrospectTypeExports IntrospectionTest => qw( TwentyThree NonEmptyStr MyNonEmptyStr );

my $P = 'IntrospectionTest';

is_deeply(IntrospectTypeExports->get_memory, [

    [$P, TwentyThree    => undef],
    [$P, NonEmptyStr    => undef],
    [$P, MyNonEmptyStr  => undef],

    [$P, TwentyThree    => 'TestLibrary::TwentyThree'],
    [$P, NonEmptyStr    => undef],
    [$P, MyNonEmptyStr  => undef],

    [$P, TwentyThree    => 'TestLibrary::TwentyThree'],
    [$P, NonEmptyStr    => undef],
    [$P, MyNonEmptyStr  => 'TestLibrary::NonEmptyStr'],

    [$P, NotAType       => undef],

    [$P, TwentyThree    => undef],
    [$P, NonEmptyStr    => undef],
    [$P, MyNonEmptyStr  => 'TestLibrary::NonEmptyStr'],

], 'all calls to has_available_type_export returned correct results');

