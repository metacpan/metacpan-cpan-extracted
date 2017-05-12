#!/usr/bin/perl
# --------------------------------------------------------------------------
#
# File: example5.pl
# Date: 08-Feb-2007
# By  : Kevin Esteb
#
# This procedure will by default, monitor a group named 
# "testing" on a server named "spread.example.com" on port 4803. 
#
# Any message that is received will be decoded and dumped to the terminal. 
# This procedure also uses the Event.pm module to demostrate how to 
# incorporate an event loop.
#
# --------------------------------------------------------------------------

use strict;
use warnings;

# -Required Modules-------------------------------------------------------

use Event;
use Getopt::Long;
use Spread::Messaging;
use Spread::Messaging::Exception;

# -Global Variables-------------------------------------------------------

my $port = '4803';
my $group = 'testing';
my $host = 'spread.example.com';
my $VERSION = '0.01';

# ------------------------------------------------------------------------

sub handle_private {
    my $spread = shift;

    printf("------------------------------------------------------------\n");
    printf("Received a REGULAR message\n");
    printf("Service type is: UNRELIABLE_MESS\n") if $spread->is_unreliable_mess;
    printf("Service type is: RELIABLE_MESS\n") if $spread->is_reliable_mess;
    printf("Service type is: FIFO_MESS\n") if $spread->is_fifo_mess;
    printf("Service type is: CAUSAL_MESS\n") if $spread->is_causal_mess;
    printf("Service type is: AGREED_MESS\n") if $spread->is_agreed_mess;
    printf("Service type is: SAFE_MESS\n") if $spread->is_safe_mess;
    printf("Private message: %s\n", $spread->entity);
    printf("Type           : %s\n", $spread->type);
    printf("Endian         : %s\n", $spread->endian);
    printf("Sender         : %s\n", $spread->sender);
    printf("Message        : \"%s\"\n", $spread->message);

}

sub handle_group {
    my $spread = shift;

    printf("------------------------------------------------------------\n");
    printf("Received a REGULAR message\n");
    printf("Service type is: UNRELIABLE_MESS\n") if $spread->is_unreliable_mess;
    printf("Service type is: RELIABLE_MESS\n") if $spread->is_reliable_mess;
    printf("Service type is: FIFO_MESS\n") if $spread->is_fifo_mess;
    printf("Service type is: CAUSAL_MESS\n") if $spread->is_causal_mess;
    printf("Service type is: AGREED_MESS\n") if $spread->is_agreed_mess;
    printf("Service type is: SAFE_MESS\n") if $spread->is_safe_mess;
    printf("Group message  : %s\n", join(',', @{$spread->group}));
    printf("Type           : %s\n", $spread->type);
    printf("Endian         : %s\n", $spread->endian);
    printf("Sender         : %s\n", $spread->entity);
    printf("Message        : \"%s\"\n", $spread->message);

}

sub handle_join {
    my $spread = shift;

    printf("------------------------------------------------------------\n");
    printf("Received a MEMBERSHIP message\n");
    printf("Service type is: REGULAR\n");
    printf("Cause          : JOIN\n");
    printf("Group effected : %s\n", $spread->sender);
    printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});
    printf("Joining member : %s\n", $spread->entity);
    printf("------------------------------------------------------------\n");
    printf("Current Group Membership\n");
    printf("------------------------------------------------------------\n");

    my @groups = $spread->groups_joined;

    foreach my $grp (@groups) {

        printf("Group: %s\n", $grp);

        my @members = $spread->group_members($grp);

        foreach my $member (@members) {

            printf("       %s\n", $member);

        }

    }

}

sub handle_leave {
    my $spread = shift;

    printf("------------------------------------------------------------\n");
    printf("Received a MEMBERSHIP message\n");
    printf("Service type is: REGULAR\n");
    printf("Cause          : LEAVE\n");
    printf("Group effected : %s\n", $spread->sender);
    printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});
    printf("Leaving member : %s\n", $spread->entity);
    printf("------------------------------------------------------------\n");
    printf("Current Group Membership\n");
    printf("------------------------------------------------------------\n");

    my @groups = $spread->groups_joined;

    foreach my $grp (@groups) {

        printf("Group: %s\n", $grp);

        my @members = $spread->group_members($grp);

        foreach my $member (@members) {

            printf("       %s\n", $member);

        }

    }

}

sub handle_disconnect {
    my $spread = shift;

    printf("------------------------------------------------------------\n");
    printf("Received a MEMBERSHIP message\n");
    printf("Cause          : DISCONNECT\n");
    printf("Group effected : %s\n", $spread->sender);
    printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});
    printf("Leaving member : %s\n", $spread->entity);
    printf("------------------------------------------------------------\n");
    printf("Current Group Membership\n");
    printf("------------------------------------------------------------\n");

    my @groups = $spread->groups_joined;

    foreach my $grp (@groups) {
        
        printf("Group: %s\n", $grp);
        
        my @members = $spread->group_members($grp);

        foreach my $member (@members) {

            printf("       %s\n", $member);

        }

    }

}

sub handle_network {
    my $spread = shift;

    printf("------------------------------------------------------------\n");
    printf("Received a MEMBERSHIP message\n");
    printf("Cause          : NETWORK\n");
    printf("Group effected : %s\n", $spread->sender);
    printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});
    printf("Leaving member : %s\n", $spread->entity);

}

sub handle_transisiton {
    my $spread = shift;

    printf("------------------------------------------------------------\n");
    printf("Received a MEMBERSHIP message\n");
    printf("Service type is: TRANSISITON\n");
    printf("Cause          : %s\n", $spread->message_type);
    printf("Group effected : %s\n", $spread->sender);
    printf("Group ID       : (%s,%s,%s)\n", @{$spread->message});

}

sub handle_other {
    my $spread = shift;

    printf("Service Type: %s\n", $spread->message_type);
    printf("Sender      : %s\n", $spread->sender);
    printf("Groups      : %s\n", join(',', @{$spread->group}));
    printf("Message Type: %s\n", $spread->type);
    printf("Endian      : %s\n", $spread->endian);
    printf("Message     : %s\n", ref($spread->message) eq "ARRAY" ? 
                                     join(',', @{$spread->message}) :
                                     $spread->message);
}

sub handle_signals {

    Event::unloop_all();
    
}

sub usage {

    my ($Script) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );
    print << "EOT";

$Script
$Line
$0 - An example of how to use Spread::Messaging.
Version: $VERSION

    Usage:
          $0 [-host] <hostname>
          $0 [-port] <IP port number>
          $0 [-group] <group name>
          $0 [-help]

          -host....Where the Spread server resides at.
          -port....The port for that Spread server.
          -group...A Spread group to join.
          -help....Print this help message.

      Examples:
          $0 -host spread.example.com
          $0 -help

This procedure demostrates how to use the Spread::Messaging module. By default
it will connect to a Spread server named "spread.example.com" on port 4803
and join a group named "testing". At the point, any messages that are received
will be dumped to the terminal.

EOT

}

sub setup {

    my $stat;
    my $help = "";

    GetOptions('help|h|?' => \$help, 'port=s' => \$port, 'host=s' => \$host, 
        'group=s' => \$group);
    
    if ($help) {

        usage();
        exit(0);

    }

    $Event::DIED = sub {
        Event::verbose_exception_handler(@_);
        Event::unloop_all();
    };

}

main: {

    my $spread;

    setup();

    eval {

        $spread = Spread::Messaging->new(-host => $host, -port => $port);
        $spread->join_group($group);

        $spread->callbacks(
            -private => \&handle_private,
            -group => \&handle_group,
            -join => \&handle_join,
            -leave => \&handle_leave,
            -disconnect => \&handle_disconnect,
            -network => \&handle_network,
            -transition => \&handle_transition,
            -other => \&handle_other
        );

        Event->io(fd => $spread->fd, cb => sub { $spread->process(); });
        Event->signal(signal => 'INT', cb => \&handle_signals);
        Event::loop();

    }; if (my $ex = $@) {

        my $ref = ref($ex);

        if ($ref && $ex->isa('Spread::Messaging::Exception')) {

            printf("Error : %s \nReason: %s\n", $ex->errno, $ex->errstr);

        } else { warn $@; warn $!; }

    }

}

