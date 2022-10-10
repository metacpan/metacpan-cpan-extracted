package Power::Outlet::Common::IP::HTTPS;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP};

our $VERSION = '0.46';

=head1 NAME

Power::Outlet::Common::IP::HTTPS - Power::Outlet base class for HTTPS power outlet

=head1 SYNOPSIS

  use base qw{Power::Outlet::Common::IP::HTTPS};

=head1 DESCRIPTION
 
Power::Outlet::Common::IP::HTTPS is a package for controlling and querying an HTTPS-based network attached power outlet.

=head1 USAGE

  use base qw{Power::Outlet::Common::IP::HTTPS};

=head1 METHODS

=head2 url

Returns a configured L<URI::http> object

=head1 PROPERTIES

All properties from Power::Outlet::Common::IP::HTTP with these default differences

=head2 http_scheme

Set and returns the http_scheme property

Default: https

=cut

sub _http_scheme_default {'https'};   #see Power::Outlet::Common::IP::HTTP

=head2 port

Set and returns the port property

Default: 443

=cut

sub _port_default {'443'};         #see Power::Outlet::Common::IP

sub _http_path_default {'/'};      #see Power::Outlet::Common::IP::HTTP

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<URI>, L<HTTP::Tiny>

=cut

1;
