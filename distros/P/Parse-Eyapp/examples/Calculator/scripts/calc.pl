#!/usr/bin/perl -I../lib -I../../../lib 
use strict;
use warnings;
use Math::Calc;

# Called as a method just to keep compatibility with
# "modulino" call ..
Math::Calc->main();

=head1 NAME

calc.pl - Calculator example in Parse::Eyapp

=head1 SYNOPSIS

  $ calc.pl [OPTIONS]
  where options are:
          -f file
          -d 
          -h

  # input from STDIN
  $ calc.pl 

  # input from file expressions1
  $ calc.pl -f expressions1

  # debug mode
  $ calc.pl -d -f expressions1

  # Example of input file
  $ cat expressions1
  a=2*3
  b=4
  c=9+1
  b= (b+1)*b


=head1 DESCRIPTION

=head1 SEE ALSO

=over 2

=item * L<Math::Calculator>

=item * L<Parse::Eyapp>

=back

=head1 AUTHOR

Casiano Rodriguez Leon E<lt>casiano@ull.esE<gt>

=head1 LICENCE AND COPYRIGHT
 
Copyright (c) 2007 Casiano Rodriguez-Leon (casiano@ull.es). All rights reserved.

These modules are free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 




