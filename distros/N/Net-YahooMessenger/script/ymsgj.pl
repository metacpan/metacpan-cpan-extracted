#!perl

use Net::YahooMessenger;
use Jcode;
use strict;

my $yahoo;
my ( $yahoo_id, $password );
while (1) {
    $yahoo_id = get_yahoo_id() unless $yahoo_id;
    $password = get_password($yahoo_id);

    $yahoo = Net::YahooMessenger->new(
        id            => $yahoo_id,
        password      => $password,
        hostname      => 'cs.yahoo.co.jp',
        pre_login_url => 'http://edit.my.yahoo.co.jp/config/',
    );
    $yahoo->set_event_handler( new CommandLineEventHandler );

    print "\n";
    print "Connecting to Yahoo! as $yahoo_id\n";
    $yahoo->login and last;

    print STDERR "[system] Invalid Login\n";
    print STDERR "Make sure your ID and PASSWORD are entered correctly.\n";
}

$|++;
my $to = $yahoo_id;
$yahoo->add_event_source(
    \*STDIN,
    sub {
        my $message = scalar <STDIN>;
        chomp $message;
        if ( $message =~ m{^/sw\s+(.+)$} ) {
            $to = $1;
        }
        elsif ( $message =~ m{^/st\s+([0-9])$} ) {
            $yahoo->change_status_by_code($1);
        }
        elsif ( $message =~ m{^/st\s+(.+)$} ) {
            $yahoo->change_state( 0, Jcode->new($1)->sjis );
        }
        elsif ( $message =~ m{^/q$} ) {
            exit;
        }
        elsif ( $message =~ m{^/w$} ) {
            my $users = join "\n",
              map { $_->to_string } grep { $_->is_online } $yahoo->buddy_list;
            print Jcode->new($users)->euc, "\n";
        }
        elsif ( $message =~ m{^/h$} ) {
            print <<__USAGE__;
Usage:
/sw YAHOO_ID
/st CUSTOM_STATUS or STATUS_CODE
/w
/h
/q
__USAGE__
        }
        elsif ( $message ne '' ) {
            $yahoo->send( $to, Jcode->new($message)->sjis );
            printf "[$yahoo_id] %s\n", Jcode->new($message)->euc;
        }
    },
    'r'
);
$yahoo->start;

exit;

sub get_yahoo_id {
    my $yahoo_id;
    while (1) {
        print "Yahoo ID: ";
        chomp( $yahoo_id = <STDIN> );
        return $yahoo_id if $yahoo_id ne '';
    }
}

sub get_password {
    my $yahoo_id = shift;
    my $password;
    while (1) {
        system 'stty -echo';
        print "Password[$yahoo_id]: ";
        chomp( $password = <STDIN> );
        system 'stty echo';
        print "\n";
        return $password if $password ne '';
    }
}

package CommandLineEventHandler;
use base 'Net::YahooMessenger::EventHandler';
use strict;
use Jcode;

use constant STATUS_MESSAGE => [
    "I'm Available",
    'Be Right Back',
    'Busy',
    'Not At Home',
    'Not At My Desk',
    'Not In The Office',
    'On The Phone',
    'On Vacation',
    'Out To Lunch',
    'Stepped Out',
];

sub UnImplementEvent {
    my $self  = shift;
    my $event = shift;
}

sub Login {
    my $self  = shift;
    my $event = shift;
    my $yahoo = $event->get_connection;
    printf "[system] Friends for - %s\n", $event->from;

    my $baddy_status = join "\n", map { $_->to_string } $yahoo->buddy_list;
    print Jcode->new($baddy_status)->euc, "\n";
}

sub GoesOnline {
    my $self  = shift;
    my $event = shift;

    printf "[system] %s goes in.\n", $event->from;
}

sub GoesOffline {
    my $self  = shift;
    my $event = shift;

    if ( $event->from ) {
        printf "[system] %s goes out.\n", $event->from;
    }
    else {
        print
"[system] You have been logged off as you have logged in on a different machine.\n";
        exit;
    }
}

sub ChangeState {
    my $self  = shift;
    my $event = shift;

    my $busy_status =
        $event->busy == 1 ? '(Busy) '
      : $event->busy == 2 ? '(Sleep) '
      :                     '';

    my $message;
    if ( $event->status_code == 99 ) {
        $message = sprintf "[%s] %sTransit to '%s'\n",
          $event->from, $busy_status, $event->body;
    }
    else {
        $message = sprintf "[%s] %sTransit to '%s'\n",
          $event->from, $busy_status, STATUS_MESSAGE->[ $event->status_code ];
    }
    print Jcode->new($message)->euc;
}

sub NewFriendAlert {
    my $self  = shift;
    my $event = shift;

    my $message =
      sprintf "[system] New Friend Alert: %s added %s as a Friend.\n",
      $event->from, $event->to;
    $message .= sprintf "and also sent the following message: %s\n",
      $event->body;
    print Jcode->new($message)->euc;
}

sub ReceiveMessage {
    my $self  = shift;
    my $event = shift;

    my $body = $event->body;
    $body =~ s{</?(?:font|FACE).+?>}{}g;
    my $message = sprintf "[%s] %s\n", $event->from, $body;
    print Jcode->new($message)->euc;
}

1;

__END__


