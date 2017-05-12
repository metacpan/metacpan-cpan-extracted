#!/usr/bin/perl
use strict;
use warnings;
use POE qw( Component::Server::IRC Component::Client::Lingr Component::TSTP );
use Getopt::Long;

GetOptions('--api-key=s', \my $api_key, '--port' => \my $port);
Getopt::Long::Configure("bundling");

#$POE::Component::Client::Lingr::Debug = 1;

$api_key or die "Usage: lingr-ircd.pl API_KEY\n";

our $Root = "lingr";

my $config = {
    api_key => $api_key,
    server  => "lingr.ircd",
    port    => $port,
};

# for Ctrl-Z
POE::Component::TSTP->create();

my %config = (
    servername => $config->{server},
    nicklen    => 15,
    network    => 'SimpleNET'
);

# start ircd session
my $pocosi = POE::Component::Server::IRC->spawn( config => \%config );

POE::Session->create(
    inline_states => {
        _start   => \&_start,
        ircd_daemon_nick => \&ircd_nick,
#        ircd_daemon_join => \&ircd_join,
        ircd_daemon_privmsg => \&ircd_privmsg,
        ircd_daemon_public  => \&ircd_public,
    },
    heap => { ircd => $pocosi },
);

$poe_kernel->run();

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # register ircd to receive events
    $heap->{ircd}->yield( 'register' );
    $heap->{ircd}->add_auth( mask => '*@*' );
    $heap->{ircd}->add_listener( port => $config->{port} || 6667 );

    # add super user
    $heap->{ircd}->yield(add_spoofed_nick => { nick => $Root });

    # register my POE::Session to recieve Lingr events
    $_[KERNEL]->post(lingr => 'register');
    $_[KERNEL]->post(lingr => call => 'session.create', { api_key => $config->{api_key} });

    # TODO: maintain session ID by calling once per 10 minutes
    # TODO: retrieve session ID when it timeouts

    undef;
}

sub ircd_nick {
    my($kernel, $heap, $nick, $host) = @_[KERNEL, HEAP, ARG0, ARG5];

    if ($host eq $config->{server}) {
        return;
    }

    my $text = "Hello $nick! Tell me your Lingr email and password, separated by space (e.g. 'you\@example.com password')";
    $heap->{ircd}->yield(daemon_cmd_privmsg => $Root, $nick, $text);
    $heap->{nick} = $nick;
}

sub ircd_privmsg {
    my($kernel, $heap, $user, $to, $text) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];

    if ($to eq $Root) {
        # TODO: support more syntaxes like "help"
        my($email, $password) = split / /, $text, 2;
        my $nick = ($user =~ m/^(.*)!/)[0];

        warn "Creating Lingr session for $nick";

        # Create Lingr session for this user now
        my $lingr = POE::Component::Client::Lingr->spawn();

        $heap->{lingr_session}->{$nick} = POE::Session->create(
            inline_states => {
                _start => \&lingr_start,
                lingr_say => \&lingr_say,
                'lingr.session.create' => \&lingr_session_create,
                'lingr.room.enter'   => \&lingr_room_enter,
                'lingr.room.observe' => \&lingr_room_observe,
                'lingr.auth.login'     => \&lingr_auth_login,
                'lingr.user.getInfo'   => \&lingr_user_get_info,
            },
            heap => {
                email => $email,
                password => $password,
                lingr => $lingr,
                nick  => $nick,
                ircd  => $heap->{ircd},
            },
        )->ID;
    }
}

sub ircd_public {
    my($kernel, $heap, $user, $channel, $text) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];

    return if $user =~ /\@\Q$config->{server}\E$/;
    my $nick = ( $user =~ m/^(.*)!/)[0];

    # XXX we shold check $channel as well for multiple channels support
    if (my $session = $heap->{lingr_session}->{$nick}) {
        $kernel->post($session => "lingr_say", $text);
    }

}

sub lingr_start {
    my($kernel, $heap) = @_[KERNEL, HEAP];
    warn "starting lingr client. Create a session";
    $heap->{lingr}->yield('register');
    $heap->{lingr}->yield(call => 'session.create', { api_key => $config->{api_key} });
}

sub lingr_say {
    my($kernel, $heap, $text) = @_[KERNEL, HEAP, ARG0];
    $heap->{lingr}->yield(call => 'room.say', { message => $text });
}

sub lingr_session_create {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
    warn "Lingr session created: $event->{session}\n";
    warn "Authenticate user $heap->{email} in behalf of $heap->{nick}";
    $heap->{lingr}->yield(call => "auth.login", { email => $heap->{email}, password => $heap->{password} });
}

sub lingr_auth_login {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
    warn "Auth successful. Now call user.getInfo";
    $heap->{lingr}->yield(call => "user.getInfo");
}

sub lingr_user_get_info {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
    for my $room (@{ $event->{favorite_rooms} || [] }) {
        warn "Entering $room->{name} on Lingr";
        $heap->{lingr}->yield(call => 'room.enter' => { id => $room->{id}, nickname => $heap->{nick} });
        last; # xxx support multi channel
    }
}

sub lingr_room_enter {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
    warn "Entered room: $event->{room}->{name}\n";

    $heap->{channel} = '#' . ($event->{room}->{url} =~ m!^http://www\.lingr\.com/room/(.*)$!)[0]; # xxx
    $heap->{ircd}->yield(daemon_cmd_join => $Root, $heap->{channel});

    for my $occupant (@{$event->{occupants} || []}) {
        my $nick = $occupant->{nickname} or next;
        join_nick($heap, $nick);
    }

    # Auto add the user to this channel
    $heap->{ircd}->_daemon_cmd_join($heap->{nick}, $heap->{channel});

    # Set topic
    $heap->{ircd}->_daemon_cmd_topic($heap->{nick}, $heap->{channel}, $event->{room}->{description});

    # TODO: display recent messages by $Root user
}

sub join_nick {
    my($heap, $nick) = @_;

    return if $heap->{ircd}->state_is_chan_member($nick, $heap->{channel});
    return if $nick eq $heap->{nick}; # this is me!

    warn "Adding $nick to $heap->{channel}";
    $heap->{ircd}->yield(add_spoofed_nick => { nick => $nick });
    $heap->{ircd}->yield(daemon_cmd_join  => $nick, $heap->{channel});
}

sub part_nick {
    my($heap, $nick) = @_;

    return unless $heap->{ircd}->state_is_chan_member($nick, $heap->{channel});
    return if $nick eq $heap->{nick}; # this is me!

    warn "Removing $nick from $heap->{channel}";
    $heap->{ircd}->yield(daemon_cmd_part => $nick, $heap->{channel});
}

sub lingr_room_observe {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];

    for my $msg (@{$event->{messages} || []}) {
        if ($msg->{type} eq 'system:enter') {
            join_nick($heap, $msg->{nickname});
        } elsif ($msg->{type} eq 'system:leave') {
            part_nick($heap, $msg->{nickname});
        } else {
            $heap->{ircd}->yield(daemon_cmd_privmsg => $msg->{nickname}, $heap->{channel}, $msg->{text});
        }
    }
}
