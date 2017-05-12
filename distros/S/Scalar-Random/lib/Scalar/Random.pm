package Scalar::Random;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	randomize
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Scalar::Random', $VERSION);

1;
__END__

=head1 NAME

Scalar::Random - Create automatic random number generators

=head1 SYNOPSIS

  use Scalar::Random 'randomize';

  my $random;
  my $MAX_RANDOM = 100;

  randomize( $random, $MAX_RANDOM );

  print $random, "\n"; # '42'
  print $random, "\n"; # '17'
  print $random, "\n"; # '88'
  print $random, "\n"; # '4'
  print $random, "\n"; # '50'

=head1 DESCRIPTION

Scalar::Random will turn a scalar variable into an automatic random number
generator. All you need to do to get the next random number is use it!

=head1 AUTHOR

Alfie John, E<lt>alfie@h4c.krE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alfie John

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
