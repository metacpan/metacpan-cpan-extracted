package Net::DNSBLLookup::Result;

use Net::DNSBLLookup;

use strict;

use constant DNSBLLOOKUP_RESULT_OPEN_PROXY => 1;
use constant DNSBLLOOKUP_RESULT_SPAM => 2;
use constant DNSBLLOOKUP_RESULT_UNKNOWN => 3;
use constant DNSBLLOOKUP_RESULT_DYNAMIC_IP => 4;

my %result_type = (
		   DNSBLLOOKUP_OPEN_RELAY() => DNSBLLOOKUP_RESULT_SPAM,
		   DNSBLLOOKUP_DYNAMIC_IP() => DNSBLLOOKUP_RESULT_DYNAMIC_IP,
		   DNSBLLOOKUP_CONFIRMED_SPAM() => DNSBLLOOKUP_RESULT_SPAM,
		   DNSBLLOOKUP_SMARTHOST() => DNSBLLOOKUP_RESULT_SPAM,
		   DNSBLLOOKUP_SPAMHOUSE() => DNSBLLOOKUP_RESULT_SPAM,
		   DNSBLLOOKUP_LISTSERVER() => DNSBLLOOKUP_RESULT_SPAM,
		   DNSBLLOOKUP_FORMMAIL() => DNSBLLOOKUP_RESULT_SPAM,
		   DNSBLLOOKUP_OPEN_PROXY() => DNSBLLOOKUP_RESULT_OPEN_PROXY,
		   DNSBLLOOKUP_OPEN_PROXY_HTTP() => DNSBLLOOKUP_RESULT_OPEN_PROXY,
		   DNSBLLOOKUP_OPEN_PROXY_SOCKS() => DNSBLLOOKUP_RESULT_OPEN_PROXY,
		   DNSBLLOOKUP_OPEN_PROXY_MISC() => DNSBLLOOKUP_RESULT_OPEN_PROXY,
		   DNSBLLOOKUP_HIJACKED() => DNSBLLOOKUP_RESULT_SPAM,
		   DNSBLLOOKUP_MULTI_OPEN_RELAY() => DNSBLLOOKUP_RESULT_SPAM,
		   DNSBLLOOKUP_UNKNOWN() => DNSBLLOOKUP_RESULT_UNKNOWN,
		   );

sub new {
  my ($class) = @_;
  my $self = bless {}, $class;
  $self->{results} = {};
  return $self;
}

sub add {
  my ($self, $dnsbl, $address) = @_;
  my $address_lookup = $Net::DNSBLLookup::dns_servers{$dnsbl};
  if (ref($address_lookup) eq 'HASH') {
    push @{$self->{results}->{$dnsbl}}, $address_lookup->{$address};
  } elsif (ref($address_lookup) eq 'CODE') {
    push @{$self->{results}->{$dnsbl}}, &$address_lookup($address);
  }    
}

sub add_dnsbl {
  my ($self, $dnsbl) = @_;
  $self->{dnsbl_responded}->{$dnsbl} = 1;
}

sub num_proxies_responded {
  my ($self) = @_;
  return scalar(keys %{$self->{dnsbl_responded}});
}

sub breakdown {
  my ($self) = @_;
  my ($total_spam, $total_proxy, $total_unknown) = (0,0,0);
  return unless exists $self->{results};
  while (my ($dnsbl, $v) = each %{$self->{results}}) {
    my ($is_spam, $is_proxy, $is_unknown) = (0,0,0);
    for my $retval (@$v) {
      my $result_type = $result_type{$retval};
      if ($result_type == DNSBLLOOKUP_RESULT_OPEN_PROXY) {
	$is_proxy = 1;
      } elsif ($result_type == DNSBLLOOKUP_RESULT_SPAM) {
	$is_spam = 1;
      } elsif ($result_type == DNSBLLOOKUP_RESULT_UNKNOWN) {
	$is_unknown = 1;
      }
    }
    $total_proxy += $is_proxy;
    $total_spam += $is_spam;
    unless ($is_proxy || $is_spam) {
      $total_unknown += $is_unknown;
    }
  }
  return ($total_proxy, $total_spam, $total_unknown);
}

1;

__END__

=head1 NAME

Net::DNSBLLookup::Result - Analyze the DNS Blocklist lookup results

=head1 SYNOPSIS

  use Net::DNSBLLookup;
  my $dnsbl = Net::DNSBLLookup->new(timeout => 5);
  my $res = $dnsbl->lookup($ip_addr);
  my ($proxy, $spam, $unknown) = $res->breakdown;
  my $num_responded = $res->num_proxies_responded;

=head1 DESCRIPTION

The class represents objects returned by the lookup method of L<Net::DNSBLLookup>.
Currently it supports the breakdown between the number of Open Proxy and Spam hosts, as
well as the number of DNS Blocklist servers that actually responded.

=head1 METHODS

=over 4

=item breakdown

Returns the breakdown between the number of Open Proxy and Spam/Open Relay hosts.
It also returns the number of hits that are unknown - for example the DSBL blocklist
lumps all Open Proxy and Spam results into one code.

  ($proxy, $spam, $unknown) = $res->breakdown;

=item num_responded

Returns the total number of DNS Blocklists that responded to our queries within
C<timeout> seconds or less.

  $num_responded = $res->num_proxies_responded;

=back

=head1 SEE ALSO

L<Net::DNSBLLookup>

=head1 AUTHOR

TJ Mather, E<lt>tjmather@maxmind.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by MaxMind LLC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
