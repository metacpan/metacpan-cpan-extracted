use strict;
use warnings;

use Test::LeakTrace qw( no_leaks_ok );
use Test::More;

use Params::Validate qw( validate );

subtest(
    'callback with default error' => sub {
        no_leaks_ok( sub { val1( foo => 42 ); }, 'validation passes' );
        local $TODO = 'Not sure if all the leaks are in Carp or not';
        no_leaks_ok(
            sub {
                eval { val1( foo => 'forty two' ) };
            },
            'validation fails'
        );
    },
);

subtest(
    'callback that dies with string' => sub {
        no_leaks_ok( sub { val2( foo => 42 ); }, 'validation passes' );
        local $TODO = 'Not sure if all the leaks are in Carp or not';
        no_leaks_ok(
            sub {
                eval { val2( foo => 'forty two' ) };
            },
            'validation fails'
        );
    },
);

subtest(
    'callback that dies with object' => sub {
        no_leaks_ok( sub { val3( foo => 42 ); }, 'validation passes' );
        no_leaks_ok(
            sub {
                eval { val3( foo => 'forty two' ) };
            },
            'validation fails'
        );
    },
);

done_testing();

sub val1 {
    validate(
        @_,
        {
            foo => {
                callbacks => {
                    'is int' => sub { $_[0] =~ /^[0-9]+$/ }
                }
            },
        },
    );
}

sub val2 {
    validate(
        @_,
        {
            foo => {
                callbacks => {
                    'is int' => sub {
                        $_[0] =~ /^[0-9]+$/ or die "$_[0] is not an integer";
                    }
                }
            },
        },
    );
}

sub val3 {
    validate(
        @_,
        {
            foo => {
                callbacks => {
                    'is int' => sub {
                        $_[0] =~ /^[0-9]+$/
                            or die { error => "$_[0] is not an integer" };
                    }
                }
            },
        },
    );
}
