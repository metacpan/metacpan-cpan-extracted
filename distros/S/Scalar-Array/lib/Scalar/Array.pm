package Scalar::Array;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	round_robin
	shrink
	sa_length
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Scalar::Array', $VERSION);

1;
__END__

=head1 NAME

Scalar::Array - Turns arrayrefs into iterators

=head1 SYNOPSIS

  use Scalar::Array;

  my $rr_ref = [ 1, 2, 3, 4, 5 ];

  round_robin( $rr_ref );
  print sa_length( $rr_ref ); # prints 5

  print $rr_ref,"\n"; # prints 1
  print $rr_ref,"\n"; # prints 2
  print $rr_ref,"\n"; # prints 3
  print $rr_ref,"\n"; # prints 4
  print $rr_ref,"\n"; # prints 5
  print $rr_ref,"\n"; # prints 1
  print $rr_ref,"\n"; # prints 2
  print $rr_ref,"\n"; # prints 3
  ...

  my $s_ref = [ 1, 2, 3, 4, 5 ];

  shrink( $s_ref );
  print sa_length( $s_ref ); # prints 5

  print $s_ref,"\n"; # prints 1
  print $s_ref,"\n"; # prints 2
  print $s_ref,"\n"; # prints 3
  print $s_ref,"\n"; # prints 4
  print $s_ref,"\n"; # prints 5
  print $s_ref,"\n"; # undef
  print $s_ref,"\n"; # undef
  print $s_ref,"\n"; # undef

=head1 DESCRIPTION

Scalar::Array will turn any arrayref into an iterator by simply using
the arrayref itself. Only reading is currently implemented.

=head2 round_robin

	round_robin( $arrayref );

Turn the passed in arrayref into a round robin iterator. At each iteration, we
shift off the next value and then push back on the other end. See SYNOPSIS for
the example.

=head2 shrink

	shrink( $arrayref );

Turn the passed in arrayref into a shrinking iterator. At each iteration, we
shift off the next value, but don't push back on the other end. In other words,
the arrayref will shrink on each read.

=head sa_length

	printf "Arrayref has %d items\n", sa_length( $arrayref );

Return the number of items in the arrayref.

=head1 BUGS

This did seem like a good idea at the time. Now I'm not so sure.

=head1 AUTHOR

Alfie John, E<lt>alfie@h4c.krE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Alfie John

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
