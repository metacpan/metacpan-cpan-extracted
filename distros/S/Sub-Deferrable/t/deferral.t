#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

# We'll need this. We're feeling a little down.
sub seppuku { die "I'm not fit to bear the sword of a Samurai!\n" }
sub reconsider { seppuku if @_ and defined $_[0]->{die} and $_[0]->{die} }

my ($queue, $sub);
use_ok( "Sub::Deferrable", "Load module" );

# New queue
ok( $queue = Sub::Deferrable->new, "Constructor" );
is( $queue->deferring, 0, "Starts out in immediate mode." );
is( ref $queue->{queue}, "ARRAY", "Queue is an array" );
is( $#{$queue->{queue}}, -1, "Queue is empty" );

# Deferring the inevitable
ok( $sub = $queue->mk_deferrable( \&seppuku ), "Can wrap a sub" );
is( ref $sub, "CODE", "Returned object is a sub" );
throws_ok { &$sub } qr/Samurai/, "Immediate mode works";
$queue->defer;
lives_ok( sub { $sub->() }, "Deferred mode appears to work" );
throws_ok { $queue->undefer } qr/Samurai/, "Yes, yes it works";
is( $queue->deferring, 0, "Back in immediate mode." );
is( $#{$queue->{queue}}, -1, "Queue is again empty" );

# Maybe things aren't so bad after all. We CAN reconsider...
my $reconsider;
ok( $reconsider = $queue->mk_deferrable( \&reconsider ), "Wrap another sub" );
lives_ok( sub { $reconsider->({die => 0}) }, "Immediate mode works" );
throws_ok { $reconsider->({die => 1}) } qr/Samurai/, "...and works again" ;

# Let's enjoy our new-found freedom.
my $final_decision = { die => 0 };
lives_ok(sub { $reconsider->($final_decision) }, "Live to fight another day");
$final_decision->{die} = 1;	# Will our hero make it?
$queue->defer;			# Tune in next week!
lives_ok(sub { $reconsider->($final_decision) }, "Dying of suspense");
$final_decision->{die} = 0;	# Last-minute script change...
lives_ok(sub { $queue->undefer }, "And our hero is saved!");

# Need some fancy footwork to preserve call-time state...
use Storable qw( dclone );

# And let's block these last-minute script changes!
$final_decision->{die} = 1;
my $resolve;
ok($resolve = $queue->mk_deferrable( \&reconsider, \&dclone ), "Clone defer");
throws_ok { $resolve->($final_decision) } qr/Samurai/, "Immediate works still";
$queue->defer;
lives_ok( sub {$resolve->($final_decision)}, "Deferral worked" );
$final_decision->{die} = 0;	# Writers always figure something out...
throws_ok { $queue->undefer } qr/Samurai/, "And the decision was final!";


# Try more than one thing in the queue
{
    my $sub_ran = 0;
    my $sub = $queue->mk_deferrable( sub { $sub_ran++ } );

    $queue->defer;

    $sub->() for 1..5;
    is $sub_ran, 0, 'execution was deferred';
    is @{$queue->{queue}}, 5, 'five subs in queue';

    $queue->undefer;

    is $sub_ran, 5, 'five subs were run';
    is @{$queue->{queue}}, 0, 'queue is empty';
}

# Fill up the queue and then cancel
{
    my $sub_ran = 0;
    my $sub = $queue->mk_deferrable( sub { $sub_ran++ } );

    $queue->defer;

    $sub->() for 1..5;
    is $sub_ran, 0, 'execution was deferred';
    is @{$queue->{queue}}, 5, 'five subs in queue';

    $queue->cancel;

    is $sub_ran, 0, 'no subs were run';
    is @{$queue->{queue}}, 0, 'queue is empty';

    $queue->undefer;

    is $sub_ran, 0, 'still no subs were run';
}



# And when the queue dies halfway through?
{
    my $sub_ran = 0;
    my $sub = $queue->mk_deferrable( sub { $sub_ran++;  die "Poopie" if @_ } );
    $queue->defer;

    $sub->();
    $sub->();
    $sub->(1);
    $sub->();
    $sub->();

    is $sub_ran, 0, 'execution deferred';
    is @{$queue->{queue}}, 5, 'queue has five items';

    throws_ok { $queue->undefer } qr/^Poopie\b/;

    is $sub_ran, 3, 'three subs were run';
    is @{$queue->{queue}}, 2, 'two subs still in queue';

    lives_ok { $queue->undefer };
    is $sub_ran, 5, 'five subs were run';
    is @{$queue->{queue}}, 0, 'queue is now empty';
}

