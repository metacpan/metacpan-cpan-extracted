package POE::Component::Metabase::Client::Submit;
$POE::Component::Metabase::Client::Submit::VERSION = '0.14';
#ABSTRACT: a POE client that submits to Metabase servers

use strict;
use warnings;
use Carp ();
use HTTP::Status qw[:constants];
use HTTP::Request::Common ();
use HTTP::Message 5.814 (); # for HTTP::Message::decodable() support
use JSON ();
use POE qw[Component::Client::HTTP Component::Client::Keepalive];
use URI;

my @valid_args;
BEGIN {
  @valid_args = qw(profile secret uri fact event session http_alias context resolver compress);

  for my $arg (@valid_args) {
    no strict 'refs';
    *$arg = sub { $_[0]->{$arg}; }
  }
}

sub submit {
  my ($class,%opts) = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $args = $class->__validate_args(
    [ %opts ],
    {
      ( map { $_ => 0 } @valid_args ),
      ( map { $_ => 1 } qw(profile secret uri event fact) )
    } # hehe
  );

  my $self = bless $args, $class;

  Carp::confess( "'profile' argument for $class must be a Metabase::User::Profile" )
    unless $self->profile->isa('Metabase::User::Profile');
  Carp::confess( "'secret' argument for $class must be a Metabase::User::secret" )
    unless $self->secret->isa('Metabase::User::Secret');
  Carp::confess( "'secret' argument for $class must be a Metabase::Fact" )
    unless $self->secret->isa('Metabase::Fact');

  $self->{session_id} = POE::Session->create(
	  object_states => [
	    $self => [ qw(_start _dispatch _submit _response _register _guid_exists _http_req) ],
	  ],
	  heap => $self,
	  ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub _start {
  my ($kernel,$session,$sender,$self) = @_[KERNEL,SESSION,SENDER,OBJECT];
  $self->{session_id} = $session->ID();
  if ( $kernel == $sender and !$self->{session} ) {
        Carp::confess "Not called from another POE session and 'session' wasn't set\n";
  }
  my $sender_id;
  if ( $self->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $self->{session} ) ) {
        $sender_id = $ref->ID();
    }
    else {
        Carp::confess "Could not resolve 'session' to a valid POE session\n";
    }
  }
  else {
    $sender_id = $sender->ID();
  }
  $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  $kernel->detach_myself;
  $self->{sender_id} = $sender_id;
  if ( $self->{http_alias} ) {
     my $http_ref = $kernel->alias_resolve( $self->{http_alias} );
     $self->{http_id} = $http_ref->ID() if $http_ref;
  }
  unless ( $self->{http_id} ) {
    $self->{http_id} = 'metabaseclient' . $$ . $self->{session_id};
    my $ka;
    if ( $self->resolver ) {
      $ka = POE::Component::Client::Keepalive->new(
        resolver => $self->resolver,
      );
    }
    POE::Component::Client::HTTP->spawn(
        Alias           => $self->{http_id},
	      FollowRedirects => 2,
        Timeout         => 120,
        Agent           => 'Mozilla/5.0 (X11; U; Linux i686; en-US; '
                . 'rv:1.1) Gecko/20020913 Debian/1.1-1',
        ( defined $ka ? ( ConnectionManager => $ka ) : () ),
    );
    $self->{my_httpc} = 1;
  }
  $kernel->yield( '_submit' );
  return;
}

sub _submit {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $fact = $self->fact;
  my $path = sprintf 'submit/%s', $fact->type;

  $fact->set_creator($self->profile->resource)
    unless $fact->creator;

  my $req_uri = $self->_abs_uri($path);
  my $can_decode = HTTP::Message::decodable;

  my $req = HTTP::Request::Common::POST(
    $req_uri,
    ( length $can_decode ? ('Accept-Encoding' => $can_decode) : () ),
    Content_Type => 'application/json',
    Accept       => 'application/json',
    Content      => JSON->new->encode($fact->as_struct),
  );
  $req->authorization_basic($self->profile->resource->guid, $self->secret->content);

  # Compress it?
  if ( defined $self->compress and $self->compress ne 'none' ) {
    my $err;
    eval { $req->encode( $self->compress ) };
    if ( $@ ) {
      $self->{_error} = "Compression error: $@";
      $self->{success} = 0;
      $kernel->yield( '_dispatch' );
      return;
    }
  }

  $kernel->yield( '_http_req', $req, 'submit' );
  return;
}

sub _guid_exists {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $path = sprintf 'guid/%s', $self->profile->guid;
  my $req_uri = $self->_abs_uri($path);
  my $req = HTTP::Request::Common::HEAD( $req_uri );
  $kernel->yield( '_http_req', $req, 'guid' );
  return;
}

sub _register {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  for my $type ( qw/profile secret/ ) {
    $self->$type->set_creator( $self->$type->resource )
      unless $self->$type->creator;
  }

  my $req_uri = $self->_abs_uri('register');
  my $can_decode = HTTP::Message::decodable;

  my $req = HTTP::Request::Common::POST(
    $req_uri,
    ( length $can_decode ? ('Accept-Encoding' => $can_decode) : () ),
    Content_Type => 'application/json',
    Accept       => 'application/json',
    Content      => JSON->new->encode([
      $self->profile->as_struct, $self->secret->as_struct
    ]),
  );

  $kernel->yield( '_http_req', $req, 'register' );
  return;
}

sub _http_req {
  my ($self,$req,$id) = @_[OBJECT,ARG0,ARG1];
  $poe_kernel->post(
    $self->{http_id},
    'request',
    '_response',
    $req,
    $id,
  );
  return;
}

sub _response {
  my ($kernel,$self,$request_packet,$response_packet) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $tag = $request_packet->[1];
  my $res = $response_packet->[0];
  # and punt an event back to the requesting session
  if ( $tag eq 'submit' and $res->code == HTTP_UNAUTHORIZED ) {
    $kernel->yield( '_guid_exists' );
    return;
  }
  if ( $tag eq 'guid' ) {
    if ( $res->is_success ) {
      $self->{_error} = 'authentication failed';
      $self->{content} = $res->content;
      $kernel->yield( '_dispatch' );
      return;
    }
    $kernel->yield( '_register' );
    return;
  }
  if ( $tag eq 'register' ) {
    unless ( $res->is_success ) {
      $self->{_error} = 'registration failed';
      $self->{content} = $res->content;
      $kernel->yield( '_dispatch' );
      return;
    }
    $kernel->yield( '_submit' );
    return;
  }
  unless ( $res->is_success ) {
    $self->{_error} = "fact submission failed";
  }
  else {
    $self->{success} = 1;
  }

  # decode the content if we requested it
  if ( defined $request_packet->[0]->header( 'Accept-Encoding' ) ) {
    eval { $self->{content} = $res->decoded_content( 'charset' => 'none' ) };
    if ( $@ ) {
      $self->{_error} = "unable to decode content: $@";
      $self->{success} = 0;
    }
  } else {
    $self->{content} = $res->content;
  }
  $kernel->yield( '_dispatch' );
  return;
}

sub _dispatch {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->post( $self->{http_id}, 'shutdown' )
    if $self->{my_httpc};
  my $ref = {};
  for ( qw(_error success context content) ) {
    $ref->{$_} = $self->{$_} if $self->{$_};
  }
  $ref->{error} = delete $ref->{_error} if $ref->{_error};
  $kernel->post( $self->{sender_id}, $self->event, $ref );
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  return;
}

#--------------------------------------------------------------------------#
# private methods
#--------------------------------------------------------------------------#

# Stolen from ::Fact.
# XXX: Should refactor this into something in Fact, which we can then rely on.
# -- rjbs, 2009-03-30
sub __validate_args {
  my ($self, $args, $spec) = @_;
  my $hash = (@$args == 1 and ref $args->[0]) ? { %{ $args->[0]  } }
           : (@$args == 0)                    ? { }
           :                                    { @$args };

  my @errors;

  for my $key (keys %$hash) {
    push @errors, qq{unknown argument "$key" when constructing $self}
      unless exists $spec->{ $key };
  }

  for my $key (grep { $spec->{ $_ } } keys %$spec) {
    push @errors, qq{missing required argument "$key" when constructing $self}
      unless defined $hash->{ $key };
  }

  Carp::confess(join qq{\n}, @errors) if @errors;

  return $hash;
}

sub _abs_uri {
  my ($self, $str) = @_;
  my $req_uri = URI->new($str)->abs($self->uri);
}

sub _error {
  my ($self, $res, $prefix) = @_;
  $prefix ||= "unrecognized error";
  if ( ref($res) && $res->header('Content-Type') eq 'application/json') {
    my $entity = JSON->new->decode($res->content);
    return "$prefix\: $entity->{error}";
  }
  else {
    return "$prefix\: " . $res->message;
  }
}

'Submit this';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Metabase::Client::Submit - a POE client that submits to Metabase servers

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE qw[Component::Metabase::Client::Submit];

  POE::Session->create(
    package_states => [
      'main' => [qw(_start _status)],
    ],
  );

  sub _start {
    POE::Component::Metabase::Client::Submit->submit(
      event   => '_status',
      uri     => 'https://foo.bar.com/metabase/',
      fact    => $metabase_fact_object,
      profile => $metabase_user_profile_object,
      secret  => $metabase_user_secret_object,
    );
    return;
  }

  sub _status {
    my $data = $_[ARG0];

    print "Success!\n" if $data->{success};

    print $data->{error}, "\n" if $data->{error};

    return;
  }

=head1 DESCRIPTION

POE::Component::Metabase::Client::Submit provides a L<POE> mechanism for submitting facts
to a L<Metabase> web server.

=for Pod::Coverage profile secret uri fact event session http_alias context resolver compress

=head1 CONSTRUCTOR

=over

=item C<submit>

  POE::Component::Metabase::Client::Submit->spawn( %args );

Constructs a POE session that will manage submitting a L<Metabase> fact to a L<Metabase> web
server.

Takes a number of mandatory arguments:

 'profile', a Metabase::User::Profile object
 'secret', a Metabase::User::Secret object
 'fact', a Metabase::Fact object
 'event', an event handler in the calling session to invoke on completion
 'uri', the uri of a Metabase server to submit to.

And some optional arguments:

 'session', a session alias, reference or ID to send 'event' to instead of the calling session
 'http_alias', the alias or ID of an existing POE::Component::Client::HTTP session to use.
 'context', anything that can be stored in a scalar that is meaningful to you.
 'resolver', a reference to a POE::Component::Resolver object to use (ignored if http_alias is used).
 'compress', a compressor to use - defaults to none ( available compressors: gzip, deflate, x-bzip2, none )

=back

=head1 OUTPUT EVENT

An event will be sent to either the calling session or the session specified with C<session>
during C<submit>.

C<ARG0> of the event will be a hashref with the following keys:

=over

=item C<success>

Indicates that the submission was successful.

=item C<error>

If there was an error this will contain a string indicating the error that occurred.

=item C<context>

If you specified C<context> in C<submit>, whatever you passed will be here.

=item <content>

This will contain the content of any HTTP responses whether success or failure.

=back

=head1 SEE ALSO

L<Metabase>

L<POE>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Ricardo SIGNES

=item *

David A. Golden

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
