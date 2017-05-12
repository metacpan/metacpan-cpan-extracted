#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper::Process module
#####################################################################

use v5.10;
use strict;
use warnings;

use Test::Most;

my $APP = "Piper::Process";

use Piper::Process;

#####################################################################

# Number of successfully created objects
my $SUCCESSFUL_NEW;

# Test new
{
    subtest "$APP - new" => sub {
        throws_ok {
            Piper::Process->new(qw(1 2 3))
        } qr/^ERROR: Too many arguments/, 'too many arguments';

        throws_ok {
            Piper::Process->new(qw(1 2))
        } qr/^ERROR: Last argument must be a CODE ref or HASH ref/, 'last arg CODE or HASH';

        throws_ok {
            Piper::Process->new([qw(blah)], {})
        } qr/^ERROR: Labels may not be a reference/, 'bad label';

        my $EXP = Piper::Process->new({
            label => 'process',
            handler => sub {},
        });

        is(ref $EXP, $APP, 'ok - by hashref');
        $SUCCESSFUL_NEW++;

        is_deeply(
            Piper::Process->new(process => { handler => sub {}, }),
            $EXP,
            'ok - by label => hashref'
        );
        $SUCCESSFUL_NEW++;

        is_deeply(
            Piper::Process->new(process => sub {}),
            $EXP,
            'ok - by label => sub'
        );
        $SUCCESSFUL_NEW++;
    };
}

my $PROC = Piper::Process->new(
    process => {
        batch_size => 3,
        allow => sub { $_[0] =~ /^\d+$/ },
        handler => sub{},
        debug => 0,
        verbose => 0,
    }
);
$SUCCESSFUL_NEW++;

my $DEFAULT = Piper::Process->new(sub{});

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
    [ 'Piper::Process', $PROC, $DEFAULT ],
    [ 'initialized Piper::Process', $INIT, $DEFAULT_INIT ]
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
            is($TEST->label, 'process', 'ok from constructor');

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
                    Piper::Process->new({ handler => sub{}, batch_size => -14 })
                } qr/^Must be a positive integer/, 'positive integer required';
            }
        };

        # Test allow
        subtest "$NAME - allow" => sub {
            ok($TEST->has_allow, 'predicate');

            ok(!$DEFAULT->has_allow, 'predicate default');

            if ($NAME !~ /^initialized/) {
                throws_ok {
                    Piper::Process->new({ handler => sub{}, allow => 'blah' })
                } qr/did not pass type constraint "CodeRef"/, 'bad allow';
            }
        };

        # Test debug/verbose
        for my $type (qw(debug verbose)) {
            my $has = "has_$type";
            my $clear = "clear_$type";
            subtest "$NAME - $type" => sub {
                ok($TEST->$has(), 'predicate');

                ok(!$DEFAULT->$has(), 'predicate default');

                $DEFAULT->$type(1);
                ok($DEFAULT->$has(), 'predicate after set');
                is($DEFAULT->$type(), 1, 'writer ok');

                $DEFAULT->$clear();
                ok(!$DEFAULT->$has(), 'clearer ok');

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
