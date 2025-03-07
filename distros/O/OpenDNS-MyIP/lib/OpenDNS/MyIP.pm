package OpenDNS::MyIP;
# ABSTRACT: Get your public IP address
$OpenDNS::MyIP::VERSION = '1.250650';
use 5.006;
use strict;
use warnings;

use Net::DNS;
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

our @ISA = qw(Exporter AutoLoader);
our @EXPORT = qw(get_ip);

sub get_ip{
  my $resolver = new Net::DNS::Resolver(
      nameservers => [ '208.67.220.220', '208.67.222.222' ],
      recurse     => 0,
      debug       => 0
      );

  my $query = $resolver->query( 'myip.opendns.com' );

  if ($query) {
    foreach my $rr ($query->answer) {
      next unless $rr->type eq "A";
      return $rr->rdstring();
    }
  } else {
    confess($resolver->errorstring);
  }
}

1;

=pod

=encoding UTF-8

=head1 NAME

OpenDNS::MyIP - Get your public IP address

=head1 VERSION

version 1.250650

=head1 SYNOPSIS

  use OpenDNS::MyIP qw(get_ip);

  my $ip = get_ip(); # 12.34.56.78

=head1 METHODS

=head2 get_ip()

Return public IP address

=head1 SEE ALSO

L<https://metacpan.org/pod/WWW::IP>

L<https://metacpan.org/pod/WWW::curlmyip>

L<https://metacpan.org/pod/WWW::ipinfo>

L<https://metacpan.org/pod/WWW::hmaip>

L<https://metacpan.org/pod/WWW::PerlTricksIP>

=head1 AUTHOR

Petr Kletecka <pek@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015, 2025 by Petr Kletecka.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

1;
