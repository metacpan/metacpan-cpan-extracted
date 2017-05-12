use warnings;
use strict;

package Net::Whois::SIDN::Util;
use base 'Exporter';

our @EXPORT      = qw/NS_WHOIS_DRS50/;

our %EXPORT_TAGS = ( constants => [ qw/NS_WHOIS_DRS50/ ] );

=head1 NAME

Net::Whois::SIDN::Util - SIDN useful constants

=head1 SYNOPSIS

  use Net::Whois::SIDN::Util ':constants';

=head1 DESCRIPTION

Helper functions and constants, available to applications which
use L<Net::Whois::SIDN> objects.

=head1 FUNCTIONS

=head2 Constants

Defines only C<NS_WHOIS_DRS50>

=cut

use constant
  { NS_WHOIS_DRS50 => 'http://rxsd.domain-registry.nl/sidn-whois-drs50'
  };

1;
