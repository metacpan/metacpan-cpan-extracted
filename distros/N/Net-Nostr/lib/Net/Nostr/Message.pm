package Net::Nostr::Message;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Scalar::Util qw(blessed);
use Net::Nostr::Event;
use Net::Nostr::Filter;
use Class::Tiny qw(type subscription_id event event_id accepted message prefix filters challenge count approximate neg_msg filter neg_limit);

my $JSON = JSON->new->utf8;

sub _validate_subscription_id {
    my ($sub_id) = @_;
    croak "subscription_id must be a non-empty string"
        unless defined $sub_id && !ref($sub_id) && length($sub_id) > 0;
    croak "subscription_id must be at most 64 characters"
        unless length($sub_id) <= 64;
}

sub _validate_non_negative_int {
    my ($value, $name) = @_;
    croak "$name must be a non-negative integer"
        unless defined $value && !ref($value) && $value =~ /\A[0-9]+\z/;
}

sub _validate_filters {
    my ($filters) = @_;
    for my $f (@$filters) {
        croak "each filter must be a Net::Nostr::Filter object"
            unless blessed($f) && $f->isa('Net::Nostr::Filter');
    }
}

sub _extract_prefix {
    my ($message) = @_;
    return undef unless defined $message && $message =~ /^([a-z-]+): /;
    return $1;
}

sub new {
    my $class = shift;
    my %args = @_;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    my $self = bless {}, $class;

    croak "type is required" unless defined $args{type};
    $self->type($args{type});

    my $type = $args{type};

    if ($type eq 'EVENT') {
        croak "event is required for EVENT message" unless $args{event};
        croak "event must be a Net::Nostr::Event object"
            unless blessed($args{event}) && $args{event}->isa('Net::Nostr::Event');
        $self->event($args{event});
        $self->subscription_id($args{subscription_id}) if defined $args{subscription_id};
    } elsif ($type eq 'REQ') {
        _validate_subscription_id($args{subscription_id});
        $self->subscription_id($args{subscription_id});
        croak "req requires at least one filter"
            unless $args{filters} && @{$args{filters}};
        _validate_filters($args{filters});
        $self->filters($args{filters});
    } elsif ($type eq 'CLOSE') {
        _validate_subscription_id($args{subscription_id});
        $self->subscription_id($args{subscription_id});
    } elsif ($type eq 'OK') {
        croak "event_id is required for OK message"
            unless defined $args{event_id};
        croak "event_id must be 64-char lowercase hex"
            unless $args{event_id} =~ /\A[0-9a-f]{64}\z/;
        $self->event_id($args{event_id});
        $self->accepted($args{accepted} ? 1 : 0);
        my $msg = $args{message} // '';
        croak "message must be a string" if ref($msg);
        $self->message($msg);
        $self->prefix(_extract_prefix($self->message));
    } elsif ($type eq 'EOSE') {
        croak "subscription_id is required for EOSE"
            unless defined $args{subscription_id};
        $self->subscription_id($args{subscription_id});
    } elsif ($type eq 'NOTICE') {
        croak "message is required for NOTICE" unless defined $args{message};
        croak "message must be a string" if ref($args{message});
        $self->message($args{message});
    } elsif ($type eq 'CLOSED') {
        croak "subscription_id is required for CLOSED"
            unless defined $args{subscription_id};
        croak "message is required for CLOSED"
            unless defined $args{message};
        croak "message must be a string" if ref($args{message});
        $self->subscription_id($args{subscription_id});
        $self->message($args{message});
        $self->prefix(_extract_prefix($self->message));
    } elsif ($type eq 'COUNT') {
        # Bidirectional: client sends filters, relay sends count
        _validate_subscription_id($args{subscription_id});
        $self->subscription_id($args{subscription_id});
        croak "COUNT count and filters are mutually exclusive"
            if defined $args{count} && $args{filters};
        if (defined $args{count}) {
            _validate_non_negative_int($args{count}, 'count');
            $self->count(0 + $args{count});
            $self->approximate($args{approximate} ? 1 : 0) if $args{approximate};
        } else {
            croak "COUNT requires at least one filter"
                unless $args{filters} && @{$args{filters}};
            _validate_filters($args{filters});
            $self->filters($args{filters});
        }
    } elsif ($type eq 'AUTH') {
        # Bidirectional: relay sends challenge string, client sends signed event
        croak "AUTH event and challenge are mutually exclusive"
            if defined $args{event} && defined $args{challenge};
        if (defined $args{event}) {
            croak "event must be a Net::Nostr::Event object"
                unless blessed($args{event}) && $args{event}->isa('Net::Nostr::Event');
            $self->event($args{event});
        } elsif (defined $args{challenge}) {
            croak "challenge must be a string" if ref($args{challenge});
            $self->challenge($args{challenge});
        } else {
            croak "AUTH requires either 'event' or 'challenge'";
        }
    } elsif ($type eq 'NEG-OPEN') {
        _validate_subscription_id($args{subscription_id});
        $self->subscription_id($args{subscription_id});
        croak "filter is required for NEG-OPEN"
            unless $args{filter};
        croak "filter must be a Net::Nostr::Filter object"
            unless blessed($args{filter}) && $args{filter}->isa('Net::Nostr::Filter');
        $self->filter($args{filter});
        croak "neg_msg is required for NEG-OPEN"
            unless defined $args{neg_msg};
        croak "neg_msg must be a hex string"
            unless $args{neg_msg} =~ /\A[0-9a-f]+\z/;
        $self->neg_msg($args{neg_msg});
    } elsif ($type eq 'NEG-MSG') {
        _validate_subscription_id($args{subscription_id});
        $self->subscription_id($args{subscription_id});
        croak "neg_msg is required for NEG-MSG"
            unless defined $args{neg_msg};
        croak "neg_msg must be a hex string"
            unless $args{neg_msg} =~ /\A[0-9a-f]+\z/;
        $self->neg_msg($args{neg_msg});
    } elsif ($type eq 'NEG-CLOSE') {
        _validate_subscription_id($args{subscription_id});
        $self->subscription_id($args{subscription_id});
    } elsif ($type eq 'NEG-ERR') {
        croak "subscription_id is required for NEG-ERR"
            unless defined $args{subscription_id};
        croak "message is required for NEG-ERR"
            unless defined $args{message};
        croak "message must be a string" if ref($args{message});
        $self->subscription_id($args{subscription_id});
        $self->message($args{message});
        $self->prefix(_extract_prefix($self->message));
        if (defined $args{neg_limit}) {
            _validate_non_negative_int($args{neg_limit}, 'neg_limit');
            $self->neg_limit(0 + $args{neg_limit});
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
    } elsif ($type eq 'COUNT') {
        if (defined $self->count) {
            my %result = (count => $self->count);
            $result{approximate} = JSON::true if $self->approximate;
            return $JSON->encode(['COUNT', $self->subscription_id, \%result]);
        }
        return $JSON->encode(['COUNT', $self->subscription_id, map { $_->to_hash } @{$self->filters}]);
    } elsif ($type eq 'AUTH') {
        if ($self->event) {
            return $JSON->encode(['AUTH', $self->event->to_hash]);
        } else {
            return $JSON->encode(['AUTH', $self->challenge]);
        }
    } elsif ($type eq 'NEG-OPEN') {
        return $JSON->encode(['NEG-OPEN', $self->subscription_id, $self->filter->to_hash, $self->neg_msg]);
    } elsif ($type eq 'NEG-MSG') {
        return $JSON->encode(['NEG-MSG', $self->subscription_id, $self->neg_msg]);
    } elsif ($type eq 'NEG-CLOSE') {
        return $JSON->encode(['NEG-CLOSE', $self->subscription_id]);
    } elsif ($type eq 'NEG-ERR') {
        my @arr = ('NEG-ERR', $self->subscription_id, $self->message);
        push @arr, $self->neg_limit if defined $self->neg_limit;
        return $JSON->encode(\@arr);
    }
}

my %PARSERS = (
    EVENT => sub {
        my ($arr) = @_;
        # client-to-relay: ["EVENT", {event}]
        if (@$arr == 2) {
            croak "EVENT event element must be a JSON object\n"
                unless ref($arr->[1]) eq 'HASH';
            return (
                event => Net::Nostr::Event->from_wire($arr->[1]),
            );
        }
        # relay-to-client: ["EVENT", sub_id, {event}]
        croak "EVENT message requires 2 or 3 elements\n" unless @$arr == 3;
        croak "EVENT subscription_id must be a string\n"
            if ref($arr->[1]);
        croak "EVENT event element must be a JSON object\n"
            unless ref($arr->[2]) eq 'HASH';
        return (
            subscription_id => $arr->[1],
            event           => Net::Nostr::Event->from_wire($arr->[2]),
        );
    },
    OK => sub {
        my ($arr) = @_;
        croak "OK message requires 4 elements\n" unless @$arr == 4;
        croak "OK event_id must be 64-char lowercase hex\n"
            unless defined $arr->[1] && $arr->[1] =~ /\A[0-9a-f]{64}\z/;
        croak "OK message must be a string\n"
            if ref($arr->[3]);
        return (
            event_id => $arr->[1],
            accepted => $arr->[2] ? 1 : 0,
            message  => $arr->[3],
        );
    },
    EOSE => sub {
        my ($arr) = @_;
        croak "EOSE message requires 2 elements\n" unless @$arr == 2;
        croak "EOSE subscription_id must be a string\n"
            if ref($arr->[1]);
        return (
            subscription_id => $arr->[1],
        );
    },
    CLOSED => sub {
        my ($arr) = @_;
        croak "CLOSED message requires 3 elements\n" unless @$arr == 3;
        croak "CLOSED subscription_id must be a string\n"
            if ref($arr->[1]);
        croak "CLOSED message must be a string\n"
            if ref($arr->[2]);
        return (
            subscription_id => $arr->[1],
            message         => $arr->[2],
        );
    },
    NOTICE => sub {
        my ($arr) = @_;
        croak "NOTICE message requires 2 elements\n" unless @$arr == 2;
        croak "NOTICE message must be a string\n"
            if ref($arr->[1]);
        return (
            message => $arr->[1],
        );
    },
    REQ => sub {
        my ($arr) = @_;
        croak "REQ message requires at least 3 elements\n" unless @$arr >= 3;
        my @filters;
        for my $i (2 .. $#$arr) {
            croak "REQ filter element must be a JSON object\n"
                unless ref($arr->[$i]) eq 'HASH';
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
    COUNT => sub {
        my ($arr) = @_;
        croak "COUNT message requires at least 3 elements\n" unless @$arr >= 3;
        # Relay-to-client: ["COUNT", sub_id, {"count": N}]
        if (ref($arr->[2]) eq 'HASH' && exists $arr->[2]{count}) {
            _validate_non_negative_int($arr->[2]{count}, 'count');
            return (
                subscription_id => $arr->[1],
                count           => $arr->[2]{count},
                ($arr->[2]{approximate} ? (approximate => 1) : ()),
            );
        }
        # Client-to-relay: ["COUNT", sub_id, {filter}...]
        my @filters;
        for my $i (2 .. $#$arr) {
            croak "COUNT filter element must be a JSON object\n"
                unless ref($arr->[$i]) eq 'HASH';
            push @filters, Net::Nostr::Filter->new(%{$arr->[$i]});
        }
        return (
            subscription_id => $arr->[1],
            filters         => \@filters,
        );
    },
    AUTH => sub {
        my ($arr) = @_;
        croak "AUTH message requires 2 elements\n" unless @$arr == 2;
        # If second element is a hash, it's a signed event from client
        if (ref($arr->[1]) eq 'HASH') {
            return (
                event => Net::Nostr::Event->from_wire($arr->[1]),
            );
        }
        # Otherwise it's a challenge string from relay
        croak "AUTH challenge must be a string\n"
            if ref($arr->[1]);
        return (
            challenge => $arr->[1],
        );
    },
    'NEG-OPEN' => sub {
        my ($arr) = @_;
        croak "NEG-OPEN message requires 4 elements\n" unless @$arr == 4;
        croak "NEG-OPEN subscription_id must be a string\n"
            if ref($arr->[1]);
        croak "NEG-OPEN filter must be a JSON object\n"
            unless ref($arr->[2]) eq 'HASH';
        croak "NEG-OPEN neg_msg must be a hex string\n"
            unless defined $arr->[3] && !ref($arr->[3]) && $arr->[3] =~ /\A[0-9a-f]+\z/;
        return (
            subscription_id => $arr->[1],
            filter          => Net::Nostr::Filter->new(%{$arr->[2]}),
            neg_msg         => $arr->[3],
        );
    },
    'NEG-MSG' => sub {
        my ($arr) = @_;
        croak "NEG-MSG message requires 3 elements\n" unless @$arr == 3;
        croak "NEG-MSG subscription_id must be a string\n"
            if ref($arr->[1]);
        croak "NEG-MSG neg_msg must be a hex string\n"
            unless defined $arr->[2] && !ref($arr->[2]) && $arr->[2] =~ /\A[0-9a-f]+\z/;
        return (
            subscription_id => $arr->[1],
            neg_msg         => $arr->[2],
        );
    },
    'NEG-CLOSE' => sub {
        my ($arr) = @_;
        croak "NEG-CLOSE message requires 2 elements\n" unless @$arr == 2;
        croak "NEG-CLOSE subscription_id must be a string\n"
            if ref($arr->[1]);
        return (
            subscription_id => $arr->[1],
        );
    },
    'NEG-ERR' => sub {
        my ($arr) = @_;
        croak "NEG-ERR message requires 3 or 4 elements\n" unless @$arr == 3 || @$arr == 4;
        croak "NEG-ERR subscription_id must be a string\n"
            if ref($arr->[1]);
        croak "NEG-ERR message must be a string\n"
            if ref($arr->[2]);
        if (@$arr == 4) {
            _validate_non_negative_int($arr->[3], 'neg_limit');
        }
        return (
            subscription_id => $arr->[1],
            message         => $arr->[2],
            (@$arr == 4 ? (neg_limit => $arr->[3]) : ()),
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
C<REQ>, C<CLOSE>, C<OK>, C<EOSE>, C<NOTICE>, C<CLOSED>, C<COUNT>, C<AUTH>,
C<NEG-OPEN>, C<NEG-MSG>, C<NEG-CLOSE>, C<NEG-ERR>.

Required fields by type:

    EVENT  - event (Net::Nostr::Event object), optional subscription_id
    REQ    - subscription_id, filters (arrayref of Net::Nostr::Filter)
    CLOSE  - subscription_id
    OK     - event_id (64-char lowercase hex), accepted (bool), optional message (defaults to '')
    EOSE   - subscription_id
    NOTICE - message (string)
    CLOSED - subscription_id, message (string)
    COUNT     - subscription_id, filters (client-to-relay) or count (non-negative integer, relay-to-client); mutually exclusive
    AUTH       - challenge (string) or event (Net::Nostr::Event object); mutually exclusive
    NEG-OPEN  - subscription_id, filter (Net::Nostr::Filter), neg_msg (hex string)
    NEG-MSG   - subscription_id, neg_msg (hex string)
    NEG-CLOSE - subscription_id
    NEG-ERR   - subscription_id, message (string), optional neg_limit (non-negative integer)

C<subscription_id> must be a non-empty string of at most 64 characters
for REQ, CLOSE, and COUNT messages. For EOSE and CLOSED, subscription_id
must be defined but is not length-validated (relay-to-client messages echo
back whatever the client sent). C<event_id> must be 64-character
lowercase hex. C<event> must be a L<Net::Nostr::Event> object.
C<filters> must be an arrayref of L<Net::Nostr::Filter> objects.
C<message> and C<challenge> must be non-reference scalars.

For C<AUTH>, passing both C<event> and C<challenge> is rejected. For
C<COUNT>, passing both C<count> and C<filters> is rejected. Croaks on
missing required fields, invalid field formats, mutually exclusive
arguments, type mismatches, unknown type, or unknown arguments.

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
types, or malformed messages. Validates structural format of each
message type (element count, field types). String fields
(subscription_id, message, challenge) are rejected if they are JSON
objects or arrays. C<event_id> in OK messages must be 64-character
lowercase hex. For EVENT and AUTH messages, the contained event is
constructed via C<< Net::Nostr::Event->from_wire >> which requires all
seven NIP-01 fields (id, pubkey, created_at, kind, tags, content, sig)
and rejects missing or undefined fields.

B<Trust boundary>: C<parse> validates message structure and field formats
but does B<not> verify event signatures, event ID hashes, or
authenticity. The caller is responsible for verifying event integrity
via C<< $event->validate >>, which recomputes the ID hash and verifies
the signature against the event's own pubkey.

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

=head2 count

    my $count = $msg->count;  # non-negative integer

The event count. Present on COUNT response messages (NIP-45). Must be
a non-negative integer; croaks on references, non-numeric strings,
negative values, or floats.

    my $msg = Net::Nostr::Message->parse('["COUNT","q1",{"count":42}]');
    say $msg->count;  # 42

=head2 approximate

    my $approx = $msg->approximate;  # 1 or undef

Whether the count is probabilistic. Present on COUNT response messages
when the relay uses approximate counting.

=head2 filters

    my $filters = $msg->filters;  # arrayref of Net::Nostr::Filter

The filter objects. Present on REQ and COUNT (client-to-relay) messages.

=head2 challenge

    my $challenge = $msg->challenge;

The challenge string. Present on AUTH messages from relays.

    my $msg = Net::Nostr::Message->parse('["AUTH","challenge123"]');
    say $msg->challenge;  # 'challenge123'

=head2 neg_msg

    my $hex = $msg->neg_msg;

The negentropy protocol message as a hex string. Present on NEG-OPEN
and NEG-MSG messages.

=head2 filter

    my $filter = $msg->filter;  # Net::Nostr::Filter

A single NIP-01 filter. Present on NEG-OPEN messages.

=head2 neg_limit

    my $limit = $msg->neg_limit;  # non-negative integer or undef

Optional maximum number of records the relay will process. Present on
NEG-ERR messages when the relay rejects a query as too large. Must be
a non-negative integer; croaks on references, non-numeric strings,
negative values, or floats.

    my $msg = Net::Nostr::Message->parse('["NEG-ERR","x","blocked: too big",100000]');
    say $msg->neg_limit;  # 100000

=head1 SEE ALSO

L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md>,
L<NIP-42|https://github.com/nostr-protocol/nips/blob/master/42.md>,
L<NIP-45|https://github.com/nostr-protocol/nips/blob/master/45.md>,
L<NIP-77|https://github.com/nostr-protocol/nips/blob/master/77.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Filter>

=cut
