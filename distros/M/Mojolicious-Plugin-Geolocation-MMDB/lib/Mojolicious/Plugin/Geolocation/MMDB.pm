package Mojolicious::Plugin::Geolocation::MMDB;
use Mojo::Base 'Mojolicious::Plugin';

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

our $VERSION = 0.001;

use Carp qw(croak);
use IP::Geolocation::MMDB;

sub register {
  my ($self, $app, $conf) = @_;

  my $file = $conf->{file} or croak q{The "file" parameter is mandatory};

  my $mmdb = IP::Geolocation::MMDB->new(file => $file);

  $app->helper(geolocation => sub {
    my ($c, $ip_address) = @_;

    if (!defined $ip_address) {
      $ip_address = $c->tx->remote_address;
    }

    my $data;
    if ($ip_address) {
      $data = $mmdb->record_for_address($ip_address);
    }

    return $data;
  });

  return;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Geolocation::MMDB - Look up location information by IP address

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Mojolicious::Lite -signatures;

  plugin 'Geolocation::MMDB', {file => 'Country.mmdb'};

  get '/' => sub ($c) {
    my $location = $c->geolocation;
    my $country =
      eval { $location->{country}->{names}->{en} } // 'unknown location';
    $c->render(text => "Welcome visitor from $country");
  };

  app->start;

=head1 DESCRIPTION

This L<Mojolicious> plugin provides a helper that maps IPv4 and IPv6 addresses
to location information such as country and city names.

=head1 HELPERS

=head2 geolocation

  my $request_location   = $c->geolocation;
  my $arbitrary_location = $c->geolocation('1.2.3.4');

If no IP address is given, the location of the current transaction's remote
address is looked up.  Otherwise, the specified IP address is looked up.
Returns the undefined value if no location information is available for the IP
address.

=head1 SUBROUTINES/METHODS

=head2 register

  $plugin->register(Mojolicious->new, {file => 'City.mmdb'});

Registers the plugin in a Mojolicious application.  The "file" parameter is
required.

=head1 DIAGNOSTICS

=over

=item B<< The "file" parameter is mandatory >>

The plugin was loaded without a database filename.

=back

=head1 CONFIGURATION AND ENVIRONMENT

If your application is behind a reverse proxy, the environment variable
C<MOJO_REVERSE_PROXY> needs to bet set.  See L<Mojolicious::Guides::Cookbook>
for more information.

=head1 DEPENDENCIES

Requires the Perl modules L<Mojolicious> and L<IP::Geolocation::MMDB> from
CPAN.

Requires an IP to country, city or ASN database in the MaxMind DB file format
from L<MaxMind|https://www.maxmind.com/> or L<DP-IP.com|https://db-ip.com/>.

=head1 INCOMPATIBILITIES

None.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

None known.

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
