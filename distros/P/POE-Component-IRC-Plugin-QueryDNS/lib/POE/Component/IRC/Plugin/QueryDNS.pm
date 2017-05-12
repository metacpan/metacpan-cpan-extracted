package POE::Component::IRC::Plugin::QueryDNS;
{
  $POE::Component::IRC::Plugin::QueryDNS::VERSION = '1.04';
}

#ABSTRACT: A POE::Component::IRC plugin for IRC based DNS queries

use strict;
use warnings;
use POE;
use POE::Component::Client::DNS;
use POE::Component::IRC::Plugin qw(:ALL);
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
  unless ( $self->{resolver} ) {
     $self->{resolver} = POE::Component::Client::DNS->spawn();
     $self->{_mydns} = 1;
  }
  return 1;
}

sub PCI_unregister {
  my $self = shift;
  return 1 unless $self->{_mydns};
  $self->{resolver}->shutdown();
  delete $self->{resolver};
  return 1;
}

sub S_public {
  my ($self,$irc) = splice @_, 0 , 2;
  my ($nick,$userhost) = ( split /!/, ${ $_[0] } )[0..1];
  my $channel = ${ $_[1] }->[0];
  my $what = ${ $_[2] };
  my $mynick = $irc->nick_name();
  my $cmdstr = $self->{command} || 'dns';
  my ($command) = $what =~ m/^\s*\Q$mynick\E[\:\,\;\.]?\s*(.*)$/i;
  return PCI_EAT_NONE unless ( $command and $command =~ /^\Q$cmdstr\E/i );
  $self->_dns_query( $irc, $channel, 'privmsg', split(/\s+/, $command) );
  return PCI_EAT_NONE;
}

sub S_msg {
  my ($self,$irc) = splice @_, 0 , 2;
  my ($nick,$userhost) = ( split /!/, ${ $_[0] } )[0..1];
  my $string = ${ $_[2] };
  my $cmdstr = $self->{command} || 'dns';
  return PCI_EAT_NONE unless ( $string and $string =~ /^\Q$cmdstr\E\s+/i );
  $self->_dns_query( $irc, $nick, ( $self->{privmsg} ? 'privmsg' : 'notice' ), split(/\s+/, $string) );
  return PCI_EAT_NONE;
}

sub _dns_query {
  my ($self,$irc,$target,$method,$cmdstr,$query,$type) = @_;
  return unless $cmdstr and $query;
  $poe_kernel->state( '_querydns_response', $self, '_response' );
  $type = 'A' unless $type and $type =~ /^(A|CNAME|NS|MX|PTR|TXT|AAAA|SRV|SOA)$/i;
  $type = 'PTR' if ip_is_ipv4( $query );
  my $response = $self->{resolver}->resolve(
	event => '_querydns_response',
	host => $query,
	type => $type,
	context => { targ => $target, meth => $method, irc => $irc },
  );
  $poe_kernel->yield( '_querydns_response', $response ) if $response;
  return 1;
}

sub _response {
  my $response = $_[ARG0];
  my $target = $response->{context}->{targ};
  my $method = $response->{context}->{meth};
  my $irc = $response->{context}->{irc};
  if ( !$response->{response} ) {
     $irc->yield( $method, $target, 'Thanks, that generated an error!' );
  }
  else {
     my @answers;
     foreach my $ans ( $response->{response}->answer() ) {
	if ( $ans->type() eq 'SOA' ) {
	   push @answers, 'SOA=' . join(':', $ans->mname, $ans->rname, $ans->serial, $ans->refresh, $ans->retry, $ans->expire, $ans->minimum );
	}
	else {
	   push @answers, join('=', $ans->type(), $ans->rdatastr() );
	}
     }
     if ( @answers ) {
	$irc->yield( $method, $target, $response->{host} . ' [ ' . join(' ', @answers) . ' ]' );
     }
     else {
	$irc->yield( $method, $target, 'No answers for ' . $response->{host} );
     }
  }
  $poe_kernel->state( '_querydns_response' );
  return;
}

1;


__END__
=pod

=head1 NAME

POE::Component::IRC::Plugin::QueryDNS - A POE::Component::IRC plugin for IRC based DNS queries

=head1 VERSION

version 1.04

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE qw(Component::IRC Component::IRC::Plugin::QueryDNS);

  my $nickname = 'qdns' . $$;
  my $ircname = 'QueryDNS Bot';
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
    # Create and load our QueryDNS plugin
    $irc->plugin_add( 'QueryDNS' =>
        POE::Component::IRC::Plugin::QueryDNS->new() );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    undef;
  }

  sub irc_001 {
    $irc->yield( join => $channel );
    undef;
  }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::QueryDNS is a L<POE::Component::IRC> plugin that provides DNS query
facilities to the channels it occupies and via private messaging.

It uses L<POE::Component::Client::DNS> to do non-blocking DNS queries. By default the plugin attempts
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

  'command', define the command that will trigger DNS queries, default is 'dns';
  'privmsg', set to a true value to specify that the bot should reply with PRIVMSG instead of
	     NOTICE to privmsgs that it receives.
  'resolver', specify a POE::Component::Client::DNS object that the plugin should use,
	      the default is to try and use POE::Component::IRC's resolver;

=back

=head1 IRC USAGE

The bot replies to requests in the following form, when addressed:

  dns <query> <optional_type>

Of course, if you changed the C<command> in the constructor it will be something different to C<dns>.

C<query> maybe a hostname, a zone, an IP address, anything that you want to query DNS for.

C<type> can be C<A>, C<PTR>, C<CNAME>, C<NS>, C<MX>, C<TXT>, C<AAAA>, C<SRV> or C<SOA>. If it isn't specified the default is
C<A> unless the C<query> is an IP address in which case the default is C<PTR>.

Some examples:

   # No type, defaults to 'A'
   < you> bot: dns www.perl.org
   < bot> www.perl.org [ CNAME=x3.develooper.com. A=63.251.223.163 ]

   # No type, defaults to 'PTR' because the query is an IP address
   < you> bot: dns 63.251.223.163
   < bot> 63.251.223.163 [ PTR=x3.develooper.com. ]

   # Specify a type of 'MX'
   < you> bot: dns perl.org mx
   < bot> perl.org [ MX=5 mx.develooper.com. ]

   # Specify a type of 'TXT'
   < you> bot: dns perl.org txt
   < bot> No answers for perl.org

   # Specify a type of 'SOA'
   < you> bot: dns perl.org soa
   < bot> perl.org [ SOA=ns1.us.bitnames.com:dnsoper.bitnames.com:2008011304:5400:5400:604800:300 ]

=head1 SEE ALSO

L<POE::Component::Client::DNS>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

