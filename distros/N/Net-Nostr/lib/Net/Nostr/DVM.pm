package Net::Nostr::DVM;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;

use constant SP_DISCOVERY_KIND => 31990;

use Class::Tiny qw(
    inputs
    output
    params
    bid
    relays
    providers
    hashtags
    encrypted
    request_id
    request_event
    relay_hint
    customer
    amount
    bolt11
    status
    extra_info
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{inputs}    //= [];
    $args{params}    //= [];
    $args{relays}    //= [];
    $args{providers} //= [];
    $args{hashtags}  //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub is_job_request {
    my ($class, $kind) = @_;
    return $kind >= 5000 && $kind <= 5999;
}

sub is_job_result {
    my ($class, $kind) = @_;
    return $kind >= 6000 && $kind <= 6999;
}

sub is_job_feedback {
    my ($class, $kind) = @_;
    return $kind == 7000;
}

sub result_kind {
    my ($class, $request_kind) = @_;
    return $request_kind + 1000;
}

sub request_kind {
    my ($class, $result_kind) = @_;
    return $result_kind - 1000;
}

sub job_request {
    my ($class, %args) = @_;

    my $kind = delete $args{kind}
        // croak "job_request requires 'kind'";
    croak "job_request kind must be in range 5000-5999"
        unless $class->is_job_request($kind);

    my $inputs    = delete $args{inputs}    // [];
    my $output    = delete $args{output};
    my $params    = delete $args{params}    // [];
    my $bid       = delete $args{bid};
    my $relays    = delete $args{relays};
    my $providers = delete $args{providers} // [];
    my $hashtags  = delete $args{hashtags}  // [];
    my $encrypted = delete $args{encrypted};
    my $content   = delete $args{content}   // '';

    my @tags;
    for my $input (@$inputs) {
        push @tags, ['i', @$input];
    }
    push @tags, ['output', $output] if defined $output;
    for my $param (@$params) {
        push @tags, ['param', @$param];
    }
    push @tags, ['bid', $bid]         if defined $bid;
    push @tags, ['relays', @$relays]  if $relays;
    push @tags, ['p', $_] for @$providers;
    push @tags, ['t', $_] for @$hashtags;
    push @tags, ['encrypted'] if $encrypted;

    return Net::Nostr::Event->new(
        %args,
        kind    => $kind,
        content => $content,
        tags    => \@tags,
    );
}

sub job_result {
    my ($class, %args) = @_;

    my $request   = delete $args{request}
        // croak "job_result requires 'request'";
    my $encrypted  = delete $args{encrypted};
    my $relay_hint = delete $args{relay_hint};
    my $amount     = delete $args{amount};
    my $bolt11     = delete $args{bolt11};
    my $content    = delete $args{content} // '';

    my $kind = delete $args{kind} // $class->result_kind($request->kind);
    croak "job_result kind must be in range 6000-6999"
        unless $class->is_job_result($kind);

    my @tags;

    # request tag: stringified JSON
    push @tags, ['request', JSON::encode_json($request->to_hash)];

    # e tag: job request id
    my @e_tag = ('e', $request->id);
    push @e_tag, $relay_hint if defined $relay_hint;
    push @tags, \@e_tag;

    # i tags: original inputs (skip if encrypted)
    unless ($encrypted) {
        for my $tag (@{$request->tags}) {
            push @tags, [@$tag] if $tag->[0] eq 'i';
        }
    }

    # p tag: customer's pubkey
    push @tags, ['p', $request->pubkey];

    # amount tag
    if (defined $amount) {
        my @amt = ('amount', $amount);
        push @amt, $bolt11 if defined $bolt11;
        push @tags, \@amt;
    }

    push @tags, ['encrypted'] if $encrypted;

    return Net::Nostr::Event->new(
        %args,
        kind    => $kind,
        content => $content,
        tags    => \@tags,
    );
}

sub job_feedback {
    my ($class, %args) = @_;

    my $request_id = delete $args{request_id}
        // croak "job_feedback requires 'request_id'";
    my $customer = delete $args{customer}
        // croak "job_feedback requires 'customer'";
    my $status = delete $args{status}
        // croak "job_feedback requires 'status'";

    my $relay_hint = delete $args{relay_hint};
    my $extra_info = delete $args{extra_info};
    my $amount     = delete $args{amount};
    my $bolt11     = delete $args{bolt11};
    my $encrypted  = delete $args{encrypted};
    my $content    = delete $args{content} // '';

    my @tags;

    # status tag
    my @status_tag = ('status', $status);
    push @status_tag, $extra_info if defined $extra_info;
    push @tags, \@status_tag;

    # amount tag
    if (defined $amount) {
        my @amt = ('amount', $amount);
        push @amt, $bolt11 if defined $bolt11;
        push @tags, \@amt;
    }

    # e tag: job request id
    my @e_tag = ('e', $request_id);
    push @e_tag, $relay_hint if defined $relay_hint;
    push @tags, \@e_tag;

    # p tag: customer's pubkey
    push @tags, ['p', $customer];

    # encrypted tag
    push @tags, ['encrypted'] if $encrypted;

    return Net::Nostr::Event->new(
        %args,
        kind    => 7000,
        content => $content,
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($class->is_job_request($kind)) {
        return _parse_request($class, $event);
    } elsif ($class->is_job_result($kind)) {
        return _parse_result($class, $event);
    } elsif ($class->is_job_feedback($kind)) {
        return _parse_feedback($class, $event);
    }

    return undef;
}

sub _parse_request {
    my ($class, $event) = @_;

    my (@inputs, @params, @relays, @providers, @hashtags);
    my ($output, $bid, $encrypted);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if    ($t eq 'i')      { push @inputs, [@{$tag}[1 .. $#$tag]] }
        elsif ($t eq 'output') { $output = $tag->[1] }
        elsif ($t eq 'param')  { push @params, [@{$tag}[1 .. $#$tag]] }
        elsif ($t eq 'bid')    { $bid = $tag->[1] }
        elsif ($t eq 'relays') { @relays = @{$tag}[1 .. $#$tag] }
        elsif ($t eq 'p')      { push @providers, $tag->[1] }
        elsif ($t eq 't')      { push @hashtags, $tag->[1] }
        elsif ($t eq 'encrypted') { $encrypted = 1 }
    }

    return $class->new(
        inputs    => \@inputs,
        output    => $output,
        params    => \@params,
        bid       => $bid,
        relays    => \@relays,
        providers => \@providers,
        hashtags  => \@hashtags,
        encrypted => $encrypted,
    );
}

sub _parse_result {
    my ($class, $event) = @_;

    my ($request_id, $relay_hint, $customer, $amount, $bolt11, $encrypted);
    my ($request_event, @inputs);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if ($t eq 'e') {
            $request_id = $tag->[1];
            $relay_hint = $tag->[2] if defined $tag->[2];
        }
        elsif ($t eq 'p')       { $customer = $tag->[1] }
        elsif ($t eq 'request') {
            eval { $request_event = $tag->[1] };
        }
        elsif ($t eq 'amount') {
            $amount = $tag->[1];
            $bolt11 = $tag->[2] if defined $tag->[2];
        }
        elsif ($t eq 'i')         { push @inputs, [@{$tag}[1 .. $#$tag]] }
        elsif ($t eq 'encrypted') { $encrypted = 1 }
    }

    return $class->new(
        request_id    => $request_id,
        request_event => $request_event,
        relay_hint    => $relay_hint,
        customer      => $customer,
        amount        => $amount,
        bolt11        => $bolt11,
        inputs        => \@inputs,
        encrypted     => $encrypted,
    );
}

sub _parse_feedback {
    my ($class, $event) = @_;

    my ($request_id, $relay_hint, $customer, $status, $extra_info);
    my ($amount, $bolt11, $encrypted);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if ($t eq 'status') {
            $status     = $tag->[1];
            $extra_info = $tag->[2] if defined $tag->[2];
        }
        elsif ($t eq 'e') {
            $request_id = $tag->[1];
            $relay_hint = $tag->[2] if defined $tag->[2];
        }
        elsif ($t eq 'p')         { $customer = $tag->[1] }
        elsif ($t eq 'encrypted') { $encrypted = 1 }
        elsif ($t eq 'amount') {
            $amount = $tag->[1];
            $bolt11 = $tag->[2] if defined $tag->[2];
        }
    }

    return $class->new(
        status     => $status,
        extra_info => $extra_info,
        request_id => $request_id,
        relay_hint => $relay_hint,
        customer   => $customer,
        amount     => $amount,
        bolt11     => $bolt11,
        encrypted  => $encrypted,
    );
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    croak "DVM event MUST be kind 5000-5999, 6000-6999, or 7000"
        unless $class->is_job_request($kind)
            || $class->is_job_result($kind)
            || $class->is_job_feedback($kind);

    my %has;
    for my $tag (@{$event->tags}) {
        $has{$tag->[0]} = 1;
    }

    if ($class->is_job_result($kind)) {
        croak "job result MUST have an 'e' tag"       unless $has{e};
        croak "job result MUST have a 'p' tag"        unless $has{p};
        croak "job result MUST have a 'request' tag"  unless $has{request};
    }

    if ($class->is_job_feedback($kind)) {
        croak "job feedback MUST have a 'status' tag" unless $has{status};
        croak "job feedback MUST have an 'e' tag"     unless $has{e};
        croak "job feedback MUST have a 'p' tag"      unless $has{p};
    }

    return 1;
}

1;

__END__


=head1 NAME

Net::Nostr::DVM - NIP-90 Data Vending Machine

=head1 SYNOPSIS

    use Net::Nostr::DVM;

    # Job request (kind 5000-5999)
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $hex_pubkey,
        kind   => 5001,
        inputs => [['https://example.com/audio.mp3', 'url']],
        output => 'text/plain',
    );

    # Job result (kind 6000-6999)
    my $result = Net::Nostr::DVM->job_result(
        pubkey  => $hex_pubkey,
        request => $event,
        content => 'Transcribed text here.',
        amount  => '5000',
    );

    # Job feedback (kind 7000)
    my $feedback = Net::Nostr::DVM->job_feedback(
        pubkey     => $hex_pubkey,
        request_id => $job_request_id,
        customer   => $customer_pubkey,
        status     => 'processing',
    );

    # Parse any DVM event
    my $parsed = Net::Nostr::DVM->from_event($event);

    # Validate
    Net::Nostr::DVM->validate($event);

    # Kind helpers
    Net::Nostr::DVM->is_job_request(5001);   # true
    Net::Nostr::DVM->is_job_result(6001);    # true
    Net::Nostr::DVM->is_job_feedback(7000);  # true
    Net::Nostr::DVM->result_kind(5001);      # 6001
    Net::Nostr::DVM->request_kind(6001);     # 5001

=head1 DESCRIPTION

Implements NIP-90 (Data Vending Machine). Nostr acts as a marketplace
for data processing where customers request jobs and service providers
compete to fulfill them. Three event kind ranges are used:

=over 4

=item * B<Job Request> (kind 5000-5999) - Published by a customer
to request data processing. Contains input data, expected output
format, optional parameters, a bid amount, and preferred relays
and service providers. All tags are optional.

=item * B<Job Result> (kind 6000-6999) - Published by a service
provider with the output of processed data. The kind is always
1000 higher than the corresponding request kind. References the
original request event and includes the customer's pubkey.

=item * B<Job Feedback> (kind 7000) - Published by a service
provider to communicate status updates. Status values include
C<payment-required>, C<processing>, C<error>, C<success>, and
C<partial>. MAY include partial results in content.

=back

Job requests support encrypted parameters via the C<encrypted> tag.
When encrypted, input and param tags are encrypted with the service
provider's key using NIP-04 and placed in the content field.

=head1 CONSTANTS

=head2 SP_DISCOVERY_KIND

    my $kind = Net::Nostr::DVM::SP_DISCOVERY_KIND;  # 31990

NIP-89 kind for service provider discoverability announcements.

=head1 CONSTRUCTOR

=head2 new

    my $dvm = Net::Nostr::DVM->new(
        status => 'processing',
    );

Creates a new C<Net::Nostr::DVM> object. Croaks on unknown arguments.
Array fields (C<inputs>, C<params>, C<relays>, C<providers>,
C<hashtags>) default to C<[]>.

=head1 CLASS METHODS

=head2 job_request

    my $event = Net::Nostr::DVM->job_request(
        pubkey    => $hex_pubkey,                      # required
        kind      => 5001,                             # required (5000-5999)
        inputs    => [[$data, $type, $relay, $marker], ...], # optional (i tags)
        output    => $mime_type,                        # optional
        params    => [[$key, $value], ...],             # optional (param tags)
        bid       => $millisats,                       # optional
        relays    => [$url, ...],                      # optional
        providers => [$pubkey, ...],                   # optional (p tags)
        hashtags  => [$tag, ...],                      # optional (t tags)
        encrypted => 1,                                # optional
        content   => $encrypted_payload,               # optional, defaults to ''
    );

Creates a job request L<Net::Nostr::Event>. The C<kind> must be in the
5000-5999 range. Input types are C<url>, C<event>, C<job>, or C<text>.
When C<encrypted> is set, an C<encrypted> tag is added and content
should contain the NIP-04 encrypted parameters.

=head2 job_result

    my $event = Net::Nostr::DVM->job_result(
        pubkey     => $hex_pubkey,      # required
        request    => $request_event,   # required (Net::Nostr::Event)
        content    => $payload,         # optional, defaults to ''
        relay_hint => $relay_url,       # optional
        amount     => $millisats,       # optional
        bolt11     => $invoice,         # optional
        encrypted  => 1,               # optional
    );

Creates a job result L<Net::Nostr::Event>. The kind is automatically
set to the request kind + 1000. The C<request> tag contains the
stringified JSON of the original request. When C<encrypted> is set,
input tags from the request are omitted to avoid leaking clear text.

=head2 job_feedback

    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $hex_pubkey,      # required
        request_id => $event_id,        # required (e tag)
        customer   => $customer_pubkey, # required (p tag)
        status     => $status,          # required
        extra_info => $description,     # optional
        relay_hint => $relay_url,       # optional
        amount     => $millisats,       # optional
        bolt11     => $invoice,         # optional
        content    => $partial_result,  # optional, defaults to ''
        encrypted  => 1,               # optional, adds 'encrypted' tag
    );

Creates a kind 7000 job feedback L<Net::Nostr::Event>. Valid status
values: C<payment-required>, C<processing>, C<error>, C<success>,
C<partial>.

=head2 from_event

    my $dvm = Net::Nostr::DVM->from_event($event);

Parses a DVM event (kind 5000-5999, 6000-6999, or 7000) into a
C<Net::Nostr::DVM> object. Returns C<undef> for unrecognized kinds.

=head2 validate

    Net::Nostr::DVM->validate($event);

Validates a NIP-90 event. Croaks if:

=over

=item * Kind is not in 5000-5999, 6000-6999, or 7000

=item * Job result missing C<e>, C<p>, or C<request> tag

=item * Job feedback missing C<status>, C<e>, or C<p> tag

=back

Returns 1 on success.

=head2 is_job_request

    Net::Nostr::DVM->is_job_request(5001);  # true

Returns true if the kind is in the 5000-5999 range.

=head2 is_job_result

    Net::Nostr::DVM->is_job_result(6001);  # true

Returns true if the kind is in the 6000-6999 range.

=head2 is_job_feedback

    Net::Nostr::DVM->is_job_feedback(7000);  # true

Returns true if the kind is 7000.

=head2 result_kind

    my $rk = Net::Nostr::DVM->result_kind(5001);  # 6001

Returns the result kind for a given request kind (request + 1000).

=head2 request_kind

    my $rk = Net::Nostr::DVM->request_kind(6001);  # 5001

Returns the request kind for a given result kind (result - 1000).

=head1 ACCESSORS

=head2 inputs

Arrayref of arrayrefs from C<i> tags. Each contains
C<[$data, $type, $relay, $marker]>. Defaults to C<[]>.

=head2 output

Expected output MIME type from C<output> tag.

=head2 params

Arrayref of arrayrefs from C<param> tags. Each contains
C<[$key, $value]>. Defaults to C<[]>.

=head2 bid

Maximum payment amount in millisats from C<bid> tag.

=head2 relays

Arrayref of relay URLs from C<relays> tag. Defaults to C<[]>.

=head2 providers

Arrayref of service provider pubkeys from C<p> tags. Defaults to C<[]>.

=head2 hashtags

Arrayref of hashtag strings from C<t> tags. Defaults to C<[]>.

=head2 encrypted

True if the event has an C<encrypted> tag.

=head2 request_id

Job request event ID from C<e> tag (results and feedback).

=head2 request_event

Stringified JSON of the original request from C<request> tag (results).

=head2 relay_hint

Relay hint from C<e> tag.

=head2 customer

Customer pubkey from C<p> tag (results and feedback).

=head2 amount

Payment amount in millisats from C<amount> tag.

=head2 bolt11

Bolt11 invoice from C<amount> tag.

=head2 status

Feedback status from C<status> tag. One of C<payment-required>,
C<processing>, C<error>, C<success>, or C<partial>.

=head2 extra_info

Extra human-readable info from C<status> tag.

=head1 SEE ALSO

L<NIP-90|https://github.com/nostr-protocol/nips/blob/master/90.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
