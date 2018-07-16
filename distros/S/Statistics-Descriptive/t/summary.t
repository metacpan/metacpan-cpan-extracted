#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;
use Statistics::Descriptive;

{
    my @data1 = ( 1 .. 20 );
    my $obj   = Statistics::Descriptive::Full->new;
    $obj->add_data(@data1);

    my $summary = $obj->summary;

    # TEST
    like( $summary, qr#\bMin: 1#, 'min' );

    # TEST
    like( $summary, qr#\bMax: 2#, 'max' );

    # TEST
    like( $summary, qr#\bMean: 1#, 'mean' );

    # TEST
    like( $summary, qr#\bMedian: 1#, 'mean' );

    # TEST
    like( $summary, qr#\b1st quantile: 5#, 'quantile' );

    # TEST
    like( $summary, qr#\b3rd quantile: 1#, 'quantile' );
}
__END__

=head1 COPYRIGHT & LICENSE

Copyright 2018 by Shlomi Fish

This program is distributed under the MIT / Expat License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
