package Net::Async::MCP;
# ABSTRACT: Async MCP (Model Context Protocol) client for IO::Async

use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future::AsyncAwait;
use Carp qw( croak );
use Scalar::Util qw( blessed looks_like_number weaken );

our $VERSION = '0.004';


# The protocol revisions this client speaks, newest first: the first of them is
# what a client that was not told otherwise sends, and they are the only ones a
# refused request may be renegotiated into.
#
# What belongs in here is decided by the code below and by nothing else: an
# entry means that what this file builds is what that revision defines - today
# a server/discover handshake with no initialize/initialized pair, the
# io.modelcontextprotocol/* keys in _meta, and input_required results answered
# with inputResponses. So adding one means first teaching this client to build
# that revision's request shapes. A revision some dependency happens to know
# about is not one this client can speak, and switching to it on that strength
# would put a new version string on requests that revision never had - trading
# a clear "unsupported protocol version" for a confusing "method not found".
#
# Deliberately not MCP::Constants::SUPPORTED_VERSIONS: that list says what the
# installed server library accepts, which is a different question whose answer
# only happens to be the same one today.
my @SPOKEN_PROTOCOL_VERSIONS = ('2026-07-28');

# What this client sends when the caller named no protocol_version: the newest
# revision it speaks. Deliberately not MCP::Constants::PROTOCOL_VERSION - that
# is the revision the installed server library implements, and following it
# onto a newer one would put that version string on requests this file still
# builds in the old one, for the reason spelled out above.
my $DEFAULT_PROTOCOL_VERSION = $SPOKEN_PROTOCOL_VERSIONS[0];

# The code a server answers a request made in a revision it does not speak
# with. The number the specification gives it, written out rather than read
# from L<MCP::Constants>: it is compared against what a remote server sent, so
# a locally installed library has no say in it, and a client on stdio or HTTP
# has no reason to have L<MCP> installed at all.
my $UNSUPPORTED_PROTOCOL_VERSION = -32022;

# The settings this client keeps to itself, whichever transport it ends up
# with.
my @CLIENT_KEYS = qw( server command url protocol_version client_capabilities
  on_input_request );

# The settings handed on to the transport instead, each with the class a
# transport has to be for it to reach it. Kept apart from @CLIENT_KEYS because
# they are passed on only when the caller actually gave them: the transport's
# own default for stall_timeout has to survive a client that was never asked
# about it.
#
# Which transport takes what is one decision per key rather than one for the
# lot. headers, timeout and stall_timeout describe an HTTP request, and handing
# one to the Stdio transport is not a setting it ignores but an "Unrecognised
# configuration keys" croak; on_notification is an event both wire transports
# have. on_subscription_end has only the HTTP transport to go to, a stream
# being the one thing a subscription can end on. The InProcess transport is no
# L<IO::Async::Notifier>, has no C<configure> and no events at all, so it
# matches nothing here and is handed nothing.
my %TRANSPORT_KEYS = (
  headers               => 'Net::Async::MCP::Transport::HTTP',
  timeout               => 'Net::Async::MCP::Transport::HTTP',
  stall_timeout         => 'Net::Async::MCP::Transport::HTTP',
  on_notification       => 'IO::Async::Notifier',
  on_subscription_end   => 'Net::Async::MCP::Transport::HTTP',
);

# The keys of %TRANSPORT_KEYS that are events of this client rather than
# settings. They travel to the transport wrapped - see _event_handler - and
# are asked for by event rather than by key, because a subclass method of that
# name is a handler just as much as a configured code ref is.
my %EVENT_KEYS = map { $_ => 1 } qw( on_notification on_subscription_end );

sub _init {
  my ( $self, $params ) = @_;
  for my $key (@CLIENT_KEYS, keys %TRANSPORT_KEYS) {
    $self->{$key} = delete $params->{$key} if exists $params->{$key};
  }
  $self->{protocol_version}    //= $DEFAULT_PROTOCOL_VERSION;
  $self->{client_capabilities} //= {};
  $self->SUPER::_init($params);
}

sub configure {
  my ( $self, %params ) = @_;
  my @changed = grep { exists $params{$_} } sort keys %TRANSPORT_KEYS;
  for my $key (@CLIENT_KEYS, keys %TRANSPORT_KEYS) {
    $self->{$key} = delete $params{$key} if exists $params{$key};
  }
  $self->{protocol_version}    //= $DEFAULT_PROTOCOL_VERSION;
  $self->{client_capabilities} //= {};

  # A transport that already exists takes the change too: the transport is
  # built when this client joins a loop, and a bearer token that has to be
  # rotated, or a handler for the notifications of a call about to be made,
  # arrives long after that. Only the keys that transport takes, though - see
  # %TRANSPORT_KEYS for why that is asked per key and not once for the lot.
  if ( my $transport = $self->{transport} ) {
    my @keys = grep { $transport->isa($TRANSPORT_KEYS{$_}) } @changed;
    $transport->configure($self->_transport_params(@keys)) if @keys;
  }

  $self->SUPER::configure(%params);
}

# Private: the named settings as the transport takes them. All of them travel
# as they stand except the events among them, which the transport would
# otherwise invoke with itself - see _event_handler.
sub _transport_params {
  my ( $self, @keys ) = @_;
  my %params = map { $_ => $self->{$_} } @keys;
  for my $event (grep { $EVENT_KEYS{$_} } keys %params) {
    $params{$event} = $self->_event_handler($event);
  }
  return %params;
}

# Private: the handler handed to the transport for an event of this client's
# own. It is the transport that receives the underlying thing - a notification,
# an ended subscription - and invokes the event, so a handler passed on as it
# stands would be called with the transport, while every other event of this
# client is called with the client. This wrapper puts the client back in front,
# and leaves the choice of handler to the client's own event dispatch, so a
# subclass method serves as well as a configured code ref.
#
# The client holds the transport, so what the transport holds must not hold the
# client: a strong reference in here would close the cycle. It is never undef
# where it matters - a transport that can still deliver anything is in a loop,
# and the loop holds the client that holds it.
sub _event_handler {
  my ( $self, $event ) = @_;
  return undef unless $self->can_event($event);

  weaken( my $weak_self = $self );
  return sub {
    my ( undef, @args ) = @_;
    my $client = $weak_self or return;
    return $client->maybe_invoke_event($event => @args);
  };
}

sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);
  $self->_ensure_transport;
}

sub _ensure_transport {
  my ( $self ) = @_;
  return if $self->{transport};

  if ($self->{server}) {
    require Net::Async::MCP::Transport::InProcess;
    $self->{transport} = Net::Async::MCP::Transport::InProcess->new(
      server => $self->{server},
    );
  }
  elsif ($self->{command}) {
    croak "Stdio transport requires being added to an IO::Async::Loop"
      unless $self->loop;
    require Net::Async::MCP::Transport::Stdio;
    $self->_build_transport('Net::Async::MCP::Transport::Stdio',
      command => $self->{command});
  }
  elsif ($self->{url}) {
    croak "HTTP transport requires being added to an IO::Async::Loop"
      unless $self->loop;
    require Net::Async::MCP::Transport::HTTP;
    $self->_build_transport('Net::Async::MCP::Transport::HTTP',
      url => $self->{url});
  }
  else {
    croak "Must provide server, command, or url";
  }
}

# Private: a transport of $class, built with the setting that selected it and
# whichever of %TRANSPORT_KEYS that class takes, and made a child of this
# client so that it joins and leaves the loop along with it.
sub _build_transport {
  my ( $self, $class, %params ) = @_;

  # Only the keys the caller actually gave: handing over a stall_timeout of
  # undef for one that was never set would switch off the transport's default
  # instead of leaving it alone. Events are asked for by name rather than by
  # key, because a subclass method of that name is a handler just as much as a
  # configured code ref is.
  my @keys = grep { $class->isa($TRANSPORT_KEYS{$_}) }
    grep { $EVENT_KEYS{$_} ? $self->can_event($_) : exists $self->{$_} }
    sort keys %TRANSPORT_KEYS;

  my $transport = $class->new(%params, $self->_transport_params(@keys));
  $self->{transport} = $transport;
  $self->add_child($transport);
  return $transport;
}

sub protocol_version { $_[0]->{protocol_version} }


sub client_capabilities { $_[0]->{client_capabilities} }


sub headers { $_[0]->{headers} }


sub timeout { $_[0]->{timeout} }


sub stall_timeout { $_[0]->{stall_timeout} }





# Private: the C<_meta> fields carried on every JSON-RPC request, as required
# by the current MCP revision.
sub _meta {
  my ( $self ) = @_;
  return {
    'io.modelcontextprotocol/protocolVersion'    => $self->{protocol_version},
    'io.modelcontextprotocol/clientCapabilities' => $self->{client_capabilities},
    'io.modelcontextprotocol/clientInfo'         => {
      name    => 'Net::Async::MCP',
      version => $VERSION,
    },
  };
}

# Private: merge a caller's C<_meta> (if any) into the standard one, returning
# params that carry C<_meta> on every request.
sub _with_meta {
  my ( $self, $params ) = @_;
  my %params = %{ $params // {} };
  my %meta   = (%{ $self->_meta }, %{ $params{_meta} // {} });
  return { %params, _meta => \%meta };
}

# Private: how many input_required results one request may collect before the
# client gives up on it. A server is allowed to ask again after being answered
# - a confirmation can lead to a second question - but one that never arrives
# at a final result would keep this going for as long as it feels like.
my $MAX_INPUT_ROUNDS = 8;

# Private: the protocol revision to send a refused request again with, or undef
# if there is none. A server that does not speak the revision a request was
# made with answers UNSUPPORTED_PROTOCOL_VERSION and lists the ones it does
# speak in error.data.supported, newest first; the first of those this client
# speaks too is the one to switch to.
sub _renegotiated_version {
  my ( $self, $failed ) = @_;

  my ( undef, $category, $error ) = $failed->failure;
  return undef unless ( $category // '' ) eq 'mcp' && ref $error eq 'HASH';
  return undef unless ( $error->{code} // 0 ) == $UNSUPPORTED_PROTOCOL_VERSION;

  my $supported = ref $error->{data} eq 'HASH' ? $error->{data}{supported} : undef;
  return undef unless ref $supported eq 'ARRAY';

  my %usable = map { $_ => 1 } @SPOKEN_PROTOCOL_VERSIONS;
  for my $version (@$supported) {
    next unless defined $version && !ref $version && $usable{$version};

    # The one offer that is no answer: the request that was just refused
    # carried this very version, so sending it again would be sending the same
    # request twice and getting the same refusal back.
    return undef if $version eq $self->{protocol_version};
    return $version;
  }

  return undef;
}

# Private: one MCP request, from a method's own params to the final result.
# Every method goes through here, because this is the one place that holds what
# is true of all of them: the _meta every request carries, the input_required
# round trips a result may take before it is one, and the one retry a refused
# protocol version is worth.
async sub _request {
  my ( $self, $method, $params, %options ) = @_;

  my ( %retry, $rounds, $renegotiated );
  while ( 1 ) {
    # Awaited as a completed Future rather than for its value: a failure has
    # more to it than its message, and the server's error object - which is
    # where a refused version names the ones it would accept instead - travels
    # as the failure's details.
    my $answered = await $self->{transport}->send_request($method,
      $self->_with_meta({ %{ $params // {} }, %retry }), %options)
      ->followed_by(sub { Future->done( $_[0] ) });

    if ( $answered->is_failed ) {
      my $version = $renegotiated ? undef : $self->_renegotiated_version($answered);

      # Nothing to switch to, or one switch already made - which makes a second
      # refusal the server's problem and not one more version away from being
      # solved. Either way the server's own error is what the caller gets, code
      # and data and all, rather than a summary of it written here.
      return await $answered unless defined $version;

      # Kept on the client, not just used for the retry: every following
      # request would otherwise pay for the same refusal again. The _meta at
      # the top of this loop is built afresh, so the retry carries the version
      # agreed on here and the answers of any input_required round already
      # walked.
      $renegotiated = 1;
      $self->{protocol_version} = $version;
      next;
    }

    my $result = $answered->get;

    return $result
      unless ref $result eq 'HASH'
      && ( $result->{resultType} // '' ) eq 'input_required';

    croak "MCP $method: server answered with input_required more than "
      . "$MAX_INPUT_ROUNDS times without returning a result"
      if ++$rounds > $MAX_INPUT_ROUNDS;

    %retry = await $self->_input_required($method, $result);
  }
}

# Private: the top-level params that turn a request into the retry an
# input_required result asks for. Both of them are optional and each is sent
# only when the result actually carried it.
async sub _input_required {
  my ( $self, $method, $result ) = @_;

  my %retry;

  # Mirrored back exactly as it arrived. The server sealed it against its own
  # secret and bound it to this caller and this primitive, so there is nothing
  # here to read and everything to break by touching it.
  $retry{requestState} = $result->{requestState} if defined $result->{requestState};

  my $requests = $result->{inputRequests};
  if ( ref $requests eq 'HASH' && keys %$requests ) {
    $retry{inputResponses} = await $self->_input_responses($method, $requests);
  }
  elsif ( !%retry ) {
    # Neither half: no question to answer, and nothing to hand back that would
    # make the second attempt any different from the first.
    croak "MCP $method: server sent an input_required result with neither "
      . "inputRequests nor requestState";
  }

  return %retry;
}

# Private: the answers to a server's input requests, under the keys it asked
# them by - the same keys it reads its own responses back from.
async sub _input_responses {
  my ( $self, $method, $requests ) = @_;

  # Checked over the whole ask before a single answer is gathered: a server
  # that asks for an undeclared capability has broken its side of the
  # capability promise, and no part of that ask should be acted on.
  my $capabilities = $self->{client_capabilities} // {};
  for my $key (sort keys %$requests) {
    my $request = $requests->{$key};
    my $wanted  = ref $request eq 'HASH' ? $request->{method} : undef;

    croak "MCP $method: server sent an input request '$key' without a method"
      unless defined $wanted && length $wanted;

    # The capability is the namespace of the method asked for:
    # elicitation/create needs elicitation, sampling/createMessage needs
    # sampling, roots/list needs roots.
    my $capability = ( split m{/}, $wanted, 2 )[0];
    croak "MCP $method: server sent input request '$key' for '$wanted', "
      . "a capability this client did not declare in client_capabilities"
      unless exists $capabilities->{$capability};
  }

  croak "MCP $method: server sent input requests ("
    . join(', ', sort keys %$requests)
    . ") but no on_input_request handler is set to answer them"
    unless $self->can_event('on_input_request');

  my %responses;
  for my $key (sort keys %$requests) {
    my $request  = $requests->{$key};
    my $response = $self->invoke_event(on_input_request =>
      $request->{method}, $request->{params} // {});

    # A handler that has to ask a human answers with a Future instead of an
    # answer, and the retry waits for it.
    $response = await $response if blessed($response) && $response->isa('Future');

    croak "MCP $method: on_input_request answered input request '$key' with "
      . "something that is not a HashRef"
      unless ref $response eq 'HASH';

    $responses{$key} = $response;
  }

  return \%responses;
}

sub server_info { $_[0]->{server_info} }


sub server_capabilities { $_[0]->{server_capabilities} }


async sub initialize {
  my ( $self ) = @_;
  $self->_ensure_transport;

  my $result = await $self->_request('server/discover');

  # Read without autovivifying an _meta key into the result we hand back.
  my $meta = $result->{_meta} // {};
  $self->{server_info} = $meta->{'io.modelcontextprotocol/serverInfo'} // {};
  $self->{server_capabilities} = $result->{capabilities} // {};

  return $result;
}


# Private: how many pages a list method walks before giving up. Only a cursor
# that comes round again proves a server is looping; one that keeps changing
# while never running out cannot be told apart from a genuinely long list, so
# there has to be an end to it somewhere.
my $MAX_LIST_PAGES = 100;

# Private: every entry of a paginated list method, following nextCursor until
# the server stops handing one out. $key is the result key holding the entries,
# and each page is appended in the order the server sent it.
#
# Anything short of the full list is failed rather than returned. Handing back
# the pages collected so far would be indistinguishable from a server that
# really has that many entries, which is exactly the bug this walk exists to
# fix - it would just move from the first page to the hundredth.
async sub _list_all {
  my ( $self, $method, $key ) = @_;

  my ( @entries, %seen, $cursor );

  for my $page ( 1 .. $MAX_LIST_PAGES ) {
    my $result = await $self->_request($method,
      defined $cursor ? { cursor => $cursor } : undef);

    push @entries, @{ $result->{$key} // [] };

    $cursor = $result->{nextCursor};
    return \@entries unless defined $cursor;

    # A cursor is a position in the list, so being handed one back that was
    # already followed means the server is not moving. Left alone that spins
    # for as long as the server keeps answering.
    croak "MCP $method pagination: server repeated cursor '$cursor'"
      if $seen{$cursor}++;
  }

  croak "MCP $method pagination: server offered more than $MAX_LIST_PAGES pages";
}

async sub list_tools {
  my ( $self ) = @_;
  my $tools = await $self->_list_all('tools/list', 'tools');

  # A fresh listing is the whole truth about the server's tools, so it replaces
  # the cache rather than adding to it - and the whole truth is every page,
  # which is why this runs on the merged list once the walk is through. A walk
  # that failed part way leaves the cache as it was instead of replacing it with
  # what happens to have arrived.
  $self->{tool_header_params} = {
    map { $_->{name} => _header_params($_->{inputSchema}) }
    grep { ref $_ eq 'HASH' && defined $_->{name} } @$tools
  };

  return $tools;
}


# Private: the arguments a server expects mirrored into Mcp-Param-{Name}
# headers - every property annotated with x-mcp-header, reachable from the
# schema root through a chain of "properties" keys and nothing else. Same walk
# as MCP::Tool::_header_params, whose result the server checks the headers
# against, down to sorting by key so both sides agree on order.
sub _header_params {
  my ( $schema, $path ) = @_;
  $path //= [];

  return [] unless ref $schema eq 'HASH' && ref $schema->{properties} eq 'HASH';

  my $properties = $schema->{properties};
  my @params;
  for my $key (sort keys %$properties) {
    my $property = $properties->{$key};
    next unless ref $property eq 'HASH';

    my @next = ( @$path, $key );
    push @params, {
      name => $property->{'x-mcp-header'},
      path => \@next,
      type => $property->{type} // '',
    } if defined $property->{'x-mcp-header'};
    push @params, @{ _header_params($property, \@next) };
  }

  return \@params;
}

# Private: the argument a header parameter points at, or undef if the caller
# passed none. Same walk as MCP::Server::Transport::HTTP::_arg_value, which is
# what the server compares the header against.
sub _arg_value {
  my ( $arguments, $path ) = @_;

  my $value = $arguments;
  for my $key (@$path) {
    return undef unless ref $value eq 'HASH';
    $value = $value->{$key};
  }
  return $value;
}

# Private: an argument value in the form the server's _match_value compares it
# in. Getting this wrong is not a degradation but a rejection: the server
# answers -32020 (HEADER_MISMATCH) for a header that disagrees with the body.
sub _header_value {
  my ( $type, $value ) = @_;

  if ($type eq 'boolean') {
    # A JSON false reaches us either as \0, which JSON::MaybeXS encodes as
    # false, or as a JSON::PP::Boolean. The latter knows it is false, but \0 is
    # a reference and so a *true* Perl value: asking it directly would put
    # "true" in the header while the body says false. Unwrap plain scalar
    # references first, and let an object's own boolean overload speak.
    $value = $$value while ref $value eq 'SCALAR' || ref $value eq 'REF';
    return $value ? 'true' : 'false';
  }

  # Compared numerically by the server, so the number decides, not its
  # spelling. Anything that is not a number at all is passed through as text
  # for the server to reject.
  return 0 + $value if $type eq 'integer' && !ref $value && looks_like_number($value);

  return "$value";
}

# Private: the Mcp-Param-{Name} bindings for a tools/call, as a list of
# name/value pairs with each value already formatted the way the server
# compares it.
async sub _tool_header_params {
  my ( $self, $name, $arguments ) = @_;

  my $transport = $self->{transport};
  return () unless $transport->can('mirrors_header_params')
    && $transport->mirrors_header_params;

  unless (exists $self->{tool_header_params}{$name}) {
    # Calling a tool whose schema this client has never seen is not safe over a
    # binding that mirrors arguments into headers: an annotated argument
    # without its header is rejected outright, so the schema has to be fetched
    # before the call goes out. A failure is deliberately swallowed - the tool
    # may well have no annotated argument at all, and must not become
    # uncallable because an unrelated tools/list failed. The request then goes
    # out bare and the server decides.
    await $self->list_tools->else(sub { Future->done });
  }

  my @params;
  for my $param (@{ $self->{tool_header_params}{$name} // [] }) {
    my $value = _arg_value($arguments, $param->{path});

    # A header the server does not expect is rejected exactly like a missing
    # one, so an argument the caller left out gets no header.
    next unless defined $value;

    push @params, {
      name  => $param->{name},
      value => _header_value($param->{type}, $value),
    };
  }

  return @params;
}

async sub call_tool {
  my ( $self, $name, $arguments ) = @_;
  $arguments //= {};

  my @header_params = await $self->_tool_header_params($name, $arguments);

  my $result = await $self->_request('tools/call',
    {
      name      => $name,
      arguments => $arguments,
    },
    @header_params ? ( header_params => \@header_params ) : (),
  );
  return $result;
}


async sub list_prompts {
  my ( $self ) = @_;
  return await $self->_list_all('prompts/list', 'prompts');
}


async sub get_prompt {
  my ( $self, $name, $arguments ) = @_;
  my $result = await $self->_request('prompts/get', {
    name      => $name,
    arguments => $arguments // {},
  });
  return $result;
}


async sub list_resources {
  my ( $self ) = @_;
  return await $self->_list_all('resources/list', 'resources');
}


async sub read_resource {
  my ( $self, $uri ) = @_;
  my $result = await $self->_request('resources/read', {
    uri => $uri,
  });
  return $result;
}


# Private: the notification a server answers a subscriptions/listen with in
# place of a response. Named to the transport rather than recognised by it -
# see subscriptions_listen.
my $SUBSCRIPTION_ACKNOWLEDGED = 'notifications/subscriptions/acknowledged';

async sub subscriptions_listen {
  my ( $self, $notifications ) = @_;
  my $result = await $self->_request('subscriptions/listen',
    { notifications => $notifications // {} },
    resolve_on_notification => $SUBSCRIPTION_ACKNOWLEDGED);
  return $result;
}


async sub subscriptions_stop {
  my ( $self, $subscription_id ) = @_;
  $self->_ensure_transport;

  my $transport = $self->{transport};
  return 0 unless $transport->can('stop_subscription');
  return $transport->stop_subscription($subscription_id);
}


async sub ping {
  my ( $self ) = @_;
  # The current MCP revision moved liveness to the transport level and has no
  # client-addressable JSON-RPC "ping" request. Sending one would fail against
  # MCP::Server >= 0.15 (InProcess errors with -32601); stdio only "succeeded"
  # via an accidental legacy latch. Ask the transport whether it is still
  # usable instead of reporting success unconditionally.
  $self->_ensure_transport;
  croak "MCP transport is not alive" unless $self->{transport}->is_alive;
  return 1;
}


async sub shutdown {
  my ( $self ) = @_;
  if ($self->{transport} && $self->{transport}->can('close')) {
    await $self->{transport}->close;
  }
  return 1;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP - Async MCP (Model Context Protocol) client for IO::Async

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::MCP;
    use Future::AsyncAwait;

    my $loop = IO::Async::Loop->new;

    # In-process transport (Perl MCP::Server in same process)
    use MCP::Server;
    my $server = MCP::Server->new(name => 'MyServer');
    $server->tool(
        name         => 'echo',
        description  => 'Echo text',
        input_schema => {
            type       => 'object',
            properties => { message => { type => 'string' } },
            required   => ['message'],
        },
        code => sub { return "Echo: $_[1]->{message}" },
    );

    my $mcp = Net::Async::MCP->new(server => $server);
    $loop->add($mcp);

    # Stdio transport (external MCP server subprocess)
    my $mcp_stdio = Net::Async::MCP->new(
        command => ['npx', '@anthropic/mcp-server-web-search'],
    );
    $loop->add($mcp_stdio);

    # HTTP transport (remote MCP server)
    my $mcp_http = Net::Async::MCP->new(
        url     => 'https://example.com/mcp',
        headers => { Authorization => "Bearer $token" },
    );
    $loop->add($mcp_http);

    # All transports share the same async API:
    async sub main {
        await $mcp->initialize;

        my $tools = await $mcp->list_tools;
        # [{name => 'echo', description => '...', inputSchema => {...}}]

        my $result = await $mcp->call_tool('echo', { message => 'Hello' });
        # {content => [{type => 'text', text => 'Echo: Hello'}], isError => \0}

        await $mcp->shutdown;
    }

    main()->get;

=head1 DESCRIPTION

L<Net::Async::MCP> is an asynchronous client for the MCP (Model Context
Protocol) built on L<IO::Async>. It connects to MCP servers via pluggable
transports:

=over 4

=item * B<InProcess> - Direct calls to an L<MCP::Server> instance in the same
process. See L<Net::Async::MCP::Transport::InProcess>.

=item * B<Stdio> - Subprocess communication over stdin/stdout using
newline-delimited JSON-RPC. Works with any MCP server implementation (Perl,
Node.js, Python, etc.). See L<Net::Async::MCP::Transport::Stdio>.

=item * B<HTTP> - Streamable HTTP transport for remote MCP servers. Supports
both JSON and SSE responses. See L<Net::Async::MCP::Transport::HTTP>.

=back

All methods return L<Future> objects and work with L<Future::AsyncAwait>.
Call L</initialize> first before using any other MCP methods. It performs the
handshake with a single C<server/discover> request of the revision this client
speaks (see L</protocol_version>; the legacy C<initialize> request no longer
exists in it), carrying the client's protocol version, capabilities, and info
in C<_meta>.

=head2 protocol_version

    my $version = $mcp->protocol_version;

Returns (or via C<configure>/constructor argument C<protocol_version> sets) the
MCP protocol revision this client speaks on the wire, such as C<'2026-07-28'>.
Sent on every request inside C<_meta>. Defaults to the newest revision this
client builds the requests of.

A server that does not speak this revision answers with
C<UNSUPPORTED_PROTOCOL_VERSION> (-32022) and names the ones it does. Where one
of those is a revision this client speaks too - one whose request shapes it
builds, which today is exactly one - the request goes out again in it, and this
attribute keeps it, so every following request carries the agreed revision from
the start.

Which revisions those are, and which of them is the default, is this
distribution's own to say. An installed L<MCP::Server> has no part in it:
its C<PROTOCOL_VERSION> is the revision that library implements, and taking
that for the default would put a new version string on requests still built in
the old revision the moment the library learns a newer one - trading a clear
"unsupported protocol version" for a confusing "method not found".

Nothing beyond that one retry: a refusal that offers no usable revision, and a
second refusal after the switch, both reach the caller as the server's own
error with its code and C<data>, because the revisions it named are in there
and in nothing this client could put in its place.

=head2 client_capabilities

    my $caps = $mcp->client_capabilities;
    $mcp->configure(client_capabilities => { sampling => {} });

Returns (or via C<configure>/constructor argument C<client_capabilities> sets)
the HashRef of client capabilities sent on every request inside C<_meta>.
Defaults to C<{}>, an empty declaration, which is what a client that never
touches this attribute keeps sending.

Setting this is a B<promise>, not a hint. A conforming server may not send an
C<inputRequest> for a capability the client did not declare, so the empty
default is precisely what keeps a server from asking this client for anything
it cannot do. Declaring C<sampling>, C<elicitation> or C<roots> here tells the
server it may ask, and what answers it is L</on_input_request> that gives, so
declare a capability only once that handler serves it. This client holds both
ends of the promise: an input request for a capability that is not declared
here is refused as a server violation rather than passed on to the handler.

=head2 headers

    my $headers = $mcp->headers;
    $mcp->configure(headers => { Authorization => "Bearer $token" });

Returns (or via C<configure>/constructor argument C<headers> sets) a HashRef of
extra headers sent with every HTTP request, which is how a server behind OAuth
is reached: nothing else in this client sets an C<Authorization>. Configuring
them after the client has joined a loop works too, so a token can be rotated on
a live client.

They cannot take over a header the MCP binding derives from the request body -
see L<Net::Async::MCP::Transport::HTTP/new> for why that is a rejection rather
than an override. Only the HTTP transport sends headers at all; the InProcess
and Stdio transports ignore this.

=head2 timeout

    my $timeout = $mcp->timeout;

Returns (or via C<configure>/constructor argument C<timeout> sets) the
wall-clock limit in seconds on a single HTTP request. Unset by default, because
an MCP C<tools/call> may legitimately run for minutes and a default would break
such a setup; L</stall_timeout> is the one that guards against a hung server.
Note that C<0> is a limit of zero seconds rather than "no limit". HTTP
transport only.

=head2 stall_timeout

    my $stall_timeout = $mcp->stall_timeout;

Returns (or via C<configure>/constructor argument C<stall_timeout> sets) how
many seconds an HTTP request may go without a single byte moving before it is
given up on. Set it to C<0> to switch it off. Undef here means it was never
configured and L<Net::Async::MCP::Transport::HTTP>'s default of 60 seconds
applies. HTTP transport only.

=head2 on_notification

    my $mcp = Net::Async::MCP->new(
        url             => 'https://example.com/mcp',
        on_notification => sub {
            my ( $mcp, $notification ) = @_;
            warn "$notification->{method}\n";
        },
    );

Invoked for every server-initiated notification the transport reads, with the
decoded JSON-RPC notification as it stood on the wire -
C<method> and, where the notification has any, C<params>. The
C<notifications/progress> of a long C<tools/call> is the usual reason to want
one, and it is only worth anything while that call is still running, which is
why it is an event and not part of the L<Future> the call resolves with.

Set it through C<new> or C<configure> like any other event, or implement a
method of this name in a subclass; configuring it on a client that is already
in a loop reaches the transport it built. The first argument is this client,
the same as L</on_input_request> and every other event here gets, even though
it is the transport that receives the notification and starts the call.

A handler set directly on a transport object rather than here is that
transport's own event and is called with the transport - see
L<Net::Async::MCP::Transport::HTTP/on_notification> and
L<Net::Async::MCP::Transport::Stdio/on_notification>.

The HTTP and Stdio transports both deliver what their server sends, and a
handler set here reaches whichever of the two this client built. What reaches
them differs: the HTTP transport reads notifications off the response stream of
a request it is running, while the Stdio transport reads whatever the
subprocess writes, whether a request is in flight or not. The InProcess
transport has nothing a notification could arrive over - it is a direct call
and its return value - so setting this on an in-process client is silently
without effect.

=head2 on_subscription_end

    my $mcp = Net::Async::MCP->new(
        url                  => 'https://example.com/mcp',
        on_subscription_end  => sub {
            my ( $mcp, $subscription_id ) = @_;
        },
    );

Invoked when the stream a subscription runs on ends on its own, with the
subscription id as its second argument - the same id L</subscriptions_listen>
handed back and L</subscriptions_stop> takes. The first argument is this
client, the same as L</on_notification> and every other event here gets, even
though it is the transport that watches the stream and starts the call.

A subscription is answered by its acknowledgement, and the L<Future> of
L</subscriptions_listen> is settled there and then; the stream then runs for
as long as the subscription does. So the only way a subscription can come to
the caller's attention again is its end - and there are two kinds. An end the
caller caused itself, through L</subscriptions_stop>, happens because it asked
for it and is not reported. An end that comes from the server's side - the
server closing the stream, the connection failing underneath it, a gateway
giving up on it - reaches a caller holding nothing but an already-settled
L<Future>, and that is the end this event reports, the moment the stream ends.
A caller waiting on L</subscriptions_stop> for false, to learn the same thing,
would learn it only when it thought to ask.

Set it through C<new> or C<configure> like any other event, or implement a
method of this name in a subclass; configuring it on a client that is already
in a loop reaches the transport it built. A handler set directly on a
transport object rather than here is that transport's own event and is called
with the transport - see L<Net::Async::MCP::Transport::HTTP/on_subscription_end>.

Only L<Net::Async::MCP::Transport::HTTP> can fire it: it is the only transport
with a stream a subscription runs on, and L</subscriptions_listen> says as
much. Setting this on a Stdio or InProcess client is therefore silently
without effect.

=head2 on_input_request

    my $mcp = Net::Async::MCP->new(
        server              => $server,
        client_capabilities => { elicitation => {} },
        on_input_request    => sub {
            my ( $mcp, $method, $params ) = @_;
            # $method is 'elicitation/create', 'sampling/createMessage', ...
            return { action => 'accept', content => { ok => \1 } };
        },
    );

Invoked for every input request a server embeds in a result, and returns the
response to it - either the response structure itself, or a L<Future> that will
resolve with one, which is what lets a handler go and ask a human. The
C<$params> are the request's own, whatever the asked-for method takes: a
C<message> and C<requestedSchema> for C<elicitation/create>, the messages for
C<sampling/createMessage>, and so on.

One handler serves every kind of input request rather than one attribute per
capability, because the set of methods a server may ask for is the
specification's to grow, and a caller branching on C<$method> keeps working
when it does.

Set it through C<new> or C<configure>, or implement a method of this name in a
subclass - it is an ordinary L<IO::Async::Notifier> event, so both work.
Handlers are called one after another, in the order of the request keys, so a
handler that asks a user two questions asks them one at a time.

Its return value goes on the wire as it is, under the key the server gave the
request, and must be a HashRef; C<< { action => 'accept', content => {...} } >>
is what a server expects for an C<elicitation/create>. See
L</Input required results> for the round trip this handler is one half of.

=head2 Input required results

A server that needs something from the client before it can finish answers with
an C<input_required> result instead of a final one - C<resultType> set to
C<input_required>, optionally C<inputRequests> naming what it wants, and
optionally an opaque C<requestState>. SEP-2322 made this the way sampling,
elicitation and roots reach a client: not as requests the server sends, but as
a result the client answers by asking the same question again.

Every method of this client walks that round trip itself and returns the final
result, so a caller never sees an C<input_required>:

=over 4

=item *

C<inputRequests> are handed one by one to L</on_input_request>, and its answers
travel back as C<inputResponses> under the very keys the server used.

=item *

C<requestState> is mirrored back untouched. It is sealed and bound by the
server, so this client never parses, inspects or edits it, and a result that
carries none is retried without one.

=item *

A result with a C<requestState> and no C<inputRequests> is a server asking for
nothing but the call again, and is retried straight away without troubling the
handler.

=back

Four things fail the L<Future> instead, loudly, because each of them would
otherwise leave the caller with a result that looks final and is not:

=over 4

=item *

An C<inputRequests> entry for a capability that L</client_capabilities> does
not declare. A conforming server may not ask for one, so this is named as the
server violation it is rather than passed to the handler.

=item *

An C<inputRequests> with no L</on_input_request> to answer it.

=item *

More than eight C<input_required> results in a row on one request. A server may
legitimately ask twice, but one that never arrives at a result has to be given
up on somewhere.

=item *

An C<input_required> result carrying neither of the two, which leaves nothing
to answer and nothing to send back.

=back

=head2 server_info

    my $info = $mcp->server_info;

Returns the server info hashref from the MCP C<server/discover> handshake
response. Contains at minimum C<name> and C<version> keys. Only available after
L</initialize> has been called.

=head2 server_capabilities

    my $caps = $mcp->server_capabilities;

Returns the server capabilities hashref from the MCP C<server/discover>
handshake response. Only available after L</initialize> has been called.

=head2 initialize

    my $result = await $mcp->initialize;

Performs the MCP handshake. Must be called before any other MCP method. The
current MCP revision has replaced the old C<initialize> request with
C<server/discover>, which this method sends, carrying the client's protocol
version and L</client_capabilities> in C<_meta>. The server responds with its
capabilities and, in C<result._meta>, its server info.

That single request is the whole handshake: no C<notifications/initialized>
follows it. SEP-2575 removed the C<initialize>/C<initialized> pair along with
the C<initialize> request itself, and the Streamable HTTP binding of this
revision defines no client-to-server notifications at all, so the follow-up
would have been an extra POST that no conforming server acts on.

Returns the raw result hashref (C<capabilities> key, plus C<_meta> containing
C<io.modelcontextprotocol/serverInfo>). Also populates the L</server_info> and
L</server_capabilities> accessors.

C<initialize> remains a compatibility alias for the handshake; there is no
separate C<discover> entry point.

=head2 list_tools

    my $tools = await $mcp->list_tools;

Returns an ArrayRef of tool definition hashrefs from the MCP server. Each
hashref contains C<name>, C<description>, and C<inputSchema> keys.

Also caches, per tool, which of its arguments are annotated with
C<x-mcp-header> in the input schema, which L</call_tool> needs to build the
C<Mcp-Param-{Name}> headers of the HTTP binding.

Paginated tool lists are walked to the end: as long as the server answers with
a C<nextCursor>, the next page is requested with that C<cursor> and its tools
appended, so both the returned list and the cache cover every page. Nothing
short of the whole list is ever returned - a server that keeps handing back a
cursor it already gave out, or that offers more than 100 pages, fails the
returned L<Future> instead, because a quietly truncated list is the same bug
this walk is here to fix.

=head2 call_tool

    my $result = await $mcp->call_tool($name, \%arguments);

Calls a named tool on the MCP server with the given arguments hashref.
Returns a hashref with C<content> (ArrayRef of content blocks) and C<isError>
(boolean).

A tool may annotate arguments in its input schema with C<x-mcp-header>, which
over the HTTP binding have to be mirrored into C<Mcp-Param-{Name}> headers; a
conforming server rejects a C<tools/call> that passes such an argument without
its header, and equally one that carries a header for an argument it did not
pass. This method resolves them from the tool's input schema, which means it
needs the schema: on a transport that mirrors headers it fetches L</list_tools>
once for a tool it has not seen, and keeps using the cached schemas afterwards.
If that fetch fails the call is still sent, without headers, leaving the
decision to the server.

Transports that do not mirror headers - InProcess and Stdio - resolve nothing
and never fetch a tool list on their own.

=head2 list_prompts

    my $prompts = await $mcp->list_prompts;

Returns an ArrayRef of prompt definition hashrefs from the MCP server.
Paginated results are followed to the end and merged, on the same terms as
L</list_tools>.

=head2 get_prompt

    my $result = await $mcp->get_prompt($name, \%arguments);

Retrieves a named prompt from the MCP server, optionally passing arguments.
Returns the prompt result hashref.

=head2 list_resources

    my $resources = await $mcp->list_resources;

Returns an ArrayRef of resource definition hashrefs from the MCP server.
Paginated results are followed to the end and merged, on the same terms as
L</list_tools>.

=head2 read_resource

    my $result = await $mcp->read_resource($uri);

Reads a resource by URI from the MCP server. Returns the resource content
hashref.

=head2 subscriptions_listen

    my $subscription = await $mcp->subscriptions_listen({ toolsListChanged => 1 });
    my $id = $subscription->{_meta}{'io.modelcontextprotocol/subscriptionId'};

Opens a C<subscriptions/listen> subscription on the MCP server, requesting
server-initiated notifications. C<$notifications> is a hashref mapping
notification types to a truthy value (e.g. C<toolsListChanged>,
C<promptsListChanged>, C<resourcesListChanged>). The request carries the
standard C<_meta> like all client methods.

A server does not answer this request with a response. It opens a stream,
writes C<notifications/subscriptions/acknowledged> onto it, and then holds the
stream open to carry the notifications that were subscribed to. This method
returns that acknowledgement's C<params>: the subscription id under C<_meta>,
and under C<notifications> the types the server actually honoured, which need
not be everything that was asked for. The notifications themselves arrive at
L</on_notification>, like every other server-initiated notification, and the
acknowledgement does not - it is this request's answer rather than something
that happened while it waited.

Which notification answers the request is told to the transport rather than
recognised by it, so that a transport executes what the protocol layer decided
instead of reading method names and deciding for itself.

Ending a subscription is L</subscriptions_stop>. There is no request for it:
closing the stream is what unsubscribes, and a server drops the subscription
when its stream finishes.

Only L<Net::Async::MCP::Transport::HTTP> has a stream to run this on. The
InProcess transport refuses C<subscriptions/listen> outright, and a server
without notification support answers JSON-RPC error -32601
(C<METHOD_NOT_FOUND>); either way the returned L<Future> fails. The Stdio
transport refuses it as well: L<MCP::Server> E<gt>= 0.15 serves the method
over stdio too, answering with a C<notifications/subscriptions/acknowledged>
notification where HTTP would answer with a response, and a transport that
cannot settle a request from a notification says so rather than wait for an
answer that will not come.

=head2 subscriptions_stop

    my $stopped = await $mcp->subscriptions_stop($subscription_id);

Ends the subscription of that id, and resolves with true if there was one to
end. The C<$subscription_id> is the one L</subscriptions_listen> handed back
in C<< $subscription->{_meta}{'io.modelcontextprotocol/subscriptionId'} >>.

Unsubscribing is closing the stream the subscription runs on. The current
revision has no request that cancels a subscription and no acknowledgement of
one, so nothing goes on the wire and the server drops the subscription when
its stream finishes.

Resolves with false for an id no subscription is running under - one that was
never opened, one already stopped, and one whose stream has ended on its own,
which are not told apart. It is also false on a transport that cannot
subscribe at all, since neither the InProcess nor the Stdio transport has a
stream a subscription could run on.

That makes this the way to ask whether a subscription is still running. The
prompt way is L</on_subscription_end>, which fires the moment a stream ends on
its own - the server closing it, the connection failing - because the
L<Future> of L</subscriptions_listen> was settled by the acknowledgement long
before and cannot report it. This method is what a caller that missed the
event, or did not set one, falls back on. See
L<Net::Async::MCP::Transport::HTTP/stop_subscription>.

=head2 ping

    await $mcp->ping;

Performs a transport-level liveness check and returns C<1>. The current MCP
revision moved liveness to the transport layer and has no client-addressable
JSON-RPC C<ping> request, so no request goes on the wire; sending one would
fail against L<MCP::Server> E<gt>= 0.15.

Instead the transport's C<is_alive> is consulted, and the returned L<Future>
fails if the transport can no longer carry requests: for
L<Net::Async::MCP::Transport::Stdio> that means the subprocess has exited,
while the InProcess and HTTP transports have no connection state and are
always alive.

=head2 shutdown

    await $mcp->shutdown;

Cleanly shuts down the MCP connection. For the Stdio transport this sends
SIGTERM to the subprocess and waits for it to exit. For the HTTP transport it
ends every subscription still running, that being the one thing it holds which
outlives the request that opened it, and sends nothing. For the InProcess
transport it is a no-op: a direct call and its return value leave nothing
behind.

=head1 SEE ALSO

=over 4

=item * L<Net::Async::MCP::Transport::InProcess> - In-process transport for Perl MCP servers

=item * L<Net::Async::MCP::Transport::Stdio> - Subprocess transport via stdin/stdout

=item * L<Net::Async::MCP::Transport::HTTP> - Streamable HTTP transport for remote servers

=item * L<IO::Async::Notifier> - Base class

=item * L<Future::AsyncAwait> - Async/await syntax used with this module

=item * L<https://modelcontextprotocol.io> - MCP specification

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
