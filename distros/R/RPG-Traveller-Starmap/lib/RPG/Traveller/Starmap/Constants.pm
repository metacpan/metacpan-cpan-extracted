package RPG::Traveller::Starmap::Constants;

# ABSTRACT: Constants used for readability in (Mega)Traveller applications.
use 5.010001;
use strict;
use warnings;
#
# Constants to demarcate subsector densities.
use constant RIFT      => 1;
use constant SPARSE    => 2;
use constant SCATTERED => 3;
use constant NORMAL    => 4;
use constant DENSE     => 5;

#
# Constants defining star group nature

use constant SOLO    => 1;
use constant BINARY  => 2;
use constant TRINARY => 3;

# Constants defining star types
use constant O => 1;
use constant B => 2;
use constant A => 3;
use constant F => 4;
use constant G => 5;
use constant K => 6;
use constant M => 7;

# Constants defining star sizes
use constant Ia  => 1;
use constant Ib  => 2;
use constant II  => 3;
use constant III => 4;
use constant IV  => 5;
use constant V   => 6;
use constant VI  => 7;
use constant D   => 8;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use RPG::Traveller::Starmap::Constants ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
          RIFT SPARSE SCATTERED NORMAL DENSE
          SOLO BINARY TRINARY
          Ia Ib II III IV V VI VII D
          O B A F G K M
          )
    ],
    'densities' => [qw ( RIFT SPARSE SCATTERED NORMAL DENSE )],
    'sgnature'  => [qw ( SOLO BINARY TRINARY )],
    'starsizes' => [qw ( Ia Ib II III IV V VI VII D )],
    'startypes' => [qw ( O B A F G K M )]
);

our @EXPORT_OK = (
    @{
        $EXPORT_TAGS{'all'}    #,
#################################    $EXPORT_TAGS{'densities'}
    }
);

our @EXPORT = qw(
  RIFT SPARSE SCATTERED NORMAL DENSE
);

our $VERSION = '0.500';

# Preloaded methods go here.

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Starmap::Constants - Constants used for readability in (Mega)Traveller applications.

=head1 VERSION

version 0.500

=head1 AUTHOR

Peter L. Berghold <peter@berghold.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Peter L. Berghold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
