package OEIS;

use 5.032;
use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

use LWP::Simple;

our $VERSION = '2021041201';

use Exporter ();
our @ISA    = qw [Exporter];
our @EXPORT = qw [oeis];

my $URL = "https://oeis.org/%s/list";

sub oeis ($sequence, $to = -1) {
    $sequence = sprintf "A%06d"  => $sequence if $sequence =~ /^[0-9]/;
    my $list  = get sprintf $URL => $sequence;
    my @values;

    #
    # Extract the numbers from the <PRE> section
    #
    if ($list && $list =~ m {<pre>\[([-0-9,\s]+)\]</pre>}i) {
        @values = split /[,\s]+/ => $1;
    }
    #
    # If we want more than we can fetch in the list, we see
    # if we have a module generating them. If so, we use that
    # module to fill out the rest.
    #
    if ($to > @values && eval "use OEIS::$sequence; 1") {
        @values = "OEIS::$sequence" -> new -> init (\@values) -> oeis ($to);
    }
    elsif (0 <= $to) {
        splice @values, $to;
    }
    return @values;
}


1;

__END__

=head1 NAME

OEIS - Fetch values from sequences of the OEIS.

=head1 SYNOPSIS

use OEIS;
my @list = oeis (45, 10);

=head1 DESCRIPTION

Getting tired of all those challenges asking for the first N
values of an OEIS sequence. There isn't much to do in such a
case then just fetch the numbers from the OEIS.

The C<< OEIS >> module exports a single function, C<< oeis >>,
which takes two arguments:

=over 2

=item Sequence Number

The first argument is the sequence number. This can either be the
full sequence number (an C<< A >> or C<< B >> followed by 6 digits),
or just a number. In the latter case, the number is padded with zeros
to make it 6 digits long, and an A is prepended.

=item Amount

The second, optional, argument indicates how many numbers of the sequence
we want to return. If not given, the method just returns all the integers
listed at the OEIS for the sequence; otherwise, it will be capped by
the given amount.

For a very few sequences, if the number of listed integes is less than
the given amount, the rest will be calculated.

=back

=head1 BUGS

=head1 TODO

=head1 SEE ALSO

L<< The Online Encyclopedia of Integer Sequences|https://oeis.org >>

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
