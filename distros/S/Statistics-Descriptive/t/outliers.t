#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Statistics::Descriptive;

sub foo {return;};

local $SIG{__WARN__} = sub { };

{
    # testing set_outlier_filter
    my $stat = Statistics::Descriptive::Full->new();

    # TEST
    ok ( !defined($stat->set_outlier_filter()), 'set_outlier_filter: undef code reference value');
    # TEST
    ok ( !defined($stat->set_outlier_filter(1)), 'set_outlier_filter: invalid code ref value');

    # TEST
    is ( $stat->set_outlier_filter(\&foo), 1, 'set_outlier_filter: valid code reference - return value');
    # TEST
    is ( $stat->{_outlier_filter}, \&foo, 'set_outlier_filter: valid code reference - internal');

}

{
    # testing get_data_without_outliers without removing outliers
    my $stat = Statistics::Descriptive::Full->new();

    # TEST
    ok ( !defined($stat->get_data_without_outliers()), 'get_data_without_outliers: insufficient samples');

    $stat->add_data( 1, 2, 3, 4, 5 );
    # TEST
    ok ( !defined($stat->get_data_without_outliers()), 'get_data_without_outliers: undefined filter');

    # We force the filter function to never detect outliers...
    $stat->set_outlier_filter( sub {0} );

    no warnings 'redefine';
    local *Statistics::Descriptive::Full::_outlier_candidate_index = sub { 0 };
    my @results = $stat->get_data_without_outliers();

    #...we expect the data set to be unmodified
    # TEST
    is_deeply (
        [@results],
        [1, 2, 3, 4, 5],
        'get_data_without_outliers: no outliers',
    );

}

{
    # testing get_data_without_outliers removing outliers
    my $stat = Statistics::Descriptive::Full->new();

    # 100 is definitively the candidate to be an outlier in this series
    $stat->add_data( 1, 2, 3, 4, 100, 6, 7, 8 );

    # We force the filter function to always detect outliers for this data set
    $stat->set_outlier_filter( sub {$_[1] > 0} );
    my @results = $stat->get_data_without_outliers();

    # Note that 100 has been filtered out from the data set
    # TEST
    is_deeply (
        [@results],
        [1, 2, 3, 4, 6, 7, 8, ],
        'get_data_without_outliers: remove outliers',
    );

}

my ($first_val, $second_val);
sub check_params { ($first_val, $second_val) = @_; }

{
    # testing params passed to outlier filter
    my $stat = Statistics::Descriptive::Full->new();

    # 100 is definitively the candidate to be an outlier in this series
    $stat->add_data( 1, 2, 3, 4, 100, 6, 7, 8 );

    $stat->set_outlier_filter( \&check_params );
    my @results = $stat->get_data_without_outliers();

    # TEST
    isa_ok ($first_val, 'Statistics::Descriptive::Full', 'first param of outlier filter ok');
    # TEST
    is ($second_val, 100, 'second param of outlier filter ok');

}

{
    # testing _outlier_candidate_index
    my $stat = Statistics::Descriptive::Full->new();

    # 100 is definitively the candidate to be an outlier in this series
    $stat->add_data( 1, 2, 3, 4, 100, 6, 7, 8 );

    # TEST
    is ($stat->_outlier_candidate_index, 4, '_outlier_candidate_index' );

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
