#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;
use Test::Fatal;

use Statistics::R::IO::Parser qw(:all);
use Statistics::R::IO qw( readRData );

use lib 't/lib';
use ShortDoubleVector;


sub check_rdata {
    my ($file, $expected, $message) = @_;

    subtest 'rdata ' . $message => sub {
        plan tests => keys(%{$expected}) + 1;
        
        my %actual = readRData($file);
        
        is(keys %actual,
           keys %{$expected}, "$message keys");
        while (my ($key, $value) = each %{$expected}) {
            ## NOTE: I'm switching the order of comparisons to ensure
            ## ShortDoubleVector's 'eq' overload is used
            is($expected->{$key}, $actual{$key},
               "$message $key");
        }
    }
}

sub check_rdata_variants {
    my ($file, $expected, $message) = @_;

    subtest 'variants ' . $message => sub {
        plan tests => 4;
        
        check_rdata($file . '.RData',
                    $expected, $message . ' - default');
        check_rdata($file . '_uncompressed.RData',
                    $expected, $message . ' - uncompressed');
        check_rdata($file . '_bzip.RData',
                    $expected, $message . ' - bzip');
        like(exception {
            readRData($file . '_xz.RData')
             }, qr/xz-compressed RData/, $message . ' - xz');
    }
}

## Atomic vectors
my %expected_vecs = (
    noatt_int =>
        Statistics::R::REXP::Integer->new([ -1, 0, 1, 2, 3 ]),
    abc_int =>
        Statistics::R::REXP::Integer->new(
           elements => [ 1, 2, 3 ],
           attributes => {
               names => Statistics::R::REXP::Character->new(['a', 'b', 'c'])
           }),
    
    noatt_num =>
       ShortDoubleVector->new([ 1234.56 ]),
    foo_num =>
       ShortDoubleVector->new(
           elements => [ 1234.56 ],
           attributes => {
               names => Statistics::R::REXP::Character->new(['foo'])
           }),
    
    noatt_chr =>
       Statistics::R::REXP::Character->new([ 'a', 'b', 'c' ]),
    abc_chr =>
       Statistics::R::REXP::Character->new(
           elements => [ 'a', 'b', 'c' ],
           attributes => {
               names => Statistics::R::REXP::Character->new(['A', 'B', 'C'])
           }),
    
    noatt_raw =>
       Statistics::R::REXP::Raw->new([ 1, 2, 3, 255, 0 ]),
    );

check_rdata_variants('t/data/vecs',
                     \%expected_vecs, 'Vectors');


## Matrices
my %expected_mats = (
    noatt_mat =>
        Statistics::R::REXP::Integer->new(
            elements => [ -1, 0, 1, 2, 3, 4 ],
            attributes => {
                dim => Statistics::R::REXP::Integer->new([2, 3]),
            }),
    ab_mat =>
        Statistics::R::REXP::Integer->new(
            elements => [ -1, 0, 1, 2, 3, 4 ],
            attributes => {
                dim => Statistics::R::REXP::Integer->new([2, 3]),
                dimnames => Statistics::R::REXP::List->new([
                    Statistics::R::REXP::Character->new(['a', 'b']),
                    Statistics::R::REXP::Null->new
                ]),
            }),
    );

check_rdata_variants('t/data/mats',
                     \%expected_mats, 'Matrices');


## Lists
my %expected_lists = (
    noatt_list =>
        Statistics::R::REXP::List->new([
            Statistics::R::REXP::Integer->new([ 1, 2, 3]),
            Statistics::R::REXP::List->new([
                Statistics::R::REXP::Character->new(['a']),
                Statistics::R::REXP::Character->new(['b']),
                ShortDoubleVector->new([11]) ]),
            Statistics::R::REXP::Character->new(['foo']) ]),
         foobar_list =>
        Statistics::R::REXP::List->new(
            elements => [
                Statistics::R::REXP::Integer->new([ 1, 2, 3]),
                Statistics::R::REXP::List->new([
                    Statistics::R::REXP::Character->new(['a']),
                    Statistics::R::REXP::Character->new(['b']),
                    ShortDoubleVector->new([11]) ]),
                Statistics::R::REXP::Character->new(['foo']) ],
            attributes => {
                names => Statistics::R::REXP::Character->new(['foo', '', 'bar'])
            }),
         );
check_rdata_variants('t/data/lists',
            \%expected_lists, 'Lists');


## Data frames
my %expected_frames = (
    my_cars =>
        Statistics::R::REXP::List->new(
            elements => [
                ShortDoubleVector->new([ 4, 4, 7, 7, 8, 9]),
                ShortDoubleVector->new([ 2, 10, 4, 22, 16, 10]),
            ],
            attributes => {
                names => Statistics::R::REXP::Character->new(['speed', 'dist']),
                class => Statistics::R::REXP::Character->new(['data.frame']),
                'row.names' => Statistics::R::REXP::Integer->new([
                    1, 2, 3, 4, 5, 6
                ]),
            }),
    my_mtcars =>
        Statistics::R::REXP::List->new(
            elements => [
                ShortDoubleVector->new([ 21.0, 21.0, 22.8, 21.4, 18.7, 18.1 ]),
                ShortDoubleVector->new([ 6, 6, 4, 6, 8, 6 ]),
                ShortDoubleVector->new([ 160, 160, 108, 258, 360, 225 ]),
                ShortDoubleVector->new([ 110, 110, 93, 110, 175, 105 ]),
                ShortDoubleVector->new([ 3.90, 3.90, 3.85, 3.08, 3.15, 2.76 ]),
                ShortDoubleVector->new([ 2.620, 2.875, 2.320, 3.215, 3.440, 3.460 ]),
                ShortDoubleVector->new([ 16.46, 17.02, 18.61, 19.44, 17.02, 20.22 ]),
                ShortDoubleVector->new([ 0, 0, 1, 1, 0, 1 ]),
                ShortDoubleVector->new([ 1, 1, 1, 0, 0, 0 ]),
                ShortDoubleVector->new([ 4, 4, 4, 3, 3, 3 ]),
                ShortDoubleVector->new([ 4, 4, 1, 1, 2, 1 ]),
            ],
            attributes => {
                names => Statistics::R::REXP::Character->new([
                    'mpg' , 'cyl', 'disp', 'hp', 'drat', 'wt', 'qsec',
                    'vs', 'am', 'gear', 'carb']),
                class => Statistics::R::REXP::Character->new(['data.frame']),
                'row.names' => Statistics::R::REXP::Character->new([
                    'Mazda RX4', 'Mazda RX4 Wag', 'Datsun 710',
                    'Hornet 4 Drive', 'Hornet Sportabout', 'Valiant'
                ]),
            }),
    my_iris =>
        Statistics::R::REXP::List->new(
            elements => [
                ShortDoubleVector->new([ 5.1, 4.9, 4.7, 4.6, 5.0, 5.4 ]),
                ShortDoubleVector->new([ 3.5, 3.0, 3.2, 3.1, 3.6, 3.9 ]),
                ShortDoubleVector->new([ 1.4, 1.4, 1.3, 1.5, 1.4, 1.7 ]),
                ShortDoubleVector->new([ 0.2, 0.2, 0.2, 0.2, 0.2, 0.4 ]),
                Statistics::R::REXP::Integer->new(
                    elements => [ 1, 1, 1, 1, 1, 1 ],
                    attributes => {
                        levels => Statistics::R::REXP::Character->new([
                            'setosa', 'versicolor', 'virginica']),
                        class => Statistics::R::REXP::Character->new(['factor'])
                    } ),
            ],
            attributes => {
                names => Statistics::R::REXP::Character->new([
                    'Sepal.Length', 'Sepal.Width', 'Petal.Length',
                    'Petal.Width', 'Species']),
                class => Statistics::R::REXP::Character->new(['data.frame']),
                'row.names' => Statistics::R::REXP::Integer->new([
                    1, 2, 3, 4, 5, 6
                ]),
            }),
    );
check_rdata_variants('t/data/frames',
            \%expected_frames, 'Frames');


## Environments
my %expected_env = (
    e1 =>
        Statistics::R::REXP::Environment->new(
            frame => {
                x => Statistics::R::REXP::Character->new(['foo']),
                y => Statistics::R::REXP::Character->new(['bar']),
            },
            enclosure => Statistics::R::REXP::GlobalEnvironment->new),
    e2 =>
        Statistics::R::REXP::Environment->new(
            frame => {
                x => Statistics::R::REXP::Integer->new([7]),
            },
            enclosure => Statistics::R::REXP::Environment->new(
                frame => {
                    x => Statistics::R::REXP::Character->new(['foo']),
                    y => Statistics::R::REXP::Character->new(['bar']),
                },
                enclosure => Statistics::R::REXP::GlobalEnvironment->new),
        ),
    );
check_rdata_variants('t/data/env',
            \%expected_env, 'Environment');


## Model objects
my %expected_models = (
    mtcars_lm =>
        Statistics::R::REXP::List->new(
            elements => [
                # coefficients
                ShortDoubleVector->new(
                    elements => [ 30.3002034730204, -3.27948805566774 ],
                    attributes => {
                        names => Statistics::R::REXP::Character->new(['(Intercept)', 'wt'])
                    }),
                # residuals
                ShortDoubleVector->new(
                    elements => [ -0.707944767170941, 0.128324687024322, 0.108208816128727,
                                  1.64335062595135, -0.318764561523408, -0.853174800410051 ],
                    attributes => {
                        names => Statistics::R::REXP::Character->new([
                            "Mazda RX4", "Mazda RX4 Wag",
                            "Datsun 710", "Hornet 4 Drive",
                            "Hornet Sportabout", "Valiant" ])
                    }),
                # effects
                ShortDoubleVector->new(
                    elements => [ -50.2145397270552, -3.39713386075597, 0.13375416348722,
                                  1.95527848390874, 0.0651588996571721, -0.462851730054076 ],
                    attributes => {
                        names => Statistics::R::REXP::Character->new([
                            '(Intercept)', 'wt', '',
                            '', '', '' ])
                    }),
                # rank
                Statistics::R::REXP::Integer->new([2]),
                # fitted.values
                ShortDoubleVector->new(
                    elements => [ 21.7079447671709, 20.8716753129757, 22.6917911838713,
                                  19.7566493740486, 19.0187645615234, 18.9531748004101  ],
                    attributes => {
                        names => Statistics::R::REXP::Character->new([
                            "Mazda RX4", "Mazda RX4 Wag",
                            "Datsun 710", "Hornet 4 Drive",
                            "Hornet Sportabout", "Valiant" ])
                    }),
                # assign
                Statistics::R::REXP::Integer->new([0, 1]),
                # qr
                Statistics::R::REXP::List->new(
                    elements => [
                        # qr
                        ShortDoubleVector->new(
                            elements => [ -2.44948974278318, 0.408248290463863,
                                          0.408248290463863, 0.408248290463863,
                                          0.408248290463863, 0.408248290463863,
                                          -7.31989184801706, 1.03587322261623,
                                          0.542107126002057, -0.321898217952644,
                                          -0.539106265315558, -0.558413647303373 ],
                            attributes => {
                                dim => Statistics::R::REXP::Integer->new([ 6, 2 ]),
                                dimnames => Statistics::R::REXP::List->new([
                                    Statistics::R::REXP::Character->new([
                                        "Mazda RX4", "Mazda RX4 Wag",
                                        "Datsun 710", "Hornet 4 Drive",
                                        "Hornet Sportabout", "Valiant" ]),
                                    Statistics::R::REXP::Character->new([
                                        '(Intercept)', 'wt' ])
                                    ]),
                                assign => Statistics::R::REXP::Integer->new([
                                    0, 1
                                ]),
                            }),
                        # qraux
                        ShortDoubleVector->new(
                            [ 1.40824829046386, 1.0063272758402 ]),
                        # pivot
                        Statistics::R::REXP::Integer->new([1, 2]),
                        # tol
                        ShortDoubleVector->new([1E-7]),
                        # rank
                        Statistics::R::REXP::Integer->new([2]),
                    ],
                    attributes => {
                        names => Statistics::R::REXP::Character->new([
                            "qr", "qraux", "pivot",
                            "tol", "rank" ]),
                        class => Statistics::R::REXP::Character->new(['qr'])
                    }),
                # df.residual
                Statistics::R::REXP::Integer->new([4]),
                # xlevels
                Statistics::R::REXP::List->new(
                    elements => [],
                    attributes => {
                        names => Statistics::R::REXP::Character->new([])
                    }),
                # call
                Statistics::R::REXP::Language->new(
                    elements => [
                        Statistics::R::REXP::Symbol->new('lm'),
                        Statistics::R::REXP::Language->new(
                            elements => [
                                Statistics::R::REXP::Symbol->new('~'),
                                Statistics::R::REXP::Symbol->new('mpg'),
                                Statistics::R::REXP::Symbol->new('wt'),
                            ]),
                        Statistics::R::REXP::Language->new(
                            elements => [
                                Statistics::R::REXP::Symbol->new('head'),
                                Statistics::R::REXP::Symbol->new('mtcars'),
                            ]),
                    ],
                    attributes => {
                        names => Statistics::R::REXP::Character->new([
                            '', 'formula', 'data' ])
                    }),
                # terms
                Statistics::R::REXP::Language->new(
                    elements => [
                        Statistics::R::REXP::Symbol->new('~'),
                        Statistics::R::REXP::Symbol->new('mpg'),
                        Statistics::R::REXP::Symbol->new('wt'),
                    ],
                    attributes => {
                        variables => Statistics::R::REXP::Language->new(
                            elements => [
                                Statistics::R::REXP::Symbol->new('list'),
                                Statistics::R::REXP::Symbol->new('mpg'),
                                Statistics::R::REXP::Symbol->new('wt'),
                            ]),
                        factors => Statistics::R::REXP::Integer->new(
                            elements => [ 0, 1 ],
                            attributes => {
                                dim => Statistics::R::REXP::Integer->new([ 2, 1 ]),
                                dimnames => Statistics::R::REXP::List->new([
                                    Statistics::R::REXP::Character->new([
                                        'mpg', 'wt' ]),
                                    Statistics::R::REXP::Character->new([ 'wt' ]),
                                ]),
                            }),
                        'term.labels' => Statistics::R::REXP::Character->new(['wt']),
                        order => Statistics::R::REXP::Integer->new([1]),
                        intercept => Statistics::R::REXP::Integer->new([1]),
                        response => Statistics::R::REXP::Integer->new([1]),
                        class => Statistics::R::REXP::Character->new([
                            'terms', 'formula'
                        ]),
                        '.Environment' => Statistics::R::REXP::GlobalEnvironment->new,
                        predvars => Statistics::R::REXP::Language->new(
                            elements => [
                                Statistics::R::REXP::Symbol->new('list'),
                                Statistics::R::REXP::Symbol->new('mpg'),
                                Statistics::R::REXP::Symbol->new('wt'),
                            ]),
                        dataClasses => Statistics::R::REXP::Character->new(
                            elements => ['numeric', 'numeric'],
                            attributes => {
                                names => Statistics::R::REXP::Character->new(['mpg', 'wt'])
                            }),
                    }),
                # model
                Statistics::R::REXP::List->new(
                    elements => [
                        ShortDoubleVector->new([ 21.0, 21.0, 22.8, 21.4, 18.7, 18.1 ]),
                        ShortDoubleVector->new([ 2.62, 2.875, 2.32, 3.215, 3.44, 3.46 ]),
                    ],
                    attributes => {
                        names => Statistics::R::REXP::Character->new(['mpg', 'wt']),
                        'row.names' => Statistics::R::REXP::Character->new([
                            'Mazda RX4', 'Mazda RX4 Wag', 'Datsun 710',
                            'Hornet 4 Drive', 'Hornet Sportabout', 'Valiant']),
                        class => Statistics::R::REXP::Character->new(['data.frame']),
                        terms => Statistics::R::REXP::Language->new(
                            elements => [
                                Statistics::R::REXP::Symbol->new('~'),
                                Statistics::R::REXP::Symbol->new('mpg'),
                                Statistics::R::REXP::Symbol->new('wt'),
                            ],
                            attributes => {
                                variables => Statistics::R::REXP::Language->new(
                                    elements => [
                                        Statistics::R::REXP::Symbol->new('list'),
                                        Statistics::R::REXP::Symbol->new('mpg'),
                                        Statistics::R::REXP::Symbol->new('wt'),
                                    ]),
                                factors => Statistics::R::REXP::Integer->new(
                                    elements => [ 0, 1 ],
                                    attributes => {
                                        dim => Statistics::R::REXP::Integer->new([ 2, 1 ]),
                                        dimnames => Statistics::R::REXP::List->new([
                                            Statistics::R::REXP::Character->new([
                                                'mpg', 'wt' ]),
                                            Statistics::R::REXP::Character->new([ 'wt' ]),
                                        ]),
                                    }),
                                'term.labels' => Statistics::R::REXP::Character->new(['wt']),
                                order => Statistics::R::REXP::Integer->new([1]),
                                intercept => Statistics::R::REXP::Integer->new([1]),
                                response => Statistics::R::REXP::Integer->new([1]),
                                class => Statistics::R::REXP::Character->new([
                                    'terms', 'formula'
                                ]),
                                '.Environment' => Statistics::R::REXP::GlobalEnvironment->new,
                                predvars => Statistics::R::REXP::Language->new(
                                    elements => [
                                        Statistics::R::REXP::Symbol->new('list'),
                                        Statistics::R::REXP::Symbol->new('mpg'),
                                        Statistics::R::REXP::Symbol->new('wt'),
                                    ]),
                                dataClasses => Statistics::R::REXP::Character->new(
                                    elements => ['numeric', 'numeric'],
                                    attributes => {
                                        names => Statistics::R::REXP::Character->new(['mpg', 'wt'])
                                    }),
                            }),
                    }),
            ],
            attributes => {
                names => Statistics::R::REXP::Character->new([
                    'coefficients', 'residuals', 'effects', 'rank',
                    'fitted.values', 'assign', 'qr', 'df.residual',
                    'xlevels', 'call', 'terms', 'model',
                ]),
                class => Statistics::R::REXP::Character->new(['lm']) }),
    );
check_rdata_variants('t/data/lm',
            \%expected_models, 'Models');


my %expected_all = (
    %expected_vecs,
    %expected_mats,
    %expected_lists,
    %expected_frames,
    %expected_env,
    %expected_models,
);
check_rdata_variants('t/data/all',
            \%expected_all, 'all');
