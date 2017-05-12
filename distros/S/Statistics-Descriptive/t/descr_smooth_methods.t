#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Statistics::Descriptive;

local $SIG{__WARN__} = sub { };

my @original_data = (1 .. 10);

{
    # testing set_smoother
    my $stats = Statistics::Descriptive::Full->new();

    $stats->add_data(\@original_data );

    $stats->set_smoother({
           method   => 'exponential',
           coeff    => 0,
    });
    # TEST
    isa_ok ( $stats->{_smoother}, 'Statistics::Descriptive::Smoother::Exponential', 'set_smoother: smoother set correctly');

}

{
    # testing get_smoothed_data
    my $stats = Statistics::Descriptive::Full->new();

    # TEST
    is ( $stats->get_smoothed_data(), undef, 'get_smoothed_data: smoother needs to be defined');

    $stats->add_data(\@original_data );

    $stats->set_smoother({
           method   => 'exponential',
           coeff    => 0.5,
    });

    my @expected_values = (
          1,
          1.5,
          2.25,
          3.125,
          4.0625,
          5.03125,
          6.015625,
          7.0078125,
          8.00390625,
          9.001953125,
    );

    my @smoothed_data = $stats->get_smoothed_data();

    # TEST
    is_deeply( \@smoothed_data, \@expected_values, 'Smoothing with C=0.5');
}

=pod

=head1 AUTHOR

Fabio Ponciroli

=head1 COPYRIGHT

Copyright(c) 2012 by Fabio Ponciroli.

=head1 LICENSE

This file is licensed under the MIT/X11 License:
http://www.opensource.org/licenses/mit-license.php.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
