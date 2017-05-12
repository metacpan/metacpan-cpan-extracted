#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 54;
use Test::Fatal;

use Statistics::R::IO::Parser qw(:all);
use Statistics::R::IO::ParserState;
use Statistics::R::IO::QapEncoding qw(:all);

use lib 't/lib';
use ShortDoubleVector;
use TestCases;


sub check_qap {
    my ($file, $expected, $message) = @_;
    my $filename = $file . '.qap';
    
    open (my $f, $filename) or die $! . " $filename";
    binmode $f;
    my ($data, $rc) = '';
    while ($rc = read($f, $data, 8192, length $data)) {}
    die $! unless defined $rc;
    
    subtest 'qap - ' . $message => sub {
        plan tests => 2;
        
        my ($actual, $state) = @{ decode($data) };
        ## NOTE: I'm switching the order of comparisons to ensure
        ## ShortDoubleVector's 'eq' overload is used
        is($expected, $actual, $message) or diag explain $actual;
        ok($state->eof, $message . ' - parse complete')
    }
}


sub check_padding {
    my ($data, $expected, $message) = @_;
    subtest 'padding - ' . $message => sub {
        plan tests => 2;
        
        my ($value, $state) = @{ decode($data) };
        
        is($value, $expected, $message) or diag explain $value;
        ok($state->eof, $message . ' - parse complete')

    }
}


subtest 'integer vectors' => sub {
    plan tests => 2;
    
    ## serialize 1:3, XDR: true
    check_qap('t/data/noatt-123l',
              Statistics::R::REXP::Integer->new([ 1, 2, 3 ]),
              'int vector no atts');

    ## serialize a=1L, b=2L, c=3L, XDR: true
    check_qap('t/data/abc-123l',
              Statistics::R::REXP::Integer->new(
                  elements => [ 1, 2, 3 ],
                  attributes => {
                      names => Statistics::R::REXP::Character->new(['a', 'b', 'c'])
                  }),
              'int vector names att');
    
    # ## handling of negative integer vector length
    # like(exception {
    #     unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x0d\xff\xff\xff\xff" .
    #                 "\0\0\0\0" . "\0\0\0\1")
    #      }, qr/TODO: Long vectors are not supported/, 'long length');

    # like(exception {
    #     unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x0d\xff\xff\xff\x0")
    #      }, qr/Negative length/, 'negative length');
};


subtest 'double vectors' => sub {
    plan tests => 2;
    
    ## serialize 1:3, XDR: true
    check_qap('t/data/noatt-123456',
              ShortDoubleVector->new([ 1234.56 ]),
              'double vector no atts');

    ## serialize foo=1234.56, XDR: true
    check_qap('t/data/foo-123456',
              ShortDoubleVector->new(
                  elements => [ 1234.56 ],
                  attributes => {
                      names => Statistics::R::REXP::Character->new(['foo'])
                  }),
              'double vector names att');
};


subtest 'character vectors' => sub {
    plan tests => 3;

    ## serialize letters[1:3], XDR: true
    check_qap('t/data/noatt-abc',
              Statistics::R::REXP::Character->new([ 'a', 'b', 'c' ]),
              'character vector no atts');
    ## serialize A='a', B='b', C='c', XDR: true
    check_qap('t/data/ABC-abc',
              Statistics::R::REXP::Character->new(
                  elements => [ 'a', 'b', 'c' ],
                  attributes => {
                      names => Statistics::R::REXP::Character->new(['A', 'B', 'C'])
                  }),
              'character vector names att');

    check_padding("\x0a\x0c\0\0\x22\x08\0\0\x61\0\x62\0\x63\0\1\1",
                  Statistics::R::REXP::Character->new(['a', 'b', 'c']),
                  'c("a", "b", "c")');
};


subtest 'raw vectors' => sub {
    plan tests => 4;
    
    ## serialize as.raw(c(1:3, 255, 0), XDR: true
    check_qap('t/data/noatt-raw',
              Statistics::R::REXP::Raw->new([ 1, 2, 3, 255, 0 ]),
              'raw vector');
    
    check_padding("\x0a\x0c\0\0\x25\x08\0\0\1\0\0\0\x78\0\0\0",
                  Statistics::R::REXP::Raw->new([120]),
                  'charToRaw("x")');
    
    check_padding("\x0a\x0c\0\0\x25\x08\0\0\3\0\0\0\x66\x6f\x6f\0",
                  Statistics::R::REXP::Raw->new([102, 111, 111]),
                  'charToRaw("foo")');
    
    check_padding("\x0a\x0c\0\0\x25\x08\0\0\4\0\0\0\x66\x72\x65\x64",
                  Statistics::R::REXP::Raw->new([102, 114, 101, 100]),
                  'charToRaw("fred")');
};


subtest 'logical vectors' => sub {
    plan tests => 5;
    
    check_qap('t/data/noatt-true',
              Statistics::R::REXP::Logical->new([ 1 ]),
              'logical vector - singleton');
    
    check_qap('t/data/noatt-tfftf',
              Statistics::R::REXP::Logical->new([ 1, 0, 0, 1, 0 ]),
              'logical vector');
    
    check_qap('t/data/ABCDE-tfftf',
              Statistics::R::REXP::Logical->new(
                  elements => [ 1, 0, 0, 1, 0 ],
                  attributes => {
                      names => Statistics::R::REXP::Character->new(['A', 'B', 'C', 'D', 'E'])
                  }),
              'logical vector names att');
    
    check_padding("\x0a\x0c\0\0\x24\x08\0\0\1\0\0\0\1\xff\xff\xff",
                  Statistics::R::REXP::Logical->new([1]),
                  'TRUE');
    
    check_padding("\x0a\x0c\0\0\x24\x08\0\0\4\0\0\0\1\0\0\1",
                  Statistics::R::REXP::Logical->new([1, 0, 0, 1]),
                  'c(TRUE, FALSE, FALSE, TRUE)');
};


subtest 'generic vector (list)' => sub {
    plan tests => 2;
    
    ## serialize list(1:3, list('a', 'b', 11), 'foo'), XDR: true
    check_qap('t/data/noatt-list',
              Statistics::R::REXP::List->new([
                  Statistics::R::REXP::Integer->new([ 1, 2, 3]),
                  Statistics::R::REXP::List->new([
                      Statistics::R::REXP::Character->new(['a']),
                      Statistics::R::REXP::Character->new(['b']),
                      ShortDoubleVector->new([11]) ]),
                  Statistics::R::REXP::Character->new(['foo']) ]),
              'generic vector no atts');

    ## serialize list(foo=1:3, list('a', 'b', 11), bar='foo'), XDR: true
    check_qap('t/data/foobar-list',
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
              'generic vector names att');
};


subtest 'symbol' => sub {
    plan tests => 3;
    
    check_padding("\x0a\x08\0\0\x13\4\0\0\x78\0\0\0",
                  Statistics::R::REXP::Symbol->new('x'),
                  'as.name("x")');
    
    check_padding("\x0a\x08\0\0\x13\4\0\0\x66\x6f\x6f\0",
                  Statistics::R::REXP::Symbol->new('foo'),
                  'as.name("foo")');
    
    check_padding("\x0a\x0c\0\0\x13\x08\0\0\x66\x72\x65\x64\0\0\0\0",
                  Statistics::R::REXP::Symbol->new('fred'),
                  'as.name("fred")');
};



subtest 'matrix' => sub {
    plan tests => 2;
    
    ## serialize matrix(-1:4, 2, 3), XDR: true
    check_qap('t/data/noatt-mat',
              Statistics::R::REXP::Integer->new(
                  elements => [ -1, 0, 1, 2, 3, 4 ],
                  attributes => {
                      dim => Statistics::R::REXP::Integer->new([2, 3]),
                  }),
              'int matrix no atts');
    
    ## serialize matrix(-1:4, 2, 3, dimnames=list(c('a', 'b'))), XDR: true
    check_qap('t/data/ab-mat',
              Statistics::R::REXP::Integer->new(
                  elements => [ -1, 0, 1, 2, 3, 4 ],
                  attributes => {
                      dim => Statistics::R::REXP::Integer->new([2, 3]),
                      dimnames => Statistics::R::REXP::List->new([
                          Statistics::R::REXP::Character->new(['a', 'b']),
                          Statistics::R::REXP::Null->new
                      ]),
                  }),
              'int matrix rownames');
};


subtest 'data frames' => sub {
    plan tests => 3;

    ## serialize head(cars)
    check_qap('t/data/cars',
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
              'the cars data frame');


    ## serialize head(mtcars)
    check_qap('t/data/mtcars',
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
       'the mtcars data frame');

    ## serialize head(iris)
    check_qap('t/data/iris',
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
       'the iris data frame');
    };


## Call lm(mpg ~ wt, data = head(mtcars))
check_qap('t/data/lang-lm-mpgwt',
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
          'language lm(mpg~wt, head(mtcars))');


## serialize lm(mpg ~ wt, data = head(mtcars))
check_qap('t/data/mtcars-lm-mpgwt',
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
                   '.Environment' => Statistics::R::REXP::Unknown->new(sexptype=>4),
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
                           '.Environment' => Statistics::R::REXP::Unknown->new(sexptype=>4),
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
   'lm mpg~wt, head(mtcars)');


while ( my ($name, $value) = each %{TEST_CASES()} ) {
  SKIP: {
    skip "not yet supported", 1 if ($value->{skip} || '' =~ 'rserve');
    check_qap('t/data/' . $name,
              $value->{value},
              $value->{desc});
  }
}
