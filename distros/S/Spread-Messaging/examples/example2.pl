#
# File: example2.pl
# Date: 07-Feb-2007
# By  : Kevin Esteb
#
# This example uses an event loop to monitor and 
# print any messages within the "test1" group. 
#

use Event;
use Spread::Messaging::Transport;
use Spread::Messaging::Exception;

use strict;

my $spread;

sub put_output {

    my ($srv_type, $sender, 
        $groups, $mess_type, $endian, $message) = $spread->recv();

    printf("Service Type: %s\n", $srv_type);
    printf("Sender      : %s\n", $sender);
    printf("Groups      : %s\n", join(',', @{$groups}));
    printf("Message Type: %s\n", $mess_type);
    printf("Endian      : %s\n", $endian);
    printf("Message     : %s\n", ref($message) eq "ARRAY" ? join(',', @{$message}) : $message  );

}

main: {

    my $host = "spread.example.com";

    eval {

        $spread = Spread::Messaging::Transport->new(-host => $host);
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

