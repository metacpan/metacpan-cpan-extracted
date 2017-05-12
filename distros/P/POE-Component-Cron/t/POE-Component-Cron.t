# vim: filetype=perl
#
use warnings;
use strict;

use Test::More qw(no_plan);

use_ok 'POE::Component::Cron';

use DateTime::Event::Cron;
use DateTime::Event::Random;
use POE;

my %count;
my $update_sched;

diag('This is going to take about two minutes');

#
# a client session
#
my $s1 = POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->delay( '_die_', 120 );
            $_[KERNEL]->delay( 'Tock',  1 );
            $count{ $_[STATE] }++;
        },

        Tick => sub {
            ok 1, 'tick ' . scalar localtime;
            $count{ $_[STATE] }++;
        },

        Tock => sub {
            ok 1, 'tock ' . scalar localtime;
            $_[KERNEL]->delay( 'Tock', 10 );
            $count{ $_[STATE] }++;
        },

        Tingle => sub {
            ok 1, 'tingle ' . scalar localtime;
            $count{ $_[STATE] }++;
        },

	Tawk => sub {
	    ok( $_[ARG0] eq "Talk", "Tawk Talk" );
	},

        _die_ => sub {
            ok 1, "_die_ " . $_[SESSION]->ID;
            $_[KERNEL]->alarm_remove_all();
            $_[KERNEL]->signal( $_[KERNEL], 'SHUTDOWN' );
        },
    }
);

#
# another client session
#
my $s2 = POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->delay( '_die_', 120.1 );
            ok 1, '_start';
            $count{ $_[STATE] }++;
        },

        update => sub {
            ok 1, 'update ' . scalar localtime;
            $count{ $_[STATE] }++;
            $update_sched->delete() if ( $count{ $_[STATE] } == 5 );
        },

        report => sub {
            ok 1, 'report ' . scalar localtime;
            $count{ $_[STATE] }++;
        },

        modify => sub {
            ok 1, $_[STATE] . scalar localtime;
            $count{ $_[STATE] }++;
        },

	track => sub {
	    ok( $_[ARG0] eq "Test", "track Test" );
	},

        _die_ => sub {
            ok 1, "_die_ " . $_[SESSION]->ID;
            $_[KERNEL]->alarm_remove_all();
            $count{ $_[STATE] }++;
        },
    }
);

my @sched;

#
# a crontab-ish event stream
#
push @sched,
  POE::Component::Cron->new(
    $s1 => Tick => DateTime::Event::Cron->from_cron('* * * * *')->iterator(
        span => DateTime::Span->from_datetimes(
            start => DateTime->now,
            end   => DateTime::Infinite::Future->new
        )
    ),
  );


#
# one random event stream
#
$update_sched = POE::Component::Cron->new(
    $s2 => update => DateTime::Event::Random->new(
        seconds => 5,
        start   => DateTime->now,
      )->iterator,
);

#
# add another stream
#
$update_sched->add(
    $s2 => track => DateTime::Event::Random->new(
        seconds => 2,
        start   => DateTime->now,
      )->iterator,
      'Test'
);

#
# another random event stream
#
push @sched,
  POE::Component::Cron->new(
    $s2 => report => DateTime::Event::Random->new(
        seconds => 5,
        start   => DateTime->now,
      )->iterator,
  );

# an event stream using the easy syntax.
push @sched, 
    POE::Component::Cron->from_cron('* * * * *' => $s2->ID => 'modify');

# an event stream using the easy syntax with an argument
push @sched, 
    POE::Component::Cron->from_cron('* * * * *' => $s1->ID => Tawk => 'Talk');

#
# this stream only has two events in it
#
my $now   = DateTime->now();
my $delta = DateTime::Duration->new( seconds => 15 );

push @sched,
  POE::Component::Cron->add(
    $s1 => Tingle => DateTime::Set->from_datetimes(
        dates => [ $now + $delta, $now + $delta + $delta, ],
      )->iterator,
  );

POE::Kernel->run();

for ( keys %count ) {
    ok $count{$_} > 0, "\$count{$_} = $count{$_}";
}

ok( 1, "stopped" );
