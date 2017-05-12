#
# File: example3.pl
# Date: 08-Feb-2007
# By  : Kevin Esteb
#
# This procedure will monitor a group named "test1". Any message that 
# is received will be decoded and dumped to the terminal. This procedure 
# also uses the Event module to demostrate how to incorporate an event loop.
#
# You will want to change $host to connect to your Spread server.
#

use Event;
use Spread::Messaging::Content;
use Spread::Messaging::Exception;

use strict;
my $spread;

sub put_output {

    $spread->recv();

    printf("------------------------------------------------------------\n");
    
    if ($spread->is_regular_mess) {

	    printf("Received a REGULAR message\n");
        printf("Service type is: UNRELIABLE_MESS\n") if $spread->is_unreliable_mess;
        printf("Service type is: RELIABLE_MESS\n") if $spread->is_reliable_mess;
        printf("Service type is: FIFO_MESS\n") if $spread->is_fifo_mess;
        printf("Service type is: CAUSAL_MESS\n") if $spread->is_causal_mess;
        printf("Service type is: AGREED_MESS\n") if $spread->is_agreed_mess;
        printf("Service type is: SAFE_MESS\n") if $spread->is_safe_mess;

        if ($spread->is_private_mess) {

            printf("Private message: %s\n", @{$spread->group}[0]);
            printf("Type           : %s\n", $spread->type);
            printf("Endian         : %s\n", $spread->endian);
            printf("Sender         : %s\n", $spread->sender);
            printf("Message        : %s\n", $spread->message);

        } else {

            printf("Group message  : %s\n", join(',', @{$spread->group}));
            printf("Type           : %s\n", $spread->type);
            printf("Endian         : %s\n", $spread->endian);
            printf("Sender         : %s\n", $spread->sender);
            printf("Message        : %s\n", $spread->message);

        }

    } elsif ($spread->is_membership_mess) {

        printf("Received a MEMBERSHIP message\n");

        if ($spread->is_reg_memb_mess) {

            printf("Service type is: REGULAR\n");

            if ($spread->is_caused_by_join) {

                printf("Cause          : JOIN\n");
                printf("Group effected : %s\n", $spread->sender);
                printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});
                printf("Joining member : %s\n", @{$spread->message}[3]);

            } elsif ($spread->is_caused_by_leave) {

                printf("Cause          : LEAVE\n");
                printf("Group effected : %s\n", $spread->sender);
                printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});
                printf("Leaving member : %s\n", @{$spread->message}[3]);

            } elsif ($spread->is_caused_by_disconnect) {

                printf("Cause          : DISCONNECT\n");
                printf("Group effected : %s\n", $spread->sender);
                printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});
                printf("Leaving member : %s\n", @{$spread->message}[3]);

            } elsif ($spread->is_caused_by_network) {

                printf("Cause          : NETWORK\n");
                printf("Group effected : %s\n", $spread->sender);
                printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});
                printf("Leaving member : %s\n", @{$spread->message}[3]);

            }

        } elsif ($spread->is_transition_mess) {

            printf("Service type is: TRANSISITON\n");
            printf("Cause          : %s\n", $spread->message_type);
            printf("Group effected : %s\n", $spread->sender);
            printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});

        }

    } else {

        printf("Service Type: %s\n", $spread->message_type);
        printf("Sender      : %s\n", $spread->sender);
        printf("Groups      : %s\n", join(',', @{$spread->group}));
        printf("Message Type: %s\n", $spread->type);
        printf("Endian      : %s\n", $spread->endian);
        printf("Message     : %s\n", ref($spread->message) eq "ARRAY" ? 
                                         join(',', @{$spread->message}) :
                                         $spread->message);

    }

}

main: {

    my $host = "wsipc-lmgt-01";

    eval {

	    $spread = Spread::Messaging::Content->new(-host => $host);
        $spread->join_group("test1");

        Event->io(fd => $spread->fd, cb => \&put_output);
        Event::loop();

    }; if (my $ex = $@) {

        my $ref = ref($ex);

        if ($ref && $ex->isa('Spread::Messaging::Exception')) {

            printf("Error: %s cased by: %s\n", $ex->errno, $ex->errstr);

        } else { warn $@; }

    }

}

