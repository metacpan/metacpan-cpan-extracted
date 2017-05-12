package POE::Component::IRC::Plugin::URI::Find;
BEGIN {
  $POE::Component::IRC::Plugin::URI::Find::VERSION = '1.10';
}

#ABSTRACT: A POE::Component::IRC plugin that finds URIs in channel traffic

use strict;
use warnings;
use POE;
use POE::Component::IRC::Plugin qw(:ALL);
use URI::Find;

sub new {
  my $package = shift;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  return bless \%args, $package;
}

sub PCI_register {
  my ($self,$irc) = @_;
  $irc->plugin_register( $self, 'SERVER', qw(public ctcp_action) );
  $self->{session_id} = POE::Session->create(
	object_states => [ 
	   $self => [ qw(_shutdown _start _uri_find _uri_found) ],
	],
  )->ID();
  return 1;
}

sub PCI_unregister {
  my ($self,$irc) = splice @_, 0, 2;
  $poe_kernel->call( $self->{session_id} => '_shutdown' );
  delete $self->{irc};
  return 1;
}

sub S_public {
  my ($self,$irc) = splice @_, 0, 2;
  my $who = ${ $_[0] };
  my $channel = ${ $_[1] }->[0];
  my $what = ${ $_[2] };
  $poe_kernel->call( $self->{session_id}, '_uri_find', $irc, $who, $channel, $what );
  return PCI_EAT_NONE;
}

sub S_ctcp_action {
  my ($self,$irc) = splice @_, 0, 2;
  my $who = ${ $_[0] };
  my $channel = ${ $_[1] }->[0];
  my $what = ${ $_[2] };
  my $chantypes = join('', @{ $irc->isupport('CHANTYPES') || ['#', '&']});
  return PCI_EAT_NONE if $channel !~ /^[$chantypes]/;
  $poe_kernel->call( $self->{session_id}, '_uri_find', $irc, $who, $channel, $what );
  return PCI_EAT_NONE;
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  $kernel->refcount_increment( $self->{session_id}, __PACKAGE__ );
  undef;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alarm_remove_all();
  $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ );
  undef;
}

sub _uri_find {
  my ($kernel,$session,$self,$irc,$who,$channel,$what) = @_[KERNEL,SESSION,OBJECT,ARG0..ARG3];
  my $finder = URI::Find->new( $session->callback( '_uri_found', $irc, $who, $channel, $what ) );
  $finder->find( \$what );
  undef;
}

sub _uri_found {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my ($irc,$who,$channel,$what) = @{ $_[ARG0] };
  my ($uriurl,$url) = @{ $_[ARG1] };
  $irc->send_event( 'irc_urifind_uri', $who, $channel, $url, $uriurl, $what );
  undef;
}

q[Find this URL http://cpanidx.org/];


__END__
=pod

=head1 NAME

POE::Component::IRC::Plugin::URI::Find - A POE::Component::IRC plugin that finds URIs in channel traffic

=head1 VERSION

version 1.10

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE qw(Component::IRC Component::IRC::Plugin::URI::Find);
  use Data::Dumper;

  my $nickname = 'UriFind' . $$;
  my $ircname = 'UriFind the Sailor Bot';
  my $ircserver = 'irc.blah.org';
  my $port = 6667;
  my $channel = '#IRC.pm';

  my $irc = POE::Component::IRC->spawn(
        nick => $nickname,
        server => $ircserver,
        port => $port,
        ircname => $ircname,
        debug => 0,
        plugin_debug => 1,
        options => { trace => 0 },
  ) or die "Oh noooo! $!";

  POE::Session->create(
        package_states => [
                'main' => [ qw(_start irc_001 irc_urifind_uri) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    # Create and load our plugin
    $irc->plugin_add( 'UriFind' =>
        POE::Component::IRC::Plugin::URI::Find->new() );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    undef;
  }

  sub irc_001 {
    $irc->yield( join => $channel );
    undef;
  }

  sub irc_urifind_uri {
    my @data = @_[ARG0..ARG4];
    print Dumper( \@data );
    undef;
  }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::URI::Find, is a L<POE::Component::IRC> plugin that parses
public channel traffic for URIs and generates irc events for each URI found.

=for Pod::Coverage  PCI_register
 PCI_unregister
 S_public
 S_ctcp_action

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new plugin object.

=back

=head1 OUTPUT

The following irc event is generated whenever a URI is found in channel text:

=over

=item C<irc_urifind_uri>

With the following parameters:

  ARG0, nick!user@host of the person who said what;
  ARG1, the channel where it was said;
  ARG2, the url found;
  ARG3, the URI::URL object;
  ARG4, what was originally said;

=back

=head1 SEE ALSO

L<POE::Component::IRC>

L<URI::Find>

=head1 AUTHOR

Chris Williams

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

