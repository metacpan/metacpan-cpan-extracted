package Net::DNSBLLookup;

use 5.005;
use strict;

require Exporter;
use vars qw($VERSION @EXPORT @ISA);
use Net::DNS;
use IO::Select;
$VERSION = '0.05';
@ISA = qw(Exporter);

@EXPORT = qw(DNSBLLOOKUP_OPEN_RELAY DNSBLLOOKUP_DYNAMIC_IP
	     DNSBLLOOKUP_CONFIRMED_SPAM DNSBLLOOKUP_SMARTHOST DNSBLLOOKUP_SPAMHOUSE DNSBLLOOKUP_LISTSERVER
	     DNSBLLOOKUP_FORMMAIL DNSBLLOOKUP_OPEN_PROXY DNSBLLOOKUP_OPEN_PROXY_HTTP DNSBLLOOKUP_OPEN_PROXY_SOCKS
	     DNSBLLOOKUP_OPEN_PROXY_MISC DNSBLLOOKUP_HIJACKED DNSBLLOOKUP_MULTI_OPEN_RELAY DNSBLLOOKUP_UNKNOWN);

use constant DNSBLLOOKUP_OPEN_RELAY => 1;
use constant DNSBLLOOKUP_DYNAMIC_IP => 2;
use constant DNSBLLOOKUP_CONFIRMED_SPAM => 3;
use constant DNSBLLOOKUP_SMARTHOST => 4;
use constant DNSBLLOOKUP_SPAMHOUSE => 5;
use constant DNSBLLOOKUP_LISTSERVER => 6;
use constant DNSBLLOOKUP_FORMMAIL => 7;
use constant DNSBLLOOKUP_OPEN_PROXY => 8;
use constant DNSBLLOOKUP_OPEN_PROXY_HTTP => 9;
use constant DNSBLLOOKUP_OPEN_PROXY_SOCKS => 10;
use constant DNSBLLOOKUP_OPEN_PROXY_MISC => 11;
use constant DNSBLLOOKUP_HIJACKED => 12;
use constant DNSBLLOOKUP_MULTI_OPEN_RELAY => 13;
use constant DNSBLLOOKUP_UNKNOWN => 14;

require Net::DNSBLLookup::Result;

%Net::DNSBLLookup::dns_servers = (

# no longer implemented, since osirusoft.com was taken offline due
# to DDos attacks from spammers

#		   'relays.osirusoft.com' => {
#		     '127.0.0.2' => DNSBLLOOKUP_OPEN_RELAY,
#		     '127.0.0.3' => DNSBLLOOKUP_DYNAMIC_IP, # dialup
#		     '127.0.0.4' => DNSBLLOOKUP_CONFIRMED_SPAM,
#		     '127.0.0.5' => DNSBLLOOKUP_SMARTHOST,
#		     '127.0.0.6' => DNSBLLOOKUP_SPAMHOUSE,
#		     '127.0.0.7' => DNSBLLOOKUP_LISTSERVER,
#		     '127.0.0.8' => DNSBLLOOKUP_FORMMAIL,
#		     '127.0.0.9' => DNSBLLOOKUP_OPEN_PROXY,
#		   },
		   'dnsbl.sorbs.net' => {
		     '127.0.0.2' => DNSBLLOOKUP_OPEN_PROXY_HTTP,
		     '127.0.0.3' => DNSBLLOOKUP_OPEN_PROXY_SOCKS,
		     '127.0.0.4' => DNSBLLOOKUP_OPEN_PROXY_MISC,
		     '127.0.0.5' => DNSBLLOOKUP_OPEN_RELAY,
		     '127.0.0.6' => DNSBLLOOKUP_SPAMHOUSE,
		     '127.0.0.7' => DNSBLLOOKUP_FORMMAIL,
		     '127.0.0.8' => DNSBLLOOKUP_CONFIRMED_SPAM,
		     '127.0.0.9' => DNSBLLOOKUP_HIJACKED,
		     '127.0.0.10' => DNSBLLOOKUP_DYNAMIC_IP, # not same as dialup
		   },
		   'proxies.blackholes.easynet.net' => {
		     '127.0.0.2' => DNSBLLOOKUP_OPEN_PROXY,
		   },
		   'dnsbl.njabl.org' => {
		     '127.0.0.2' => DNSBLLOOKUP_OPEN_RELAY,
		     '127.0.0.3' => DNSBLLOOKUP_DYNAMIC_IP,
		     '127.0.0.4' => DNSBLLOOKUP_SPAMHOUSE,
		     '127.0.0.5' => DNSBLLOOKUP_MULTI_OPEN_RELAY,
		     '127.0.0.8' => DNSBLLOOKUP_FORMMAIL,
		     '127.0.0.9' => DNSBLLOOKUP_OPEN_PROXY,
		   },
#		   'list.dsbl.org' => {
#		     '127.0.0.2' => DNSBLLOOKUP_UNKNOWN,
#		   },
#		   'opm.blitzed.org' => sub {
#		     my ($ip) = @_;
#		     # todo deal with bitmasks properly
#		     # see http://opm.blitzed.org/info
#		     return DNSBLLOOKUP_OPEN_PROXY;
#		   },
		   'cbl.abuseat.org' => {
		     '127.0.0.2' => DNSBLLOOKUP_OPEN_PROXY,
		   },
		   'psbl.surriel.com' => {
		     '127.0.0.2' => DNSBLLOOKUP_OPEN_PROXY,
		   },
		   );

sub new {
  my ($class) = shift;
  my $self = { @_ };
  bless $self, $class;
  unless (exists $self->{zones}) {
    @{$self->{zones}} = grep !/^relays\.osirusoft\.com$/, keys %Net::DNSBLLookup::dns_servers;
  }
  $self->{timeout} ||= 5;
  return $self;
}

sub lookup {
  my ($self, $ip) = @_;

  my $res = Net::DNS::Resolver->new;
  my $sel = IO::Select->new;
  my @sockets;

  my $result = Net::DNSBLLookup::Result->new();

  my $reverse_ip = join('.',reverse split('\.',$ip));

  for my $zone (@{$self->{zones}}) {
    my $host = join('.',$reverse_ip,$zone);
    my $socket = $res->bgsend($host);
    $sel->add($socket);
    undef $socket;
  }

  while ($sel->count > 0) {
    my @ready = $sel->can_read($self->{timeout});
    last unless @ready;
    foreach my $sock (@ready) {
      my $packet = $res->bgread($sock);
      my ($question) = $packet->question;
      next unless $question;
      my $qname = $question->qname;
      (my $dnsbl = $qname) =~ s!^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\.!!;
      $result->add_dnsbl($dnsbl);
      foreach my $rr ($packet->answer) {
	next unless $rr->type eq "A";
	$result->add($dnsbl, $rr->address);
      }
      $sel->remove($sock);
    }
  }
  return $result;
}

1;
__END__

=head1 NAME

Net::DNSBLLookup - Lookup IP Address in Open Proxy and SPAM DNS Blocklists

=head1 SYNOPSIS

  use Net::DNSBLLookup;
  my $dnsbl = Net::DNSBLLookup->new(timeout => 5);
  my $res = $dnsbl->lookup($ip_addr);
  my ($proxy, $spam, $unknown) = $res->breakdown;
  my $num_responded = $res->num_proxies_responded;

=head1 ABSTRACT

This module queries the major Open Proxy DNS Blocklists, including Sorbs,
Easynet, NJABL, DSBL, Blitzed, CBL and PSBL.  Open Proxies are servers that allow
hackers to mask their true IP address.  Some of these blocklists also contain 
hosts that have been known to send spam.  This module distinguishes the
results between Open Proxy and Spam/Open Relay servers.

=head1 DESCRIPTION

This module can be used to block or flag Internet connections coming from
Open Proxy or Spam servers.  Why would you want to do this?  Hackers often
use Open Proxy servers to hide their true IP address when doing "bad" stuff.
This includes using purchasing stuff with stolen credit cards, and getting
around IP Address based restrictions

=head1 METHODS

=over 4

=item new

Calls C<new()> to create a new DNSBLLookup object:

  $dnsbl = new Net::DNSBLLookup(timeout => 5);

Takes timeout as an argument, defaults to 5 seconds if not specified.  The module
waits C<timeout> seconds before giving up on a slow DNS host.

=item lookup

This sends out a lookup to the major DNS Blocklists, and waits up to C<timeout>
seconds then returns the results:

  $res = $dnsbl->lookup($ip_addr);

=back

=head1 SEE ALSO

L<Net::DNSBLLookup::Result>

There is a free credit card fraud prevention service that
uses this module located at
L<http://www.maxmind.com/app/ccv>

=head1 AUTHOR

TJ Mather, E<lt>tjmather@maxmind.comE<gt>

Paid support is available from directly from the author of this package.
Please see L<http://www.maxmind.com/app/opensourceservices> for more details.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Maxmind LLC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
