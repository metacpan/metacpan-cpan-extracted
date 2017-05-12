
# $Id: test.t 7587 2011-04-16 16:00:36Z jonasbn $

use strict;
use warnings;

use Env qw($TEST_VERBOSE);
use Data::Dumper;
use Test::More qw(no_plan);

use_ok 'Perl::Critic::Policy::logicLAB::RequireParamsValidate';

require Perl::Critic;
my $critic = Perl::Critic->new(
    '-profile'       => '',
    '-single-policy' => 'logicLAB::RequireParamsValidate'
);
{
    my @p = $critic->policies;
    is( scalar @p, 1, 'single policy RequireParamsValidate' );

    my $policy = $p[0];

    if ($TEST_VERBOSE) {
        diag Dumper $policy;
    }
}

my $str = q{#!/usr/bin/env perl

# $Id$

use strict;
use warnings;
use Params::Validate qw(:all);

foo();
bar();
_baz();

exit 0;

# takes named params (hash or hashref)
sub foo {
    validate(
        @_, {
            foo => 1,    # mandatory
            bar => 0,    # optional
        }
    );
}

sub bar {
    return 1;
}

sub _baz {
    return 0;
}

#Illegal declaration of anonymous subroutine at prototypes/example.pl line 12.
sub sub {
    print "WTF!?";
}
};

my @violations = $critic->critique( \$str );

is( scalar @violations, 2 );

foreach my $violation (@violations) {
    is( $violation->explanation,
        q{Use Params::Validate for public facing APIs} );
    is( $violation->description,
        q{Parameter validation not complying with required standard} );
}

#if ($TEST_VERBOSE) {
#    diag Dumper \@violations;
#}

