package POE::Component::CPANIDX;
$POE::Component::CPANIDX::VERSION = '0.12';
#ABSTRACT: A POE mechanism for querying the CPANIDX

use strict;
use warnings;
use Carp;
use POE qw(Component::Client::HTTP);
use YAML::Tiny;
use HTTP::Request::Common;
use File::Spec::Unix;

my $cmds = {
  mod       => 1,
  dist      => 1,
  auth      => 1,
  corelist  => 1,
  dists     => 1,
  timestamp => 0,
  topten    => 0,
  mirrors   => 0,
};

# Stolen from POE::Wheel. This is static data, shared by all
my $current_id = 0;
my %active_identifiers;

sub _allocate_identifier {
  while (1) {
    last unless exists $active_identifiers{ ++$current_id };
  }
  return $active_identifiers{$current_id} = $current_id;
}

sub _free_identifier {
  my $id = shift;
  delete $active_identifiers{$id};
}

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
  object_states => [
     $self => { shutdown     => '_shutdown',
                query_idx    => '_query_idx',
     },
     $self => [ qw(_start _query_idx _dispatch _http_request _http_response) ],
  ],
  heap => $self,
  ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'shutdown' );
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
     $kernel->alias_set( $self->{alias} );
  }
  else {
     $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  $self->{_httpc} = 'httpc-' . $self->{session_id};
  POE::Component::Client::HTTP->spawn(
     Alias           => $self->{_httpc},
     FollowRedirects => 2,
  );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $self->{_shutdown} = 1;
  $kernel->post( $self->{_httpc}, 'shutdown' );
  undef;
}

sub query_idx {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, '_query_idx', @_ );
}

sub _query_idx {
  my ($kernel,$self,$state) = @_[KERNEL,OBJECT,STATE];
  my $sender = $_[SENDER]->ID();
  return if $self->{_shutdown};
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
  $args = { %{ $_[ARG0] } };
  } else {
  $args = { @_[ARG0..$#_] };
  }

  $args->{lc $_} = delete $args->{$_} for grep { $_ !~ /^_/ } keys %{ $args };

  unless ( $args->{event} ) {
    warn "No 'event' specified for $state";
    return;
  }

  croak
  "You must provide a valid 'url' of a CPANIDX site"
     unless $args->{url} and URI->new($args->{url}) and URI->new($args->{url})->scheme eq 'http';

  $args->{cmd} = 'timestamp' unless $args->{cmd};
  $args->{cmd} = lc $args->{cmd};

  my $arg = $cmds->{ $args->{cmd} };

  croak
  "'cmd' that was specified is unknown"
    unless defined $arg;

  croak
  "'cmd' requires that you specify a 'search' term"
    if $arg and !$args->{search};

  $args->{sender} = $sender;
  $kernel->refcount_increment( $sender => __PACKAGE__ );
  $kernel->yield( '_http_request', $args );

  return;
}

sub _http_request {
  my ($kernel,$self,$req) = @_[KERNEL,OBJECT,ARG0];
  my $url = URI->new( $req->{url} );

  $url->path( File::Spec::Unix->catfile( $url->path, 'yaml', $req->{cmd}, ( $req->{search} ? $req->{search} : () ) ) );

  my $id = _allocate_identifier();

  $kernel->post(
    $self->{_httpc},
    'request',
    '_http_response',
    GET( $url->as_string ),
    "$id",
  );

  $self->{_requests}->{ $id } = $req;
  return;
}

sub _http_response {
  my ($kernel,$self,$request_packet,$response_packet) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $id = $request_packet->[1];
  my $req = delete $self->{_requests}->{ $id };
  _free_identifier( $id );
  my $resp = $response_packet->[0];
  if ( $resp->is_success ) {
        my $data;
        eval { $data = YAML::Tiny::Load( $resp->content ); };
        unless ( $data ) {
          $req->{error} = 'No valid YAML data was found';
          $kernel->yield( '_dispatch', $req );
          return;
        }
        $req->{data} = $data;
  }
  else {
        $req->{error} = $resp->as_string;
  }

  $kernel->yield( '_dispatch', $req );
  return;
}

sub _dispatch {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  my $session = delete $input->{sender};
  my $event = delete $input->{event};
  $kernel->post( $session, $event, $input );
  $kernel->refcount_decrement( $session => __PACKAGE__ );
  return;
}

qq[CAPTCH!];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::CPANIDX - A POE mechanism for querying the CPANIDX

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE qw(Component::CPANIDX);

  my $url = shift or die;
  my $cmd = shift or die;
  my $search = shift;

  my $idx = POE::Component::CPANIDX->spawn();

  POE::Session->create(
    package_states => [
      main => [qw(_start _reply)],
    ],
    args => [ $url, $cmd, $search ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($URL,$CMD,$SRCH) = @_[ARG0..ARG2];

    $idx->query_idx(
      event  => '_reply',
      url    => $URL,
      cmd    => $CMD,
      search => $SRCH,
    );

    return;
  }

  sub _reply {
    my $resp = $_[ARG0];

    use Data::Dumper;
    $Data::Dumper::Indent=1;

    unless ( $resp->{error} ) {
       print Dumper( $resp->{data} );
    }
    else {
       print Dumper( $resp->{error} );
    }
    $idx->shutdown;
    return;
  }

=head1 DESCRIPTION

POE::Component::CPANIDX is a L<POE> component for querying web servers that are running
L<App::CPANIDX>.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Creates a new POE::Component::CPANIDX session.

Takes one optional argument C<alias> so you can set an alias on the component
to send it events later.

Returns an object reference which the following methods can be used on.

=back

=head1 METHODS

=over

=item C<session_id>

Takes no arguments. Returns the L<POE::Session> ID of the component.

=item C<shutdown>

Takes no arguments. Terminates the component.

=item C<query_idx>

=over

=item C<event>

The name of the C<event> that should be sent to the requesting session with the reply from
the CPANIDX server. This is required.

=item C<url>

The base url of the website that is running L<App::CPANIDX>. This is required.

=item C<cmd>

The query command to send to the server. This can be C<mod>, C<dist>, C<dists>, C<corelist>, C<auth>, C<timestamp>
C<mirrors> or C<topten>. If no C<cmd> is specified the component will default to C<timestamp>. The first
three commands require a C<search> term.

=item C<search>

The search term to use for the C<mod>, C<dist>, C<dists>, C<auth>, C<corelist> commands.

=back

See C<OUTPUT EVENTS> below for what will be sent to your session in reply.

You may also set arbitary keys to pass arbitary data along with your request. These must be
prefixed with an underscore C<_>.

=back

=head1 INPUT EVENTS

These are POE events that the component will accept.

=over

=item C<shutdown>

Takes no arguments. Terminates the component.

=item C<query_idx>

=over

=item C<event>

The name of the C<event> that should be sent to the requesting session with the reply from
the CPANIDX server. This is required.

=item C<url>

The base url of the website that is running L<App::CPANIDX>. This is required.

=item C<cmd>

The query command to send to the server. This can be C<mod>, C<dists>, C<auth>, C<timestamp>
or C<topten>. If no C<cmd> is specified the component will default to C<timestamp>. The first
three commands require a C<search> term.

=item C<search>

The search term to use for the C<mod>, C<dists>, C<auth> commands.

=back

See C<OUTPUT EVENTS> below for what will be sent to your session in reply.

You may also set arbitary keys to pass arbitary data along with your request. These must be
prefixed with an underscore C<_>.

=back

=head1 OUTPUT EVENTS

The component will send an event in response to C<query_idx>. C<ARG0> of the event will be
a C<HASHREF> containing the key/values of the original request ( including any arbitary key/values passed ).
It will also contain either a C<data> key or an C<error> key.

=over

=item C<data>

This will an arrayref of the data returned by the CPANIDX site. If there was no data to return then
this will be a 'blank' arrayref.

=item C<error>

If there was an error of some sort then C<data> will not be defined and this will contain a message
indicating what the problem was.

=back

=head1 SEE ALSO

L<App::CPANIDX>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
