# ABSTRACT: Type library for OpenSky::API

package OpenSky::API::Types;
our $VERSION = '0.004';
use Type::Library
  -base,
  -declare => qw(
  Longitude
  Latitude
  );

use Type::Utils -all;

BEGIN {
    extends qw(
      Types::Standard
      Types::Common::Numeric
      Types::Common::String
    );
}

declare Longitude, as Num, where { $_ >= -180 and $lon <= 180 };
declare Latitude,  as Num, where { $_ >= -90  and $lon <= 90 };

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSky::API::Types - Type library for OpenSky::API

=head1 VERSION

version 0.004

=head1 DESCRIPTION

No user-serviceable parts inside.

=head1 CUSTOM TYPES

=head2 Longitude

A number between -180 and 180, inclusive.

=head2 Latitude

A number between -90 and 90, inclusive.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
