package Params::Validate::Checks::Net;

=head1 NAME

Params::Validate::Checks::Net - Params::Validate checks for functions taking
network-related arguments

=head1 SYNOPSIS

  use Params::Validate::Checks qw<validate as>;
  use Params::Validate::Checks::Net;

  sub configure_website
  {
    my %arg = validate @_,
    {
      website => {as 'domain'},
      nameserver => {as 'domain'},
      ip_address => {as 'public_ip_address'},
    };

    # Do something with $arg{website}, $arg{nameserver}, $arg{ip_address} ...
  }

  sub check_network
  {
    my %arg = validate @_.
    {
      device => {as 'hostname'},
      mac_address => {as 'mac_address'},
      timeout => {as 'pos_int', default => 10},
    };

    # Do something with $arg{device}, $arg{mac_address}, $arg{timeout} ...
  }

=cut


use warnings;
use strict;

use Params::Validate::Checks;

use Data::Validate::Domain 0.02 qw<is_domain is_hostname>;
use Data::Validate::IP qw<is_ipv4 is_public_ipv4>;
use Regexp::Common qw<net>;


our $VERSION = 0.01;


=head1 DESCRIPTION

This is a library of named checks for use with L<Params::Validate> to validate
function and method arguments that should be networky things: domain names,
hostnames, IP addresses, or mac addresses.  See L<Params::Validate::Checks> for
details of the overall system.

=head2 Checks

The following named checks are supplied by this module.  In all cases only the
syntax is checked, not that the entity in question actually exists on the
network:

=over

=item C<domain>

an internet domain name, such as "123-reg.co.uk"; it must having a known
top-level domain (such as ".uk")

=item C<hostname>

an internet hostname; this includes all domain names but also unqualified
hostnames like "www1", which may be valid on internal networks

=item C<ip_address>

an IP address (version 4), such as "212.100.234.56"

=item C<public_ip_address>

like C<ip_address>, but excluding addresses such as "192.168.0.42" which are
internal-only, not publicly reachable over the internet

=item C<mac_address>

the mac address of a network device, such as "00:0E:35:17:F3:4E"

=back

Feedback is welcome on further checks that should be added.

=cut


Params::Validate::Checks::register
  domain => \&is_domain,
  hostname => \&is_hostname,
  ip_address => \&is_ipv4,
  public_ip_address => \&is_public_ipv4,
  mac_address => qr/^$RE{net}{MAC}\z/,
;


=head1 SEE ALSO

=over 2

=item *

L<Params::Validate::Checks>, the framework this is using

=item *

L<Data::Validate::Domain>, provider of the domain name and hostname checks

=item *

L<Data::Validate::IP>, provider of the IP address checks

=item *

L<Regexp::Common>, provider of the mac address check

=back

=head1 CREDITS

Written and maintained by Smylers <smylers@cpan.org>

Thanks to the authors and maintainers of the above modules that are doing the
actual syntax checks.

=head1 COPYRIGHT & LICENCE

Copyright 2006-2008 by Smylers.

This library is software libre; you may redistribute it and modify it under the
terms of any of these licences:

=over 2

=item *

L<The GNU General Public License, version 2|perlgpl>

=item *

The GNU General Public License, version 3

=item *

L<The Artistic License|perlartistic>

=item *

The Artistic License 2.0

=back

=cut


1;
