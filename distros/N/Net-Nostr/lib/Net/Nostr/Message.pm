package Net::Nostr::Message;

use strictures 2;

use Carp qw(croak);
use JSON;
use Net::Nostr::Event;
use Net::Nostr::Filter;
use Class::Tiny qw(type subscription_id event event_id accepted message prefix filters challenge);

my $JSON = JSON->new->utf8;

sub _validate_subscription_id {
    my ($sub_id) = @_;
    croak "subscription_id must be a non-empty string"
        unless defined $sub_id && length($sub_id) > 0;
    croak "subscription_id must be at most 64 characters"
        unless length($sub_id) <= 64;
}

sub _extract_prefix {
    my ($message) = @_;
    return undef unless defined $message && $message =~ /^([a-z-]+): /;
    return $1;
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {}, $class;

    croak "type is required" unless defined $args{type};
    $self->type($args{type});

    my $type = $args{type};

    if ($type eq 'EVENT') {
        croak "event is required for EVENT message" unless $args{event};
        $self->event($args{event});
        $self->subscription_id($args{subscription_id}) if defined $args{subscription_id};
    } elsif ($type eq 'REQ') {
        _validate_subscription_id($args{subscription_id});
        $self->subscription_id($args{subscription_id});
        croak "req requires at least one filter"
            unless $args{filters} && @{$args{filters}};
        $self->filters($args{filters});
    } elsif ($type eq 'CLOSE') {
        _validate_subscription_id($args{subscription_id});
        $self->subscription_id($args{subscription_id});
    } elsif ($type eq 'OK') {
        $self->event_id($args{event_id});
        $self->accepted($args{accepted} ? 1 : 0);
        $self->message($args{message} // '');
        $self->prefix(_extract_prefix($self->message));
    } elsif ($type eq 'EOSE') {
        $self->subscription_id($args{subscription_id});
    } elsif ($type eq 'NOTICE') {
        $self->message($args{message});
    } elsif ($type eq 'CLOSED') {
        $self->subscription_id($args{subscription_id});
        $self->message($args{message});
        $self->prefix(_extract_prefix($self->message));
    } elsif ($type eq 'AUTH') {
        # Bidirectional: relay sends challenge string, client sends signed event
        if (defined $args{event}) {
            $self->event($args{event});
        } elsif (defined $args{challenge}) {
            $self->challenge($args{challenge});
        } else {
            croak "AUTH requires either 'event' or 'challenge'";
        }
    } else {
        croak "unknown message type: $type";
    }

    return $self;
}

sub serialize {
    my ($self) = @_;
    my $type = $self->type;

    if ($type eq 'EVENT') {
        if (defined $self->subscription_id) {
            return $JSON->encode(['EVENT', $self->subscription_id, $self->event->to_hash]);
        }
        return $JSON->encode(['EVENT', $self->event->to_hash]);
    } elsif ($type eq 'REQ') {
        return $JSON->encode(['REQ', $self->subscription_id, map { $_->to_hash } @{$self->filters}]);
    } elsif ($type eq 'CLOSE') {
        return $JSON->encode(['CLOSE', $self->subscription_id]);
    } elsif ($type eq 'OK') {
        return $JSON->encode(['OK', $self->event_id, $self->accepted ? JSON::true : JSON::false, $self->message]);
    } elsif ($type eq 'EOSE') {
        return $JSON->encode(['EOSE', $self->subscription_id]);
    } elsif ($type eq 'NOTICE') {
        return $JSON->encode(['NOTICE', $self->message]);
    } elsif ($type eq 'CLOSED') {
        return $JSON->encode(['CLOSED', $self->subscription_id, $self->message]);
    } elsif ($type eq 'AUTH') {
        if ($self->event) {
            return $JSON->encode(['AUTH', $self->event->to_hash]);
        } else {
            return $JSON->encode(['AUTH', $self->challenge]);
        }
    }
}

my %PARSERS = (
    EVENT => sub {
        my ($arr) = @_;
        # client-to-relay: ["EVENT", {event}]
        if (@$arr == 2 && ref($arr->[1]) eq 'HASH') {
            my $event_hash = $arr->[1];
            return (
                event => Net::Nostr::Event->new(%$event_hash, id => $event_hash->{id}),
            );
        }
        # relay-to-client: ["EVENT", sub_id, {event}]
        croak "EVENT message requires 2 or 3 elements\n" unless @$arr == 3;
        my $event_hash = $arr->[2];
        return (
            subscription_id => $arr->[1],
            event           => Net::Nostr::Event->new(%$event_hash, id => $event_hash->{id}),
        );
    },
    OK => sub {
        my ($arr) = @_;
        croak "OK message requires 4 elements\n" unless @$arr == 4;
        return (
            event_id => $arr->[1],
            accepted => $arr->[2] ? 1 : 0,
            message  => $arr->[3],
        );
    },
    EOSE => sub {
        my ($arr) = @_;
        croak "EOSE message requires 2 elements\n" unless @$arr == 2;
        return (
            subscription_id => $arr->[1],
        );
    },
    CLOSED => sub {
        my ($arr) = @_;
        croak "CLOSED message requires 3 elements\n" unless @$arr == 3;
        return (
            subscription_id => $arr->[1],
            message         => $arr->[2],
        );
    },
    NOTICE => sub {
        my ($arr) = @_;
        croak "NOTICE message requires 2 elements\n" unless @$arr == 2;
        return (
            message => $arr->[1],
        );
    },
    REQ => sub {
        my ($arr) = @_;
        croak "REQ message requires at least 3 elements\n" unless @$arr >= 3;
        my @filters;
        for my $i (2 .. $#$arr) {
            push @filters, Net::Nostr::Filter->new(%{$arr->[$i]});
        }
        return (
            subscription_id => $arr->[1],
            filters         => \@filters,
        );
    },
    CLOSE => sub {
        my ($arr) = @_;
        croak "CLOSE message requires 2 elements\n" unless @$arr == 2;
        return (
            subscription_id => $arr->[1],
        );
    },
    AUTH => sub {
        my ($arr) = @_;
        croak "AUTH message requires 2 elements\n" unless @$arr == 2;
        # If second element is a hash, it's a signed event from client
        if (ref($arr->[1]) eq 'HASH') {
            my $event_hash = $arr->[1];
            return (
                event => Net::Nostr::Event->new(%$event_hash, id => $event_hash->{id}),
            );
        }
        # Otherwise it's a challenge string from relay
        return (
            challenge => $arr->[1],
        );
    },
);

sub parse {
    my ($class, $raw) = @_;
    my $arr = eval { $JSON->decode($raw) };
    croak "invalid JSON: $@\n" if $@;
    croak "message must be a JSON array\n" unless ref($arr) eq 'ARRAY';
    croak "message array must not be empty\n" unless @$arr;

    my $type = $arr->[0];
    croak "unknown message type: $type\n" unless $PARSERS{$type};

    my %fields = $PARSERS{$type}->($arr);
    return $class->new(type => $type, %fields);
}

1;

__END__

=head1 NAME

Net::Nostr::Message - Nostr protocol message serialization and parsing

=head1 SYNOPSIS

    use Net::Nostr::Message;

    # Client-to-relay: publish an event
    my $msg = Net::Nostr::Message->new(type => 'EVENT', event => $event);
    my $json = $msg->serialize;  # '["EVENT",{...}]'

    # Client-to-relay: subscribe
    my $msg = Net::Nostr::Message->new(
        type            => 'REQ',
        subscription_id => 'feed',
        filters         => [$filter1, $filter2],
    );

    # Client-to-relay: close subscription
    my $msg = Net::Nostr::Message->new(
        type            => 'CLOSE',
        subscription_id => 'feed',
    );

    # Parse a relay EVENT message
    my $msg = Net::Nostr::Message->parse($json_string);
    say $msg->type;             # 'EVENT'
    say $msg->subscription_id;  # 'feed'
    say $msg->event->content;   # event content

    # Client-to-relay: NIP-42 authentication
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $auth_event);

    # Relay-to-client: AUTH challenge
    my $msg = Net::Nostr::Message->parse('["AUTH","challenge-string"]');
    say $msg->challenge;  # 'challenge-string'

=head1 DESCRIPTION

Handles all NIP-01 message types for both client-to-relay and relay-to-client
communication. Messages are constructed with C<new>, serialized with
C<serialize>, and parsed from JSON with C<parse>.

=head1 CONSTRUCTOR

=head2 new

    my $msg = Net::Nostr::Message->new(type => $type, ...);

Creates a new message. C<type> is required and must be one of: C<EVENT>,
C<REQ>, C<CLOSE>, C<OK>, C<EOSE>, C<NOTICE>, C<CLOSED>, C<AUTH>.

Required fields by type:

    EVENT  - event (Net::Nostr::Event), optional subscription_id
    REQ    - subscription_id, filters (arrayref of Net::Nostr::Filter)
    CLOSE  - subscription_id
    OK     - event_id, accepted (bool), message (string)
    EOSE   - subscription_id
    NOTICE - message
    CLOSED - subscription_id, message
    AUTH   - challenge (relay-to-client) or event (client-to-relay)

C<subscription_id> must be a non-empty string of at most 64 characters
for REQ and CLOSE messages. Croaks on missing required fields, invalid
subscription IDs, or unknown type.

=head1 METHODS

=head2 serialize

    my $json = $msg->serialize;

Returns the JSON-encoded message string per the NIP-01 wire format.

    my $msg = Net::Nostr::Message->new(type => 'CLOSE', subscription_id => 'x');
    say $msg->serialize;  # '["CLOSE","x"]'

=head2 parse

    my $msg = Net::Nostr::Message->parse($json_string);

Class method. Parses a JSON message string and returns a new
Net::Nostr::Message object. Croaks on invalid JSON, unknown message
types, or malformed messages.

    my $msg = Net::Nostr::Message->parse('["NOTICE","hello"]');
    say $msg->type;     # 'NOTICE'
    say $msg->message;  # 'hello'

=head2 type

    my $type = $msg->type;  # 'EVENT', 'OK', 'REQ', etc.

=head2 subscription_id

    my $sub_id = $msg->subscription_id;

The subscription ID. Present on EVENT (relay-to-client), REQ, CLOSE,
EOSE, and CLOSED messages.

=head2 event

    my $event = $msg->event;  # Net::Nostr::Event

The event object. Present on EVENT and AUTH (client-to-relay) messages.

=head2 event_id

    my $id = $msg->event_id;

The event ID string. Present on OK messages.

=head2 accepted

    my $bool = $msg->accepted;  # 1 or 0

Whether the event was accepted. Present on OK messages.

=head2 message

    my $text = $msg->message;

The message string. Present on OK, NOTICE, and CLOSED messages.
For OK and CLOSED, may include a machine-readable prefix like
C<"duplicate: already have this event">.

=head2 prefix

    my $prefix = $msg->prefix;  # 'duplicate', 'blocked', etc. or undef

The machine-readable prefix extracted from the message string.
Standard prefixes: C<duplicate>, C<pow>, C<blocked>, C<rate-limited>,
C<invalid>, C<restricted>, C<auth-required>, C<mute>, C<error>.

    my $msg = Net::Nostr::Message->parse(
        '["OK","aa...",false,"blocked: you are banned"]'
    );
    say $msg->prefix;  # 'blocked'

=head2 filters

    my $filters = $msg->filters;  # arrayref of Net::Nostr::Filter

The filter objects. Present on REQ messages.

=head2 challenge

    my $challenge = $msg->challenge;

The challenge string. Present on AUTH messages from relays.

    my $msg = Net::Nostr::Message->parse('["AUTH","challenge123"]');
    say $msg->challenge;  # 'challenge123'

=head1 SEE ALSO

L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Filter>

=cut
