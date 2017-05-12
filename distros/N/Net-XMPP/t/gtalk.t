use strict;
use warnings;

use Test::More;

######################## XML::Stream mocking starts
#{
#   package XML::Stream;
#   our $AUTOLOAD;
#   use Data::Dumper;
#
#   sub new {
#       bless {}, shift;
#   }
#   sub Connect {
#   }
#   sub GetErrorCode {
#   }
#   sub GetStreamFeature {
#   }
#   sub SASLClient {
#   }
#   DESTROY {
#   }
#
#   AUTOLOAD {
#       print Dumper [$AUTOLOAD, \@_];
#   }
#
#}
#$INC{'XML/Stream.pm'} = 1;
######################## XML::Stream mocking ends

my @users;
foreach my $name (qw(GTALK0 GTALK1)) {
    if ($ENV{$name}) {
        my ($user, $pw) = split /:/, $ENV{$name};
        push @users, {
              username => $user,
              password => $pw,
        };
    }
}

eval "use Test::Memory::Cycle";
my $memory_cycle = ! $@;
my $leak_guard;

BEGIN {
    eval "use Devel::LeakGuard::Object qw(leakguard)";
    $leak_guard = ! $@;
}

my $repeat = 5;
plan tests => 2 + 6 * $repeat;

# TODO ask user if it is ok to do network tests!
print_size('before loading Net::XMPP');
require Net::XMPP;
print_size('after loading Net::XMPP');
# see
# http://blogs.perl.org/users/marco_fontani/2010/03/google-talk-with-perl.html
{
  # monkey-patch XML::Stream to support the google-added JID
  package XML::Stream;
  no warnings 'redefine';

  sub SASLAuth {
    my $self         = shift;
    my $sid          = shift;
    my $first_step   = $self->{SIDS}->{$sid}->{sasl}->{client}->client_start();
    my $first_step64 = MIME::Base64::encode_base64( $first_step, "" );
    $self->Send(
      $sid,
      "<auth xmlns='"
        . &ConstXMLNS('xmpp-sasl')
        . "' mechanism='"
        . $self->{SIDS}->{$sid}->{sasl}->{client}->mechanism() . "' "
        . q{xmlns:ga='http://www.google.com/talk/protocol/auth'
            ga:client-uses-full-bind-result='true'} .    # JID
        ">" . $first_step64 . "</auth>"
    );
  }
}

my $mem1 = run();
my $mem_last = $mem1;
for (2..$repeat) {
    $mem_last = run();
}

# The leakage shown here happens even before Authentication is called
#SKIP: {
#    skip 'Devel::LeakGuard::Object is needed', 1 if not $leak_guard;
#    my $warn;
#    local $SIG{__WARN__} = sub { $warn = shift };
#    leakguard {
#         run();
#    };
#
#    ok(!$warn, 'leaking') or diag $warn;
#}


# as I can see setting up the connection leaks in the first 5 attempts 
# and then it stops leaking. I tried it with repeate=25
# When adding AuthSend to the mix the code keeps leaking even after 20 repeats.
# Still the total leak is only 130 in 25 repeats
# After duplicating the connections (having two users),
# adding the CallBacks and handling the presence messages.
# the leak after 25 repeats went up to 152.
#
# This might need to be added to a test case.
# For now we only check if it "does not leak too much"
diag 'Memory change: ' . ($mem_last - $mem1);
TODO: {
   local $TODO = 'Memory leak or expectations being to high?';
   is $mem_last, $mem1, 'expected 0 memory growth';
}
cmp_ok $mem_last, '<', $mem1+160, 'does not leak much' or diag 'Leak: ' . ($mem_last-$mem1);


# tools when XML::Stream mocking
#use Data::Dumper;
#die Dumper \%INC;
#foreach my $k (keys %INC) {
#    if ($k =~ m{XML}) {
#       diag $k;
#    }
#}
# end tools

exit;



sub run {
    my @conn;
    for my $i (0,1) {
        $conn[$i]   = Net::XMPP::Client->new;
        isa_ok $conn[$i], 'Net::XMPP::Client';

        my $status = $conn[$i]->Connect(
            hostname       => 'talk.google.com',
            port           => 5222,
            componentname  => 'gmail.com',
            connectiontype => 'tcpip',
            tls            => 1,
            ssl_verify     => 0,
        );

        SKIP: {
            skip 'Needs Test::Memory::Cycle', 1 if not $memory_cycle; 
            memory_cycle_ok($conn[$i], 'after calling Connect');
        }

        SKIP: {
            skip "need GTALK$i = username:password", 1 if not $users[$i];

            my ( $res, $msg ) = $conn[$i]->AuthSend(
                username => $users[$i]{username},
                password => $users[$i]{password},
                resource => 'notify v1.0',
            );
            is $res, 'ok', 'result is ok';
            if (not defined $res or $res ne 'ok') {
               diag $!;
            }

            $conn[$i]->SetCallBacks(
                message => \&on_message,
                presence => \&on_presence,
                receive  => \&on_receive,
            );
            $conn[$i]->PresenceSend();
        }
    }

    for my $i (0..5) {
        my $status = $conn[$i % 2]->Process(1);
        die if not defined $status;
    }
    # receive presence message
    # send and receive messages

    return print_size('after calling Run');
}

sub print_size {
    my ($msg) = @_;
    return 0 if not -x '/bin/ps';
    my @lines = grep { /^$$\s/ } qx{/bin/ps -e -o pid,rss,command};
    chomp @lines;
    my $RSS;
    foreach my $line (@lines) {
        my ($pid, $rss) = split /\s+/, $line;
        diag "RSS: $rss   - $msg";
        $RSS = $rss;
    }
    return $RSS;
}

sub on_presence {
    my ($sid, $presence) = @_;
    my $to = $presence->GetTo;
    my $from = $presence->GetFrom;
    my $type = $presence->GetType || 'available';
    my $status = $presence->GetStatus || '';

    ($to)   = split m{/}, $to;
    ($from) = split m{/}, $from;

    diag "$to - $from - $type - $status";
}

sub on_receive {
    # called on every message received
}

sub on_message {
    my ($message) = @_;
    my $type     = $message->GetType;
    my $fromJID  = $message->fromJID('jid');
    my $from     = $message->GetUserID;
    my $resource = $message->GetResource;
    my $subject  = $message->GetSubject;
    my $body     = $message->GetBody;
    my $xml      = $message->GetXML;

    diag "$from - $body";
}

