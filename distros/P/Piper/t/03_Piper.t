#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper module
#####################################################################

use v5.10;
use strict;
use warnings;

use List::AllUtils qw(shuffle);
use Test::Most;

my $APP = "Piper";

use Piper;
use Piper::Process;

#####################################################################

# Number of successfully created objects
my $SUCCESSFUL_NEW;

# Test new
{
    subtest "$APP - new" => sub {
        my %BADARGS = (
            '^ERROR: Label \(garbage\) missing a segment' => {
                'only a label' => [qw(garbage)],
                'only scalars' => [garbage => 'not a process'],
                'dangling label' => [label => sub {}, 'garbage'],
            },
            '^ERROR: Segment is missing a handler' => {
                'missing required' => [ garbage => {} ],
                'labeled options' => [garbage => { verbose => 1 }],
                'two options hashes' => [ {verbose => 1}, {debug => 1} ],
                'opts between label/handler' => [garbage => { verbose => 1 }, sub {}],
            },
            '^ERROR: No segments provided to constructor' => {
                'no children' => [],
                'only options' => [ {verbose => 1} ],
            },
            '^ERROR: Cannot coerce type \(.*?\) into a segment' => {
                'arrayref' => [ [qw(garbage)] ],
                'labeled arrayref' => [garbage => []],
            },
        );

        for my $type (keys %BADARGS) {
            my $regex = qr/$type/;
            for my $bad (keys %{$BADARGS{$type}}) {
                throws_ok {
                    Piper->new(@{$BADARGS{$type}{$bad}})
                } $regex, "Bad args: $bad";
            }
        }

        my %GOODARGS = (
            'hashref' => { handler => sub{}, },
            'coderef' => sub{},
            'Piper::Process' => Piper::Process->new(sub{}),
            'Piper' => Piper->new(sub{}),
            'Piper::Instance (process)' => Piper::Process->new(sub{})->init,
            'Piper::Instance (pipe)' => Piper->new(sub{})->init,
        );
        $SUCCESSFUL_NEW += 2;

        for my $good (keys %GOODARGS) {
            warning_is {
                Piper->new($GOODARGS{$good})
            } undef, "Good args: $good";
            $SUCCESSFUL_NEW++;

            warning_is {
                Piper->new($good, $GOODARGS{$good})
            } undef, "Good args: label => $good";
            $SUCCESSFUL_NEW++;
        }

        warning_is {
            Piper->new(values %GOODARGS)
        } undef, 'Good args: <all segment types>';
        $SUCCESSFUL_NEW++;

        warning_is {
            Piper->new(%GOODARGS)
        } undef, 'Good args: <label => all segment types>';
        $SUCCESSFUL_NEW++;

        warning_is {
            Piper->new(values %GOODARGS, { verbose => 1 })
        } undef, 'Good args: <all segment types>, $opts at end';
        $SUCCESSFUL_NEW++;

        warning_is {
            Piper->new({ verbose => 1 }, values %GOODARGS)
        } undef, 'Good args: <all segment types>, $opts at beginning';
        $SUCCESSFUL_NEW++;

        warning_is {
            my @elems = values %GOODARGS;
            splice @elems, 3, 0, { verbose => 1 };
            Piper->new(@elems)
        } undef, 'Good args: <all segment types, $opts in middle';
        $SUCCESSFUL_NEW++;

        warning_is {
            Piper->new(%GOODARGS, { verbose => 1 })
        } undef, 'Good args: <label => all segment types>, $opts at end';
        $SUCCESSFUL_NEW++;

        warning_is {
            Piper->new({ verbose => 1 }, %GOODARGS)
        } undef, 'Good args: <label => all segment types>, $opts at beginning';
        $SUCCESSFUL_NEW++;

        warning_is {
            my @elems = %GOODARGS;
            splice @elems, 6, 0, { verbose => 1 };
            Piper->new(@elems)
        } undef, 'Good args: <label => all segment types, $opts in middle';
        $SUCCESSFUL_NEW++;

        my $where = 0;
        my @elems = map {
            $where++;
            $where > 3 ? [ $_ => $GOODARGS{$_} ] : [ $GOODARGS{$_} ]
        } keys %GOODARGS;
        @elems = shuffle @elems;

        warning_is {
            Piper->new(map { @{$_} } @elems);
        } undef, 'Good args: half labeled, random order';
        $SUCCESSFUL_NEW++;

        warning_is {
            Piper->new((map { @{$_} } @elems), { verbose => 1 });
        } undef, 'Good args: half labeled, random order, $opts at end';
        $SUCCESSFUL_NEW++;

        warning_is {
            Piper->new({ verbose => 1 }, map { @{$_} } @elems);
        } undef, 'Good args: half labeled, random order, $opts at beginning';
        $SUCCESSFUL_NEW++;

        splice @elems, 3, 0, [ { verbose => 1 } ];
        warning_is {
            Piper->new(map { @{$_} } @elems);
        } undef, 'Good args: half labeled, random order, $opts in middle';
        $SUCCESSFUL_NEW++;
    };
}

my $PROC = Piper->new(
    child => sub{},
    friend => {
        handler => sub{},
        debug => 1,
        verbose => 1,
    },
    {
        batch_size => 3,
        allow => sub{},
        label => 'main',
        debug => 0,
        verbose => 0,
    },
);
$SUCCESSFUL_NEW++;

my $DEFAULT = Piper->new(child => sub{}, friend => sub{});

my $INIT;
my $DEFAULT_INIT;
# Test init
{
    subtest "$APP - init" => sub {
        $INIT = $PROC->init();
        ok(ref $INIT, 'ok - normal');
        $DEFAULT_INIT = $DEFAULT->init();
        ok(ref $DEFAULT_INIT, 'ok - default');
    };
}

for my $test (
    [ 'Piper', $PROC, $DEFAULT ],
    [ 'initialized Piper', $INIT, $DEFAULT_INIT ]
) {
    my $NAME = $test->[0];
    my $TEST = $test->[1];
    my $DEFAULT = $test->[2];

    subtest $APP => sub {
        # Test id
        subtest "$NAME - id" => sub {
            is($TEST->id, "$APP$SUCCESSFUL_NEW", 'ok');
        };

        # Test label
        subtest "$NAME - label" => sub {
            is($TEST->label, 'main', 'ok from constructor');

            is($DEFAULT->label, $DEFAULT->id, 'ok default (id)');
        };

        # Test stringification
        subtest "$NAME - stringification" => sub {
            is("$TEST", $TEST->label, 'overloaded stringify');
            is("$DEFAULT", $DEFAULT->id, 'overloaded with default');
        };

        # Test enabled
        subtest "$NAME - enabled" => sub {
            ok(!$TEST->has_enabled, 'predicate');

            $TEST->enabled(0);
            is($TEST->enabled, 0, 'writable');

            $TEST->clear_enabled;
        };

        # Test batch_size
        subtest "$NAME - batch_size" => sub {
            is($TEST->batch_size, 3, 'ok from constructor');
            
            ok($TEST->has_batch_size, 'predicate');

            ok(!$DEFAULT->has_batch_size, 'predicate default');

            if ($NAME !~ /^initialized/) {
                throws_ok {
                    Piper->new(sub{}, { batch_size => -14 })
                } qr/^Must be a positive integer/, 'positive integer required';
            }
        };

        # Test allow
        subtest "$NAME - allow" => sub {
            ok($TEST->has_allow, 'predicate');

            ok(!$DEFAULT->has_allow, 'predicate default');

            if ($NAME !~ /^initialized/) {
                throws_ok {
                    Piper->new(sub{}, { allow => 'blah' })
                } qr/did not pass type constraint "CodeRef"/, 'bad allow';
            }
        };

        # Test children
        subtest "$APP - children" => sub {
            ok(@{$TEST->children}, 'has children');
        };

        # Test debug/verbose
        for my $type (qw(debug verbose)) {
            my $has = "has_$type";
            my $clear = "clear_$type";
            subtest "$NAME - $type" => sub {
                ok($TEST->$has(), 'predicate');
                ok($TEST->children->[1]->$has(), 'predicate of child');

                ok(!$DEFAULT->$has(), 'predicate default');
                ok(!$DEFAULT->children->[1]->$has(), 'predicate default of child');

                $DEFAULT->$type(1);
                ok($DEFAULT->$has(), 'predicate after set');
                is($DEFAULT->$type(), 1, 'writer ok');

                $DEFAULT->children->[1]->$type(1);
                ok($DEFAULT->children->[1]->$has(), 'predicate of child after set');
                is($DEFAULT->children->[1]->$type(), 1, 'writer of child ok');

                $DEFAULT->$clear();
                ok(!$DEFAULT->$has(), 'clearer ok');

                is($DEFAULT->children->[1]->$type(), 1, 'cleared parent does not affect child');
                $DEFAULT->children->[1]->$clear();
                ok(!$DEFAULT->children->[1]->$has(), 'clearer of child ok');

                if ($NAME !~ /^initialized/) {
                    throws_ok {
                        Piper::Process->new({ handler => sub{}, $type => -1 });
                    } qr/Must be a number greater than or equal to zero/, "bad $type";
                }
            };
        }
    };
}

#####################################################################

done_testing();
