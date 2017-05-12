package TL1::Toolkit;


use 5.008;
use strict;
use warnings;

our $VERSION = "0.02";

# Module import
use threads;
use threads::shared;
use Thread::Queue::Any;
use Net::Telnet;

# $Revision: 602 $
# +--------------------------------------------------------------------------+
# | Licensed under the Apache License, Version 2.0 (the "License");          |
# | you may not use this file except in compliance with the License.         |
# | You may obtain a copy of the License at                                  |
# |                                                                          |
# |     http://www.apache.org/licenses/LICENSE-2.0                           |
# |                                                                          |
# | Unless required by applicable law or agreed to in writing, software      |
# | distributed under the License is distributed on an "AS IS" BASIS,        |
# | WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. |
# | See the License for the specific language governing permissions and      |
# | limitations under the License.                                           |
# +--------------------------------------------------------------------------+

=pod

=head1 NAME

TL1::Toolkit - Utility functions for interacting with TL1 equipment

=head1 VERSION

0.02

=head1 DESCRIPTION

This Perl module is intended to hide the difficult TL1 syntax from
the user. It executes TL1 commands and returns the results in Perl
data structures. For example, if you work with different types and/or
vendors of devices the TL1 syntax might be different as well as the
output. This TL1 module retrieves information from different types
and/or vendors of devices without having to know the exact details.
There is also a cmd() function to execute any TL1 function. In this
case the user has to parse the returned results. This module is known
to work on Nortel OME6500, Nortel DWDM CPL, Nortel HDXc, Nortel OM5200,
Cisco ONS15454 and Adva FSP3000; but it should work on any TL1 capable
device.

=head1 SYNOPSIS

=head2 my $tl1 = TL1::Toolkit->new("node", "name", "secret");

Create a TL1::Toolkit object that holds information about a TL1 session.
Its arguments are:

=over

=item *

hostname: network element to connect to

=item *

username: login name

=item *

password: password

=item *

type (optional): device type (OME6500, HDXc)

=item *

verbose (optional): debug level (0..9)

=back

=cut

my $keep_reading : shared = 1;

###########################################################################
# Constructor method
###########################################################################
sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    $keep_reading = 1;
    my $self     = {
        username => 'xxxx',
        password => 'xxxx',
        type => 'OME6500',
        ctag => '1',
        timeout => 10,
        retries => 3,
        verbose  => 0,
        @_,
    };

    bless( $self, $class );
    # 3 threads started
    #resp_queue has responses
    $self->{'resp_queue'} = Thread::Queue->new();
    #auto_queue has autonomous messages
    $self->{'auto_queue'} = Thread::Queue->new();
    #
    $self->{'acmd_queue'} = Thread::Queue->new();

    $self->_verbose( 2,
        "Created tl1 object for: $self->{'hostname'}.\n" );
    return $self;
}

sub _verbose {
    my ( $self, $level, $info ) = @_;
    print( STDERR "debug$level: $info" )
      if ( $level <= $self->{'verbose'} );
}

sub _receiver_thread {
    my ($self) = @_;    # Object this method is part of
    my $state  = 'noop';    # State of FSM
    my $n      = 0;        # Counter variable
    my @response;        # Local copy of return array
    my $socket = $self->{'socket'};    # Socket

    # Debug message
    $self->_verbose( 3, "Starting receiver thread.\n" );

    my $buf;
    while ($keep_reading) {
        # The OM5200 does not end its response with a newline.
        # Therefore, the last line is a single ';' character.
        # Look ahead in the buffer to detect this situation.
        my $bufref = $socket->buffer();
        if (!defined($$bufref)) {
            $self->_verbose(1, "bufref not defined\n");
        }
        if ((length($$bufref) == 1) && ($$bufref eq ";") &&
                (($state eq 'response') || $state eq 'auto')) {
            $self->_verbose( 9, "; read, state == response\n" );
            $buf = $socket->get();
        } else {
            $self->_verbose( 9, "state = $state\n" );
            $buf = $socket->getline();
        }
        if (!defined($buf)) {
            $n++;
            if (!$socket->eof()) {
                my $msg = $socket->errmsg;
                if ($msg ne "") {
                    $self->_verbose(1, "_receiver_thread $self->{'hostname'} (state=$state, retries=$n): $msg\n");
                }
            }
            # not sure if @resp needs to be shared
            #my @resp : shared = undef;
            if ($n >= $self->{'retries'}) {
                $self->{'resp_queue'}->enqueue(undef);
                $n = 0;
            }
            next;
        }
        # Debug message
        $self->_verbose( 3, "$buf\n" );
        $n = 0;
      SWITCH: {
            # a line with a ; only means the end of a response
            $buf =~ /^;/ && ( $state =~ /auto|response/ ) && do {
                if ( $state eq 'auto'
                    && defined( $self->{'auto_code'} ) )
                {

                    # Return autonomous data
                    my @resp : shared = @response;
                    $self->{'auto_queue'}->enqueue( \@resp );
                }
                elsif ( $state eq 'response' ) {
                    # this is what we do at the end of a response
                    # Return response data in @response 
                    # it returns a reference to @response called  @resp

                    my @resp : shared = @response;
                    $self->{'resp_queue'}->enqueue( \@resp );
                }
                @response = ();
                $socket->buffer_empty();

                $state = 'noop';
                last SWITCH;
            };

            $buf =~ /^[;\r\n\<\>]/ && do {
                $state = 'noop';
                last SWITCH;
            };

            # start of an autonomonous message (alarm)
            $buf =~ /^(\*C|\*\*|\* |A ) (\d{1,10}) (.*)/ && do {
                $state = 'auto';
                last SWITCH;
            };

            # start of a response
            $buf =~ /^M  (.*) (COMPLD|PRTL|DENY)/ && do {
                $state = 'response';
                last SWITCH;
            };

            # line with host date and time
            $buf =~ /(   (.*) (\d{2}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}))/
              && do {
                $state = 'log';
                last SWITCH;
              };
        }
        if ($state ne 'noop') {
            chomp($buf);
            # lines are pushed in @response until a line with
            # a ; only ($state equals 'noop') is read
            push( @response, $buf );
        }
    }
    $self->{'resp_queue'}->enqueue(undef);
    $self->_verbose( 3, "Receiver thread ended.\n" );
}

sub _auto_thread {
    my ($self) = @_;

    $self->_verbose( 3, "Autonomous messages thread started.\n" );
    while ( my $msg_ref = $self->{'auto_queue'}->dequeue() ) {
        $self->{'auto_code'}->($self, $msg_ref,
                    $self->{'auto_arg_ref'} );
    }
    $self->_verbose( 3, "Autonomous messages thread ended.\n" );
}

sub _set_auto_code {
    my ( $self, $func_ref, $arg_ref ) = @_;
    $self->{'auto_code'}    = $func_ref;
    $self->{'auto_arg_ref'} = $arg_ref;
}

sub _async_cmd_thread {
    my ($self) = @_;

    $self->_verbose( 3, "Starting async command thread.\n" );
    while ( my $cmd = $self->{'acmd_queue'}->dequeue() ) {
        my $resp_ref = $self->cmd($cmd);
        $self->{'async_code'}->( $resp_ref, $self->{'async_arg_ref'} )
          if defined( $self->{'async_code'} );
    }
    $self->_verbose( 3, "Async command thread ended.\n" );
}

sub _set_async_code {
    my ( $self, $func_ref, $arg_ref ) = @_;
    $self->{'async_code'}    = $func_ref;
    $self->{'async_arg_ref'} = $arg_ref;
}

###########################################################################
=pod

=head2 $tl1->open()

Connect to the TL1 device and login. Returns 1 on success, 0 on failure.

=cut

###########################################################################
# Connect and login to TL1 device.
###########################################################################
sub open {
    my ($self) = @_;
    $self->_verbose( 3,
        "Starting threads for tl1 device: $self->{'hostname'}.\n" );

    # open socket connection
    my $con = 1;
    $self->{'socket'} = new Net::Telnet(
        Timeout    => $self->{'timeout'},
        Errmode    => 'return'
    );
    $self->{'socket'}->port($self->{'peerport'});
    $self->{'socket'}->open($self->{'hostname'});

    if ( $con != 1 ) {
        $self->_verbose(1, "Can't connect to $self->{'hostname'}\n");
        return 0;
    } 

    # Handle alarms
    if ( defined( $self->{'auto_code'} ) ) {
        $self->{'auto_thread'} = async {
            $self->_auto_thread();
          }
    }

    # Start receiver
    $self->{'receiver_thread'} = async {
        $self->_receiver_thread();
    };

    # Async commands
    $self->{'async_cmd_thread'} = async {
        $self->_async_cmd_thread();
    };

    # login
    my $result = $self->_login();
    if ($result ne "COMPLD") {
        $self->_verbose(1, "login failed for $self->{'hostname'} $self->{'username'}\n");
        $self->{'socket'}->close();
        if ( defined( $self->{'auto_code'} ) ) {
            $self->{'auto_queue'}->enqueue(undef);
            $self->{'auto_thread'}->join();
        }
        $self->{'acmd_queue'}->enqueue(undef);
        $self->{'async_cmd_thread'}->join();
        $keep_reading = 0;
        $self->{'receiver_thread'}->join();
        return 0;
    } else {
        $self->_verbose( 2, "login succeeded $self->{'username'}.\n" );
    }
    return 1;

}

###########################################################################
=pod

=head2 $tl1->close()

Logout and disconnect from the TL1 device.

=cut

###########################################################################
# Logout and disconnect from TL1 device.
###########################################################################
sub close {
    my ($self) = @_;
    $self->_verbose( 2, "Closing connection to $self->{'hostname'}.\n" );
    my $socket = $self->{'socket'};
    $socket->print("canc-user::$self->{'username'}:$self->{'ctag'};\n");
    $keep_reading = 0;
    my $out = $self->{'resp_queue'}->dequeue();
    my $check = check_resp($out);
    $self->{'socket'}->close();
    if ( defined( $self->{'auto_code'} ) ) {
        $self->{'auto_queue'}->enqueue(undef);
        $self->{'auto_thread'}->join();
    }
    $self->{'acmd_queue'}->enqueue(undef);
    $self->{'async_cmd_thread'}->join();
    $self->{'receiver_thread'}->join();
    return $check;
}

sub _login() {
    my ($self) = @_;
    $self->_verbose( 3, "starting login to $self->{'hostname'}.\n" );
    my $out = $self->cmd("ACT-USER::$self->{'username'}:$self->{'ctag'}::$self->{'password'};\n");
    my $check = check_resp ($out);
    return $check;
}

###########################################################################
=pod

=head2 my $output = $tl1->cmd($command);

The string variable $command contains a TL1 command string that will be
sent to the TL1 device as is. It returns the results as ASCII text to
the string variable $output.

=cut

###########################################################################
# Send TL1 command and return response
###########################################################################
sub cmd {
    my ( $self, $cmd ) = @_;
    my $socket = $self->{'socket'};
    $socket->print($cmd);
    my $resp_ref = $self->{'resp_queue'}->dequeue();
    return $resp_ref;
}

###########################################################################
=pod

=head2 my $type = $tl1->get_cardtype(1, 12);

Return the type of card in the shelf given as first argument and the
slot given as second argument. Returns a string.

=cut

###########################################################################
# Return card type (CTYPE) string present in $shelf/$slot.
###########################################################################
sub get_cardtype {
    my ($self, $shelf, $slot) = @_;

    my $socket = $self->{'socket'};
    $socket->print("RTRV-INVENTORY::SLOT-$shelf-$slot:$self->{'ctag'};\n");
    my $resp = $self->{'resp_queue'}->dequeue();
    my $n = 0;
    while (defined($resp->[$n])) {
        if ($resp->[$n] =~ /"AP-\d+-\d+::CTYPE/) {
            # skip Access Panel line
        } elsif ($resp->[$n] =~ /"\S+-\d+-\d+::CTYPE=\\"(.*?)\\",/) {
            return $1;
        }
        $n++;
    }
    return undef();
}

###########################################################################
=pod

=head2 my $version = $tl1->get_swversion();

Returns the currently active firmware version on the TL1 device. Returns
a string.

=cut

###########################################################################
# Returns the currently active firmware version of the TL1 device.
###########################################################################
sub get_swversion {
    my ( $self  ) = @_;
    my $swversion;
    $self->_verbose(1, "Retrieve software vesion\n");
    my $socket = $self->{'socket'};
    if ($self->{'type'} eq "OME6500") {
        $socket->print("RTRV-SW-VER:::$self->{'ctag'};\n");
        my $resp = $self->{'resp_queue'}->dequeue();
        my $n = 0;
        while (defined($resp->[$n])) {
            # SHELF-1:REL0200Z.HQ
            if ($resp->[$n] =~ /"SHELF-1:(\w+).*"/) {
                $swversion = $1;
            }
            $n++;
        }
    } elsif ($self->{'type'} eq "HDXc") {
        $socket->print("RTRV-UPGRD-STATUS:::$self->{'ctag'};\n");
        my $resp = $self->{'resp_queue'}->dequeue();
        my $n = 0;
        while (defined($resp->[$n])) {
            # "RELEASE=HDX_Rel_03.30_fo09,...
            if ($resp->[$n] =~ /"RELEASE=([^,]+),/) {
                $swversion = $1;
            }
            $n++;
        }
    }
    return $swversion;
}

###########################################################################
=pod

=head2 my $octets = $tl1->get_inoctets(1, 3);

Returns the Ethernet input octets on the slot given as first argument
and the port given as second argument. Returns an integer.

=cut

###########################################################################
# Returns the Ethernet input octets on slot/port.
###########################################################################
sub get_inoctets {
    my ( $self  ) = @_;
    my $inoctets = 0;
    $self->_verbose( 1, "Retrieve input octets\n" );
    my $socket = $self->{'socket'};
    my $slot= $self->{'slot'};
    my $port = $self->{'port'};
    my $swver = $self->get_swversion;
    if (!defined($swver)) {
        return undef;
    }
#    if ($swver eq 'REL0200Z') {
#        $self->_verbose( 1, "sw version is REL0200Z  command RTRV-OM-ETH::ETH-1-$slot-$port:45::;\n" );
#        $socket->print("RTRV-OM-ETH::ETH-1-$slot-$port:$self->{'ctag'}::;\n");
#    } else  {
#        $socket->print("RTRV-OM-if::ETH-1-$slot-$port:$self->{'ctag'}::;\n");
#    }
    $socket->print("RTRV-OM-ETH::ETH-1-$slot-$port:$self->{'ctag'}::;\n");
    my $resp = $self->{'resp_queue'}->dequeue();
    my $n = 0;
    while (defined($resp->[$n])) {
    #match ETH-1-4-1::INFRAMES=343136315745,INFRAMESERR=0,INOCTETS=21960686905538,INDFR=1023574,INFRAMESDISCDS=0,INCFR=0,FRTOOSHORTS=0,FCSERR=0,FRTOOLONGS=0,OUTFRAMES=948548260,OUTOCTETS=68296800619,OUTPAUSEFR=0,OUTDFR=0,INTERNALMACRXERR=0,INTERNALMACTXERR=0,DEFERTRANS=77813222
        if ($resp->[$n] =~ /".*,INOCTETS=(\d+).*"/) {
            $inoctets = $1;
        }
        $n++;
    }
    return $inoctets;
}

###########################################################################
=pod

=head2 my $octets = $tl1->get_outoctets(7, 2);

Returns the Ethernet output octets on the slot given as first argument
and the port given as second argument. Returns an integer.

=cut

###########################################################################
# Returns the Ethernet output octets on slot/port.
###########################################################################
sub get_outoctets {
    my ( $self  ) = @_;
    my $outoctets = 0;
    $self->_verbose( 1, "Retrieve output octets\n" );
    my $socket = $self->{'socket'};
    my $slot= $self->{'slot'};
    my $port = $self->{'port'};
    my $swver = $self->get_swversion;
    if (!defined($swver)) {
        return undef;
    }
#    if ($swver eq 'REL0200Z') {
#        $self->_verbose( 1, "sw version is REL0200Z  command RTRV-OM-ETH::ETH-1-$slot-$port:45::;\n" );
#        $socket->print("RTRV-OM-ETH::ETH-1-$slot-$port:$self->{'ctag'}::;\n");
#    } else  {
#        $socket->print("RTRV-OM-if::ETH-1-$slot-$port:$self->{'ctag'}::;\n");
#    }
    $socket->print("RTRV-OM-ETH::ETH-1-$slot-$port:$self->{'ctag'}::;\n");
    my $resp = $self->{'resp_queue'}->dequeue();
    my $n = 0;
    while (defined($resp->[$n])) {
    #matchETH-1-4-1::INFRAMES=343136315745,INFRAMESERR=0,INOCTETS=21960686905538,INDFR=1023574,INFRAMESDISCDS=0,INCFR=0,FRTOOSHORTS=0,FC SERR=0,FRTOOLONGS=0,OUTFRAMES=948548260,OUTOCTETS=68296800619,OUTPAUSEFR=0,OUTDFR=0,INTERNALMACRXERR=0,INTERNALMACTXERR=0,DEFERTRANS=77813222
        if ($resp->[$n] =~ /".*,OUTOCTETS=(\d+).*"/) {
            $outoctets = $1;
        }
        $n++;
    }
    return $outoctets;
}

###########################################################################
=pod

=head2 my @alarms = $tl1->get_alarms();

Returns an array of hashes containing information about active alarms
on the TL1 device. Each entry in the array conatains information about
one alarm. The keys of each alarm are:

=over

=item *

interface

=item *

severity

=item *

impact

=item *

day

=item *

time

=item *

alarm

=item *

year

=item *

date

=item *

slot

=item *

subslot

=item *

port

=item *

fromfirststs

=back

Some of the keys can have an "undef" value.

=cut

###########################################################################
# Returns the active alarms on the TL1 device as an array of hashes.
###########################################################################
sub get_alarms {
    my ($self) = @_;
    my $key;
    my @result;
    my $ainfo;
    my $val;
    my $socket = $self->{'socket'};
    $self->_verbose( 1, "retrieving alarms for $self->{'type'}\n" );
    if ($self->{'type'} eq "OME6500") {
        $socket->print("RTRV-ALM-ALL:::$self->{'ctag'}:::;\n");
        my $resp = $self->{'resp_queue'}->dequeue();
        my $n = 0;
        while (defined($resp->[$n])) {
            # match "LAN-1-15,COM:MN,NET,NSA,11-01,15-44-31,NEND,NA:\"LAN-15 Port Failure\":0100000002-5003-0536,:YEAR=2005,MODE=NONE"
            if ($resp->[$n] =~ /"([^,]+),\w+:(\w+),\w+,(\w+),(\d+-\d+),(\d{1,2}-\d{1,2}-\d{1,2}),.*:\\"(.*)\\".*YEAR=(\d\d\d\d),.*"/) {
                #print "$1 $2 $3 $4 $5 $6 $7\n";
                my $interface = $1;
                my $severity = $2;
                my $impact = $3;
                my $day = $4;
                my $time = $5;
                my $alarm = $6;
                my $year = $7;
                my $date = "$7-$4";
                my $slot = undef;
                my $subslot = undef;
                my $port = undef;
                my $fromfirststs = undef;
                # interface can have diferent forms:
                # STS3C-1-5-1-88
                # WAN-1-2-4
                # ETH-1-1-2
                # 10G-1-10
                # FILLER-1-9
                if ($interface =~ /\w+-\d+-(\d+)-?(\d+)?-?(\d+)?/) {
                    $slot = $1;
                    if (defined $2){
                        #print "port is $2\n";
                        $port = $2;
                    }
                    if (defined $3){
                        #print "beginsts is $3\n";
                        $fromfirststs = $3;
                    }
                }

                $ainfo = {
                    interface => $interface,
                    slot => $slot,
                    subslot => $subslot,
                    port => $port,
                    fromfirststs => $fromfirststs,
                    severity => $severity,
                    impact => $impact,
                    date => $date,
                    time => $time,
                    alarm => $alarm
                };
                push @result, $ainfo;
            }
            $n++;
        }
        return @result;

    } elsif ($self->{'type'} eq "HDXc") {
        $socket->print("RTRV-ALM-ALL:::$self->{'ctag'}:::;\n");
        my $resp = $self->{'resp_queue'}->dequeue();
        my $n = 0;
        #print_resp($resp);
        while (defined($resp->[$n])) {
            # match "ESI-2-SATT-1,TMG:MN,SYNCLOS,NSA,09-13,04-18-28,NEND,RCV:\"Loss of signal\",,\"TYP-SH-SATT-PRT\",:000006-6040-0066,:YEAR=2005"
            if ($resp->[$n] =~ /"([^,]+),\w+:(\w+),\w+,(\w+),(\d+-\d+),(\d{1,2}-\d{1,2}-\d{1,2}),.*:\\"(.*)\\",.*,.*,.*:YEAR=(\d\d\d\d).*"/) {
                #print "$1 $2 $3 $4 $5 $6 $7\n";
                my $interface = $1;
                my $severity = $2;
                my $impact = $3;
                my $day = $4;
                my $time = $5;
                my $alarm = $6;
                my $year = $7;
                my $date = "$7-$4";
                my $slot = undef;
                my $subslot = undef;
                my $port = undef;
                my $fromfirststs = undef;

                # Interface format HDXc is:
                # Payload AID:
                # <type> <shelf> <slot> <subslot> <port> <signal> <offset>
                # signal seems to be always 1, not sure what this means.
                # offset is STS channel

                if ($interface =~
                    /^\w+-\d+-(\d+)-(\d+)-(\d+)-(\d+)-(\d+)/) {
                    $slot = $1;
                    $subslot = $2;
                    $port = $3;
                    $fromfirststs = $5;
                } elsif ($interface =~
                    /^\w+-\d+-(\d+)-(\d+)-(\d+)-(\d+)/) {
                    $slot = $1;
                    $subslot = $2;
                    $port = $3;
                } elsif ($interface =~
                        /^\w+-\d+-(\d+)-(\d+)/) {
                    $slot = $1;
                    $port = $2;
                } elsif ($interface =~ /^\w+-\d+-(\d+)/) {
                    $slot = $1;
                }
                $ainfo = {
                    interface => $interface,
                    slot => $slot,
                    subslot => $subslot,
                    port => $port,
                    fromfirststs => $fromfirststs,
                    severity => $severity,
                    impact => $impact,
                    date => $date,
                    time => $time,
                    alarm => $alarm
                };
                push @result, $ainfo;
            }
            $n++;
        }
        return @result;
    } elsif ($self->{'type'} eq "ONS15454") {
        $socket->print("RTRV-ALM-ALL:::$self->{'ctag'};\n");
        my $resp = $self->{'resp_queue'}->dequeue();
        my $n = 0;
        #print_resp($resp);
        while (defined($resp->[$n])) {
            # match FAC-3-1,G1000:MN,CARLOSS,NSA,11-23,16-43-47,,:\"Carrier Loss On The LAN\",G1000-4"
            # FAC-12-1,OC19:MN,LO-RXPO,NSA,11-01,06-49-20,,:\"Equipment Low Rx power\",OC192"
            if ($resp->[$n] =~ /"([^,]+),.*:(\w+),.*,(\w+),(\d+-\d+),(\d{1,2}-\d{1,2}-\d{1,2}),[^:]:\\"(.*)\\"/) {
                # print "$1 $2 $3 $4 $5 $6 $7\n";
                my $interface = $1;
                my $severity = $2;
                my $impact = $3;
                my $day = $4;
                my $time = $5;
                my $alarm = $6;
                my $slot = undef;
                my $subslot = undef;
                my $port = undef;
                my $fromfirststs = undef;

                # ONS does not report the year so we have to create this by ourselfs
                use Time::localtime;
                use Date::Manip;
                my $year = localtime->year() + 1900;
                my $date = "$year-$day";
                # now we need to test if the date is not a day in the future
                       my $testdate = ParseDate("$date");
                my $todaydate = ParseDate("today");     
                my $flag = Date_Cmp($testdate,$todaydate);
                if ($flag<0) {
                    #print " date1 is earlier\n";
                } elsif ($flag==0) {
                    #print " the two dates are identical\n";
                } else {
                        #print " testdate is earlier, so adjust to last year\n";
                         my $newdate = DateCalc("$testdate","-1 Year",\my $err);
                         $date = UnixDate("$newdate","%Y-%m-%d");
                         #print "$testdate\n";
                }
                
                # FAC-6-1  FAC-12-1
                if ($interface =~ /\w+-(\d+)-?(\d+)?-?(\d+)?/) {
                    $slot = $1;
                    if (defined $2){
                        #print "port is $2\n";
                        $port = $2;
                    }
                    if (defined $3){
                        #print "beginsts is $3\n";
                        $fromfirststs = $3;
                    }
                }
                $ainfo = {
                    interface => $interface,
                    slot => $slot,
                    subslot => $subslot,
                    port => $port,
                    fromfirststs => $fromfirststs,
                    severity => $severity,
                    impact => $impact,
                    date => $date,
                    time => $time,
                    alarm => $alarm
                };
                push @result, $ainfo;
            }
            $n++;
        }
        return @result;
    }
}

###########################################################################
=pod

=head2 my @crossconnects = $tl1->get_crossconnects();

Retrieve information about crossconnects on the TL1 device. The
information is returned as an array of hashes. Each entry in the
array is information about one crossconnect. The crossconnect
information consists of a hash with these keys:

=over

=item *

ckid: crossconnect ID

=item *

nr_timeslots: total amount of timeslots

=item *

from_slot: slot of "from" interface

=item *

from_subslot: subslot of "from" interface

=item *

from_port: port of "from" interface

=item *

from_first_ts: first timeslot on "from" interface

=item *

from_last_ts: last timeslot on "from" interface

=item *

to_slot: slot of "to" interface

=item *

to_subslot: subslot of "to" interface

=item *

to_port: port of "to" interface

=item *

to_first_ts: first timeslot on "to" interface

=item *

to_last_ts: last timeslot on "to" interface

=item *

swmate_slot: slot of "switchmate" interface

=item *

swmate_subslot: subslot of "switchmate" interface

=item *

swmate_port: port of "switchmate" interface

=item *

swmate_first_ts: first timeslot on "switchmate" interface

=item *

swmate_last_ts: last timeslot on "switchmate" interface

=back


=cut

###########################################################################
# Retrieve information about crossconnects on the TL1 device.
###########################################################################
sub get_crossconnects {
    my ($self) = @_;
    my %sts;
    my $key;
    my @result;
    my $val;
    my $socket = $self->{'socket'};
    $self->_verbose( 1, "retrieving circuits for $self->{'type'}\n" );
    if ($self->{'type'} eq "OME6500") {
        $socket->print("RTRV-CRS-COUNT:::$self->{'ctag'}::;\n");
        my $resp = $self->{'resp_queue'}->dequeue();
        my $n = 0;
        while (defined($resp->[$n])) {
            # match "SHELF-1:STS3C,8"
            # first we need to determine which crossconnects are there (sts3, sts24, sts192 etc..)
            if ($resp->[$n] =~ /SHELF-\d+:(STS\w+),\d+/) {
                $sts{$1} = 1;
            }
            $n++;
        }
        # now for each type of crossconnect retrieve the info
        foreach $key (keys %sts) {
            $socket->print("RTRV-CRS-".$key."::ALL:$self->{'ctag'}:::DISPLAY=PROV,CKTID=ALL;\n");
            my $resp = $self->{'resp_queue'}->dequeue();
            my $n = 0;
            while (defined($resp->[$n])) {
                # match "STS3C-1-9-1-1,STS3C-1-4-101-1:2WAY:CKTID=\"test\":"
                # match "STS3C-1-9-1-19,STS3C-1-2-1-19:2WAYPR:SWMATE=STS3C-1-6-1-40,CKTID=\"Ah001A-Es001A_GE1(Artez) \":"
                if ($resp->[$n] =~ /(STS\w+)-(\d+)-(\d+)-(\d+)-(\d+),STS\w+-(\d+)-(\d+)-(\d+)-(\d+):(2WAY:|2WAYPR:SWMATE=STS\w+)?-?(\d+)?-?(\d+)?-?(\d+)?-?(\d+)?.*CKTID=\\"([^:]+)\\":"/) {

                    my $xinfo = {};
                    my $ckid = $15;
                    my $bandwidth = $1;
                    my $nr_timeslots = $bandwidth;
                    my $shelf = $2;
                    my $from_slot = $3;
                    my $from_subslot = '';
                    my $from_port = $4;
                    my $from_first_ts;
                    my $from_last_ts;
                    my $to_slot = $7;
                    my $to_subslot = '';
                    my $to_port = $8;
                    my $to_first_ts;
                    my $to_last_ts;
                    my $swmate_slot = $12;
                    my $swmate_subslot = '';
                    my $swmate_port = $13;
                    my $swmate_first_ts;
                    my $swmate_last_ts;

                    $from_first_ts = $5;
                    
                    $to_first_ts = $9;

                    if (defined $swmate_slot) {
                            $swmate_first_ts = $14;
                            $nr_timeslots =~ s/\D//g;
                            $swmate_last_ts = $swmate_first_ts + $nr_timeslots - 1;
                    }

                    $nr_timeslots =~ s/\D//g;
                    $from_last_ts = $from_first_ts + $nr_timeslots - 1;
                    $to_last_ts = $to_first_ts + $nr_timeslots - 1;

                    # catch undefined values
                    if (not defined $swmate_slot) {
                        $swmate_slot = '';
                    }
                    if (not defined $swmate_port) {
                        $swmate_port = '';
                    }
                    if (not defined $swmate_first_ts) {
                        $swmate_first_ts = '';
                    }
                    if (not defined $swmate_last_ts) {
                        $swmate_last_ts = '';
                    }
                    $xinfo = {
                        ckid => $ckid,
                        nr_timeslots => $nr_timeslots,
                        from_slot => $from_slot,
                        from_subslot => $from_subslot,
                        from_port => $from_port,
                        from_first_ts => $from_first_ts,
                        from_last_ts => $from_last_ts,
                        to_slot => $to_slot,
                        to_subslot => $to_subslot,
                        to_port => $to_port,
                        to_first_ts => $to_first_ts,
                        to_last_ts => $to_last_ts,
                        swmate_slot => $swmate_slot,
                        swmate_subslot => $swmate_subslot,
                        swmate_port => $swmate_port,
                        swmate_first_ts => $swmate_first_ts,
                        swmate_last_ts => $swmate_last_ts
                    };
                    push @result, $xinfo;
                }
                $n++;
            }
        }
    } elsif ($self->{'type'} eq "HDXc") {
        # Voor de HDXc
        $socket->print("RTRV-CRS-ALL:::$self->{'ctag'};\n");
        my $resp = $self->{'resp_queue'}->dequeue();
        my $n = 0;
        #print_resp($resp);
        while (defined($resp->[$n])) {
            # match  "OC192-1-503-0-1-1-49,OC192-1-505-0-3-1-49:2WAY,STS-48C:PRIME=OSS,DISOWN=IDLE,CONNID=881,LABEL=\"SC05-Prague-Chicago-1\",AST=LOCKED:ACT"
            if ($resp->[$n] =~ /[^-]+-(\d+)-(\d\d\d)-(\d)-(\d)-\d{1,3}-(\d{1,3}),[^-]+-\d+-(\d\d\d)-(\d)-(\d)-\d{1,3}-(\d{1,3}):[^,]+,([^:]+):.*LABEL=\\\"(.*)\\\",/) {
                my $xinfo = {};
                my $ckid = $11;
                my $bandwidth = $10;
                my $shelf = $1;
                my $from_slot = $2;
                my $from_subslot = $3;
                my $from_port = $4;
                my $from_first_ts = $5;
                my $to_slot = $6;
                my $to_subslot = $7;
                my $to_port = $8;
                my $to_first_ts = $9;
                my $nr_timeslots = $bandwidth;
                # \D remove all non digits
                $nr_timeslots =~ s/\D//g;
                my $from_last_ts = $from_first_ts + $nr_timeslots - 1;
                my $to_last_ts = $to_first_ts + $nr_timeslots - 1;

                $xinfo = {
                    ckid => $ckid,
                    nr_timeslots => $nr_timeslots,
                    from_slot => $from_slot,
                    from_subslot => $from_subslot,
                    from_port => $from_port,
                    from_first_ts => $from_first_ts,
                    from_last_ts => $from_last_ts,
                    to_slot => $to_slot,
                    to_subslot => $to_subslot,
                    to_port => $to_port,
                    to_first_ts => $to_first_ts,
                    to_last_ts => $to_last_ts
                };
                push @result, $xinfo;
            }
            $n++;
        }
        #print "$val\n" while defined($val = pop(@result));
    } elsif ($self->{'type'} eq "ONS15454") {
        $socket->print("RTRV-CRS:::$self->{'ctag'};\n");
        my $resp = $self->{'resp_queue'}->dequeue();
        my $n = 0;
        #print_resp($resp);
        while (defined($resp->[$n])) {
            # match "STS-6-1-73,STS-12-1-97:2WAY,STS24C:CKTID=\"CERN-Vancouver 2 - TST\":IS-NR,"
            if ($resp->[$n] =~ /"\w+-(\d+)-(\d+)-?(\d+)?,\w+-(\d+)-(\d+)-?(\d+)?:[^,]+,([^:]+):CKTID=\\\"(.*)\\\":/) {
                my $xinfo = {};
                my $ckid = $8;
                my $bandwidth = $7;
                my $from_slot = $1;
                my $from_subslot = '';
                my $from_port = $2;
                my $from_first_ts = $3;
                my $to_slot = $4;
                my $to_subslot = '';
                my $to_port = $5;
                my $to_first_ts = $6;
                my $nr_timeslots;
                my $from_last_ts;
                my $to_last_ts;
                #calculate end sts, bandwidth is $7 from sts is $3 and $6
                if (defined $3){      
                    $nr_timeslots = $bandwidth;
                    $nr_timeslots =~ s/\D//g;
                    $from_last_ts = $from_first_ts + $nr_timeslots - 1;     
                }
                if (defined $6){
                    $nr_timeslots = $bandwidth;
                    $nr_timeslots =~ s/\D//g;
                    $to_last_ts = $to_first_ts + $nr_timeslots - 1;     
                }
                # catch undefined values
                if (not defined $from_first_ts) {
                    $from_first_ts = '';
                }
                if (not defined $from_last_ts) {
                    $from_last_ts = '';
                }
                if (not defined $to_first_ts) {
                    $to_first_ts = '';
                }
                if (not defined $to_last_ts) {
                    $to_last_ts = '';
                }

                $xinfo = {
                    ckid => $ckid,
                    nr_timeslots => $nr_timeslots,
                    from_slot => $from_slot,
                    from_subslot => $from_subslot,
                    from_port => $from_port,
                    from_first_ts => $from_first_ts,
                    from_last_ts => $from_last_ts,
                    to_slot => $to_slot,
                    to_subslot => $to_subslot,
                    to_port => $to_port,
                    to_first_ts => $to_first_ts,
                    to_last_ts => $to_last_ts
                };
                push @result, $xinfo;
            }
            $n++;
        }

    }
    return @result;
}

###########################################################################
=pod

=head2 my $trace = $tl1->get_section_trace(1, 12, 1);

Return the received section trace on the port given as arguments.
The first argument is the shelf number, the second argument is
the slot number and the third argument is the port number. This
function returns a string.

=cut

###########################################################################
# Return the "section trace" string received on $shelf/$slot/$port
###########################################################################
sub get_section_trace {
    my ($self, $shelf, $slot, $port) = @_;

    my $speed;
    my $socket = $self->{'socket'};
    my $cardtype = get_cardtype($self, $shelf, $slot);
    if (!defined($cardtype)) {
        return undef();
    }
    if ($cardtype =~ /\d+xOC-(\d+)/) {
        $speed = $1;
    } else {
        return undef();
    }
    $socket->print("RTRV-TRC-OC${speed}::" .
        "OC$speed-$shelf-$slot-${port}:$self->{'ctag'}::INCSTRC;\n");
    my $resp = $self->{'resp_queue'}->dequeue();
    my $n = 0;
    while (defined($resp->[$n])) {
        if ($resp->[$n] =~ /"OC\d+-\d+-\d+-\d+:\\"(.*?)\\"/) {
            my $trace = $1;
            return $trace;
        }
        $n++;
    }
    return(undef());
}


sub check_resp {
    my $resp = shift;
    my $n = 0;
    while (defined($resp->[$n])) {
        if ($resp->[$n] =~ /M\s+\w+\s+(\w+)/) {
            return $1;
        }    
        $n++;
    }
}

###########################################################################
=pod

=head2 $tl1->print_resp($output);

This function prints the output returned by the cmd() function
on STDOUT.

=cut

###########################################################################
# Prints the output returned by the cmd() function.
###########################################################################
sub print_resp {
    my ( $self, $resp ) = @_;
    my $n = 0;
    while (defined($resp->[$n])) {
        print $n, " ",  $resp->[$n], "\n";
        $n++;
    }
}


###########################################################################
# Send TL1 command and forget response or use code referent to process response
###########################################################################
sub async_cmd {
    my ( $self, $cmd ) = @_;
    $self->{'acmd_queue'}->enqueue($cmd);
}

1;

###########################################################################
=pod

=head1 AUTHORS

Ronald van der Pol, SARA High Performance Networking,  Amsterdam, 2005 - 2008.

Andree Toonk, SARA High Performance Networking,  Amsterdam, 2005 - 2007.

=head1 ACKNOWLEDGEMENTS

This work is funded by SURFnet and GigaPort:

http://www.surfnet.nl/

http://www.gigaport.nl/

This module is based on a module by Arien Vijn, AMS-IX B.V. (2005). 

=head1 COPYRIGHT

  +------------------------------------------------------------------+
  | Licensed under the Apache License, Version 2.0 (the "License");  |
  | you may not use this file except in compliance with the License. |
  | You may obtain a copy of the License at                          |
  |                                                                  |
  |     http://www.apache.org/licenses/LICENSE-2.0                   |
  |                                                                  |
  | Unless required by applicable law or agreed to in writing,       |
  | software distributed under the License is distributed on an      |
  | "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     |
  | either express or implied. See the License for the specific      |
  | language governing permissions and limitations under the         |
  | License.                                                         |
  +------------------------------------------------------------------+

=head1 REQUIRES

threads;

threads::shared;

Thread::Queue::Any;

Net::Telnet;

Time::localtime;

Date::Manip;

=head1 RELEASED

December 2008

=cut
