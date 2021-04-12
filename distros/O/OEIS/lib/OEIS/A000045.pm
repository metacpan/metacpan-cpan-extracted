package OEIS::A000045;

use 5.032;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

our $VERSION = '2021041201';

my $values;

sub new  ($class) {bless do {\my $v} => $class}
sub init ($self, $initial_values) {
    @$values = @$initial_values;
    $self
}

sub oeis ($self, $to) {
    use bigint;
    $$values [0] //= 0;
    $$values [1] //= 1;
    for (my $i = @$values; $i < $to; $i ++) {
        $$values [$i] = $$values [$i - 1] + $$values [$i - 2];
    }
    @$values;
}


1;

__END__

=head1 NAME

OEIS::A000045 - Calculate Fibonacci numbers.

=head1 SYNOPSIS

use OEIS;
my @list = oeis (A000045 => 50);

=head1 DESCRIPTION

This module is used to calculate Fibonacci numbers which are not
listed at the OEIS. 

This module should not be called directly -- use C<< OEIS >> itself.
This will call C<< OEIS::A00045 >> when needed.

=head1 BUGS

=head1 TODO

=head1 SEE ALSO

L<< Fibonacci numbers|https://oeis.org/A000045 >>

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/OEIS.git >>.

=head1 AUTHOR

Abigail, L<< mailto:cpan-oeis@abigail.freedom.nl >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2021 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
