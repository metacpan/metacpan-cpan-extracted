package POE::Component::Client::REST;
use POE qw(Component::Client::HTTP);
use Moose;
use HTTP::Request;

our $VERSION = '0.05';

has Alias => (
  is      => 'ro',
  default => 'REST-Session',
);

has http => (
  is      => 'ro',
  lazy    => 1,
  default => sub { my $str = $_[0]->Alias; "$str-HTTP" },
);

has request_cooker => (
  is        => 'ro',
  isa       => 'Maybe[CodeRef]',
);

has response_cooker => (
  is        => 'ro',
  isa       => 'Maybe[CodeRef]',
);

sub BUILD {
  my ($self, $args) = @_;

  my %object_states = map { $_ => "_$_" } qw(call shutdown respond);

  POE::Session->create(
    inline_states => {_start => sub { $poe_kernel->alias_set($self->Alias) }},
    object_states => [$self => \%object_states]
  );

  $args->{Alias} = $self->http;
  POE::Component::Client::HTTP->spawn(%$args);
}

sub spawn { my $self = shift; $self->new(@_) }

sub call {
  my ($self, $method, $url, @rest) = @_;
  my $opts = (@rest > 0 
    ? $rest[0] eq 'HASH' 
      ? $rest[0] 
      : {@rest}
    : {});
  $poe_kernel->post($self->Alias, call => $method, $url, $opts);
}

sub _call {
  my ($self, $heap, $method, $url, $opts) = 
    @_[OBJECT, HEAP, ARG0..ARG3];

  if (my $query = $opts->{query}) {
    my @pairs = map { my ($k, $v) = ($_, $query->{$_}); "$k=$v" }
                keys (%$query);

    $url = join('?', $url, join('&', @pairs));
  }

  my $request = HTTP::Request->new(
    $method, $url, $opts->{headers}, $opts->{content});

  my $cooker = exists $opts->{request_cooker} 
    ? $opts->{request_cooker}
    : $self->request_cooker;

  $request = $cooker->($request) if $cooker;

  if(my $cont = $opts->{callback}) {
    $heap->{request_info}->{$request}->{continuation} = $cont;
  }

  $heap->{request_info}->{$request}->{cooker} = 
    exists $opts->{response_cooker}
    ? $opts->{response_cooker}
    : $self->response_cooker;

  $poe_kernel->post($self->http, request => respond => $request);
}

sub _respond {
  my ($heap, $request_packet, $response_packet) = @_[HEAP, ARG0..ARG1];
  my $req = $request_packet->[0];
  my @res = ($response_packet->[0]);

  my $info = delete $heap->{request_info}->{$req};
  my $c = $info->{continuation} || return;
  my $cooker = $info->{cooker};
  @res = $cooker->(@res) if $cooker;

  if (ref $c eq 'CODE') {
    $c->(@res);
  }
  else {
    $poe_kernel->post($c->[0], $c->[1], @res);
  }
}

sub shutdown {
  $poe_kernel->post($_[0]->Alias, 'shutdown');
}

sub _shutdown {
  my $self = $_[OBJECT];
  $poe_kernel->post($self->http, 'shutdown');
  $poe_kernel->alias_remove($self->Alias);
}

1;

__END__

=head1 NAME

POE::Component::Client::REST - Low-level interface for REST calls

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

This class abstracts away some of the nastier details of talking to a REST
service.  

    use POE qw(Component::Client::REST::JSON);

    # simple CouchDB example

    POE::Session->create(inline_states => {
      _start => sub {
        $poe_kernel->alias_set('foo');
        my $rest = $_[HEAP]->{rest} = POE::Component::Client::REST::JSON->new;
        $rest->call(GET => 'http://localhost:5984/_all_dbs', callback =>
          [$_[SESSION], 'response']);
      },

      response => sub {
        my ($data, $response) = @_[ARG0, ARG1];
        die $response->status_line unless $response->code == 200;

        print 'Databases: ' . join(', ', @$data) . "\n";
        $poe_kernel->alias_remove('foo');
        $_[HEAP]->{rest}->shutdown();
      },
    });

    $poe_kernel->run();

=head1 ATTRIBUTES

=over 4

=item Alias

The string to use as the alias for the internal session.

=item http

The alias of the spawned HTTP object's session.  Defaults to something
reasonable.

=item request_cooker

A function which takes a request and cooks it in some fashion, returning a new
one (or the same one, modified). Undefined by default, but see 
L<POE::Component::Client::REST::JSON>.

=item response_cooker

Similar to the above, but returns a list of things to be passed to the
callbacks when a response is received for a particular request.

=back

=head1 METHODS

=head2 call I<method, url, keywords>

Makes an HTTP request to I<url> via I<method>. The following keyword arguments
are accepted (either as a hashref or just as extra argument pairs).

=over 4

=item request_cooker

=item response_cooker

Overrides the object defaults for these values.  Explicitly pass undef to
specify that no cooking should be done.

=item query

A hashref of query parameters to be appended as a query string.

=item content

Data (which may or may not get cooked) to be passed as the request body.

=item headers

Specify arbitrary headers as an arrayref of key-value pairs.

=item callback

Either a coderef or an arrayref of two elements (session and state name) to
call (or post to) with the (possibly cooked) response to the request.

=back

You can also post to this session's 'call' state for the same result, although
in this form the keywords must be a hashref.

=head2 spawn I<kwargs or hashref>

=head2 new I<kwargs or hashref>

Passes all options to L<POE::Component::Client::HTTP> except for Alias, which
is used for our own session.  The HTTP session has an alias of "$Alias-HTTP".
The default session alias for the internal session is REST-JSON-Session.

=head2 shutdown

Calls shutdown on the HTTP client and stops this session.  You can also post
to the 'shutdown' state for the same result.

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 BUGS

This was written for use with L<POE::Component::Client::CouchDB>, so it's
sort of tailored to that API and probably unsuitable without modification for
other purposes.  Patches welcome!

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul Driver

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
