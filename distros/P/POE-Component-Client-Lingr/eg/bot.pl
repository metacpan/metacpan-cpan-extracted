#!/usr/bin/perl
use strict;
use warnings;
use POE qw( Component::Client::Lingr Component::TSTP );

my $api_key = $ARGV[0] or die "Usage: connect.pl API_KEY\n";
my $room    = $ARGV[1] || "lingr-perl";
my $nick    = $ARGV[2] || "PoCo-Lingr/" . POE::Component::Client::Lingr->VERSION;

# for Ctrl-Z
POE::Component::TSTP->create();

# start Lingr session
POE::Component::Client::Lingr->spawn(alias   => 'lingr');

POE::Session->create(
    inline_states => {
        _start => sub {
            # register my POE::Session to recieve events
            $_[KERNEL]->post(lingr => 'register');
            # create session using API KEY
            # this automatically stores the retrieved session ID to HEAP
            $_[KERNEL]->post(lingr => call => 'session.create', { api_key => $api_key });
        },
        'lingr.session.create' => \&lingr_session_create,
        'lingr.room.enter'     => \&lingr_room_enter,
        'lingr.room.observe'   => \&lingr_room_observe,
    },
);

POE::Kernel->run;

sub lingr_session_create {
    my($kernel, $event) = @_[KERNEL, ARG0];
    warn "Session created: $event->{session}\n";

    # enter the room $room
    # this automatically creates another Session to observe the room
    $kernel->call(lingr => call => 'room.enter' => { id => $room, nickname => $nick });
}

sub lingr_room_enter {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
    warn "Entered room: $event->{room}->{name}\n";
    warn "Occupants:\n";
    for my $occupant (@{$event->{occupants} || []}) {
        my $nick = $occupant->{nickname} || "(anonymous)";
        if ($occupant->{client_type} eq 'automaton') {
            $nick .= "*";
        }
        warn "  $nick\n";
    }
    $heap->{room} = $event->{room};
}

sub lingr_room_observe {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];

    for my $msg (@{$event->{messages} || []}) {
        warn "$msg->{nickname}: $msg->{text} ($msg->{timestamp})\n";

        # Homework: make this pluggable
        if ($msg->{text} =~ m!^calc: (.*)!) {
            eval {
                require WWW::Google::Calculator;
                my $answer = WWW::Google::Calculator->new->calc($1); # xxx blocks!
                $kernel->post(lingr => call => 'room.say', { message => $answer });
            };
            warn $@ if $@;
        }
    }
}
