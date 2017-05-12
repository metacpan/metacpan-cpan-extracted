#
# File: example1.pl
# Date: 07-Feb-2007
# By  : Kevin Esteb
#
# This is a simple poller. It will read input and send output to 
# the spread group "test1". Any waiting message will be printed.
#

use Term::ReadLine;
use Spread::Messaging::Transport;
use Spread::Messaging::Exception;

use strict;
use constant true  => -1;
use constant false =>  0;

sub get_input {
    my ($spread, $term) = @_;

    my $type = 0;
    my $done = false;
    my $buffer = $term->readline("Prompt> ");
    $done = true if $buffer =~ /quit/i;

    $term->addhistory($buffer);
    $spread->send("test1", $buffer, $type);

    return $done;

}

sub put_output {
    my ($spread) = @_;

    if ($spread->poll()) {

        my ($srv_type, $sender, $groups, $mess_type, $endian, $message) =
          $spread->recv();

        printf("Service Type: %s\n", $srv_type);
        printf("Sender      : %s\n", $sender);
        printf("Groups      : %s\n", join(',', @{$groups}));
        printf("Message Type: %s\n", $mess_type);
        printf("Endian      : %s\n", $endian);
        printf("Message     : %s\n", ref($message) eq "ARRAY" ? join(',', @{$message}) : $message  );

    }

}

main: {

    my $spread;
    my $term;
    my $done = false;

    eval {

        $spread = Spread::Messaging::Transport->new();
        $term = Term::ReadLine->new("testing");

        $spread->join_group("test1");
        printf("Service = %s\n", $spread->service_type());

        while ($done == false) {

            $done = get_input($spread, $term);
            put_output($spread);

        }

    }; if (my $ex = $@) {

        my $ref = ref($ex);

        if ($ref && $ex->isa('Spread::Messaging::Exception')) {

            printf("Error: %s cased by: %s\n", $ex->errno, $ex->errstr);

        } else { warn $@; }

    }

}

