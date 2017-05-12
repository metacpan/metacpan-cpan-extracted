package POE::Component::IRC::Plugin::QueryDNSBL;
{
  $POE::Component::IRC::Plugin::QueryDNSBL::VERSION = '1.04';
}

#ABSTRACT: A POE::Component::IRC plugin for IRC based DNSBL queries

use strict;
use warnings;
use POE;
use POE::Component::Client::DNSBL;
use POE::Component::IRC::Plugin qw[:ALL];
use Net::IP::Minimal qw[ip_is_ipv4];

sub new {
  my $package = shift;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  delete $args{resolver}
	unless ref $args{resolver} and $args{resolver}->isa('POE::Component::Client::DNS');
  bless \%args, $package;
}

sub PCI_register {
  my ($self,$irc) = @_;
  $irc->plugin_register( $self, 'SERVER', qw(public msg) );
  $self->{resolver} = $irc->resolver();
  $self->{_dnsbl} = POE::Component::Client::DNSBL->spawn(
	resolver => $self->{resolver},
	dnsbl => $self->{dnsbl},
  );
  return 1;
}

sub PCI_unregister {
  my $self = shift;
  $self->{_dnsbl}->shutdown();
  return 1;
}

sub S_public {
  my ($self,$irc) = splice @_, 0 , 2;
  my ($nick,$userhost) = ( split /!/, ${ $_[0] } )[0..1];
  my $channel = ${ $_[1] }->[0];
  my $what = ${ $_[2] };
  my $mynick = $irc->nick_name();
  my $cmdstr = $self->{command} || 'dnsbl';
  my ($command) = $what =~ m/^\s*\Q$mynick\E[\:\,\;\.]?\s*(.*)$/i;
  return PCI_EAT_NONE unless ( $command and $command =~ /^\Q$cmdstr\E/i );
  $self->_dns_query( $irc, $channel, 'privmsg', split(/\s+/, $command) );
  return PCI_EAT_NONE;
}

sub S_msg {
  my ($self,$irc) = splice @_, 0 , 2;
  my ($nick,$userhost) = ( split /!/, ${ $_[0] } )[0..1];
  my $string = ${ $_[2] };
  my $cmdstr = $self->{command} || 'dnsbl';
  return PCI_EAT_NONE unless ( $string and $string =~ /^\Q$cmdstr\E\s+/i );
  $self->_dns_query( $irc, $nick, ( $self->{privmsg} ? 'privmsg' : 'notice' ), split(/\s+/, $string) );
  return PCI_EAT_NONE;
}

sub _dns_query {
  my ($self,$irc,$target,$method,$cmdstr,$query,$type) = @_;
  return unless $cmdstr and $query;
  unless ( ip_is_ipv4( $query ) ) {
     $irc->yield( $method, $target, 'That isn\'t an IPv4 address' );
     return;
  }
  $poe_kernel->state( '_querydnsbl_response', $self, '_response' );
  $self->{_dnsbl}->lookup(
	event => '_querydnsbl_response',
	address => $query,
	_context => { targ => $target, meth => $method, irc => $irc },
  );
  return 1;
}

sub _response {
  my $response = $_[ARG0];
  my $target = $response->{_context}->{targ};
  my $method = $response->{_context}->{meth};
  my $irc = $response->{_context}->{irc};
  if ( $response->{error} ) {
     $irc->yield( $method, $target, 'Thanks, that generated an error!' );
  }
  else {
     if ( $response->{response} eq 'NXDOMAIN' ) {
	$irc->yield( $method, $target, 'That address is not blacklisted.' );
     }
     else {
	$irc->yield( $method, $target, join(' ', $response->{response}, ( $response->{reason} ? "[$response->{reason}]" : '' ) ) );
     }
  }
  $poe_kernel->state( '_querydnsbl_response' );
  return;
}

1;


__END__
=pod

=head1 NAME

POE::Component::IRC::Plugin::QueryDNSBL - A POE::Component::IRC plugin for IRC based DNSBL queries

=head1 VERSION

version 1.04

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE qw(Component::IRC Component::IRC::Plugin::QueryDNSBL);

  my $nickname = 'qdnsbl' . $$;
  my $ircname = 'QueryDNSBL Bot';
  my $ircserver = $ENV{IRCSERVER} || 'irc.bleh.net';
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
                'main' => [ qw(_start irc_001) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    # Create and load our QueryDNSBL plugin
    $irc->plugin_add( 'QueryDNSBL' =>
        POE::Component::IRC::Plugin::QueryDNSBL->new() );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    undef;
  }

  sub irc_001 {
    $irc->yield( join => $channel );
    undef;
  }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::QueryDNS is a L<POE::Component::IRC> plugin that provides DNSBL query
facilities to the channels it occupies and via private messaging.

It uses L<POE::Component::Client::DNSBL> to do non-blocking DNSBL queries. By default the plugin attempts
to use L<POE::Component::IRC>'s internal PoCo-Client-DNS resolver object, but will spawn its own copy.
You can supply your own resolver object via the constructor.

=for Pod::Coverage   PCI_register
  PCI_unregister
  S_public
  S_msg

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new plugin object. Takes some optional parameter:

  'command', define the command that will trigger DNSBL queries, default is 'dnsbl';
  'privmsg', set to a true value to specify that the bot should reply with PRIVMSG instead of
	     NOTICE to privmsgs that it receives.
  'resolver', specify a POE::Component::Client::DNS object that the plugin should use,
	      the default is to try and use POE::Component::IRC's resolver;
  'dnsbl', the DNSBL zone to send queries to, default zen.spamhaus.org;

=back

=head1 IRC USAGE

The bot replies to requests in the following form, when addressed:

  dnsbl <ipv4_address>

Of course, if you changed the C<command> in the constructor it will be something different to C<dns>.

=head1 SEE ALSO

L<POE::Component::Client::DNSBL>

L<http://en.wikipedia.org/wiki/DNSBL>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

