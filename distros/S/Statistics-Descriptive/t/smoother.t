#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Statistics::Descriptive::Smoother;

local $SIG{__WARN__} = sub { };

{

    #Test factory pattern
    my $smoother = Statistics::Descriptive::Smoother->instantiate({
           method   => 'exponential',
           coeff    => 0,
           data     => [1,2,3],
           samples  => [100, 100, 100],
    });

    # TEST
    isa_ok ($smoother, 'Statistics::Descriptive::Smoother::Exponential', 'Exponential class correctly created');
}

{

    my $smoother = Statistics::Descriptive::Smoother->instantiate({
           method   => 'weightedExponential',
           coeff    => 0,
           data     => [1,2,3],
           samples  => [100, 100, 100],
    });

    # TEST
    isa_ok ($smoother, 'Statistics::Descriptive::Smoother::Weightedexponential', 'Weightedexponential class correctly created');

}

{

    # Test invalid smoothing method
    eval
    {
                Statistics::Descriptive::Smoother->instantiate({
                        method   => 'invalid_method',
                        coeff    => 0,
                        data     => [1,2,3],
                        samples  => [100, 100, 100],
            });
    };

    # TEST
    ok ($@, 'Invalid method');

}

{

    #TODO get output from Carp
    #Test invalid coefficient
    my $smoother_neg = Statistics::Descriptive::Smoother->instantiate({
           method   => 'exponential',
           coeff    => -123,
           data     => [1,2,3],
           samples  => [100, 100, 100],
        });

    # TEST
    is ($smoother_neg, undef, 'Invalid coefficient: < 0');

    my $smoother_pos = Statistics::Descriptive::Smoother->instantiate({
           method   => 'exponential',
           coeff    => 123,
           data     => [1,2,3],
           samples  => [100, 100, 100],
        });

    # TEST
    is ($smoother_pos, undef, 'Invalid coefficient: > 1');

}

{

    #Test unsufficient number of samples
    my $smoother = Statistics::Descriptive::Smoother->instantiate({
           method   => 'exponential',
           coeff    => 0,
           data     => [1],
           samples  => [100],
        });

    # TEST
    is ($smoother, undef, 'Insufficient number of samples');

}

{

    #Test smoothing coefficient accessors
    my $smoother = Statistics::Descriptive::Smoother->instantiate({
           method   => 'exponential',
           coeff    => 0.5,
           data     => [1,2,3],
           samples  => [100, 100, 100],
        });

    # TEST
    is ($smoother->get_smoothing_coeff(), 0.5, 'get_smoothing_coeff');

    my $ok = $smoother->set_smoothing_coeff(0.7);

    # TEST
    ok ($ok, 'set_smoothing_coeff: set went fine');

    # TEST
    is ($smoother->get_smoothing_coeff(), 0.7, 'set_smoothing_coeff: correct value set');

    my $ok2 = $smoother->set_smoothing_coeff(123);

    # TEST
    is ($ok2, undef, 'set_smoothing_coeff: set failed');

    # TEST
    is ($smoother->get_smoothing_coeff(), 0.7, 'set_smoothing_coeff: value not modified after failure');

}

1;

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
