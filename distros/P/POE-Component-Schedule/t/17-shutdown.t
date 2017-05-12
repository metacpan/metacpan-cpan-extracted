use strict;
$| = 1;

use Test::More tests => 4;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

#BEGIN {
#  package POE::Kernel;
#  use constant TRACE_DEFAULT => exists($INC{'Devel/Cover.pm'});
#}



use POE 'Component::Schedule';
use DateTime;
use DateTime::Set;


my $pcs_session = POE::Component::Schedule->spawn;

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "_start";
            $_[HEAP] = POE::Component::Schedule->add(
                $_[SESSION]->ID => Tick => DateTime::Set->from_recurrence(
                        after      => DateTime->now->add( seconds => 1),
                        recurrence => sub {
                            return $_[0]->truncate( to => 'second' )->add( seconds => 1 )
                        },
                    ),
                'my_ticket', 1, 2,
            );
        },
        Tick => sub {
            pass "Tick";
	    $_[KERNEL]->post($pcs_session, 'shutdown');
        },
        _stop => sub {
            pass "_stop";
        },
    },
);

POE::Kernel->run();

pass "Stopped";
