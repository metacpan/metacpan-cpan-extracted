package NetAddr::IP::Find;

use strict;
use vars qw($VERSION @EXPORT);
$VERSION = '0.03';

use base qw(Exporter);
@EXPORT = qw(find_ipaddrs);

use NetAddr::IP;

my $regex = qr<(\d+)\.(\d+)\.(\d+)\.(\d+)>;

sub find_ipaddrs (\$&) {
    my($r_text, $callback) = @_;
    my $addrs_found = 0;

    $$r_text =~ s{$regex}{
	my $orig_match = join '.', $1, $2, $3, $4;
	if ((my $num_matches = grep { _in_range($_) } $1, $2, $3, $4) == 4) {
	    $addrs_found++;
	    my $ipaddr = NetAddr::IP->new($orig_match);
	    $callback->($ipaddr, $orig_match);
	} else {
	    $orig_match;
	}
    }eg;

    return $addrs_found;
}

sub _in_range {
    return 0 <= $_[0] && $_[0] <= 255;
}


1;
__END__

=head1 NAME

NetAddr::IP::Find - Find IP addresses in plain text

=head1 SYNOPSIS

  use NetAddr::IP::Find;
  $num_found = find_ipaddrs($text, \&callback);

=head1 DESCRIPTION

This is a module for finding IP addresses in plain text.

=head2 Functions

NetAddr::IP::Find exports one function, find_ipaddrs(). It works very
similar to URI::Find's find_uris() or Email::Find's find_emails().

  $num_ipaddrs_found = find_ipaddrs($text, \&callback);

The first argument is a text to search through and manipulate. Second
is a callback routine which defines what to do with each IP address as
they're found. It returns the total number of IP addresses found.

The callback is given two arguments. The first is a NetAddr::IP
instance representing the IP address found. The second is the actual
IP address as found in the text. Whatever the callback returns will
replace the original text.

=head1 EXAMPLES

  # For each IP address found, ping its host to see if its alive.
  use Net::Ping;
  my $pinger = Net::Ping->new;
  my %pinged;
  find_ipaddrs($text, sub {
                   my($ipaddr, $orig) = @_;
                   my $host = $ipaddr->to_string;
                   next if exists $pinged{$host};
                   $pinged{$host} = $pinger->ping($host);
               });

  while (my($host, $up) == each %pinged) {
      print "$host is " . $up ? 'up' : 'down' . "\n";
  }


  # Resolve IP address to FQDN
  find_ipaddrs($text, sub {
                   my($ipaddr, $orig) = @_;
                   resolve_ip($ipaddr->to_string);
               });

  sub resolve_ip {
      use Net::DNS;
      # see perldoc Net::DNS for details
  }

=head1 TODO

=over 4

=item *

Subnet support.

=item *

IPv6 support.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<NetAddr::IP>, L<URI::Find>, L<Email::Find>, jdresove

=cut
