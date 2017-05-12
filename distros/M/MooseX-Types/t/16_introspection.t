use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::Util qw( has_available_type_export );
BEGIN {
    my @Memory;
    sub store_memory {
        my ($package, @types) = @_;
        for my $type (@types) {
            my $tc     = has_available_type_export($package, $type);
            push @Memory, [$package, $type, $tc ? $tc->name : undef];
        }
    }
    sub get_memory { \@Memory }
}

use lib 't/lib';

{
    package IntrospectionTest;
    BEGIN { main::store_memory(__PACKAGE__, qw( TwentyThree NonEmptyStr MyNonEmptyStr )) }
    use TestLibrary             qw( TwentyThree );
    BEGIN { main::store_memory(__PACKAGE__, qw( TwentyThree NonEmptyStr MyNonEmptyStr )) }
    use TestLibrary             NonEmptyStr => { -as => 'MyNonEmptyStr' };
    BEGIN { main::store_memory(__PACKAGE__, qw( TwentyThree NonEmptyStr MyNonEmptyStr )) }

    sub NotAType () { 'just a string' }

    BEGIN {
        eval {
            main::store_memory(__PACKAGE__, qw( NotAType ));
        };
        ::ok(!$@, "introspecting something that's not not a type doesn't blow up");
    }

    BEGIN {
        no strict 'refs';
        delete ${'IntrospectionTest::'}{TwentyThree};
    }
}

BEGIN { main::store_memory( IntrospectionTest => qw( TwentyThree NonEmptyStr MyNonEmptyStr )) }

my $P = 'IntrospectionTest';

is_deeply(get_memory, [
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

done_testing();
