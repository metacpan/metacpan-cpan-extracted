#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use IO::Socket::INET ();
use Socket;

use Test::More;

## Low level connections to the server used in tests
my $s;
my $rserve_host = $ENV{RSERVE_HOST} || 'localhost';
my $rserve_port = $ENV{RSERVE_PORT} || 6311;
my $rserve = IO::Socket::INET->new(PeerAddr => $rserve_host,
                                   PeerPort => $rserve_port);
if ($rserve) {
    plan tests => 58;
    $rserve->read(my $response, 32);
    die "Unrecognized server ID" unless
        substr($response, 0, 12) eq 'Rsrv0103QAP1';

    socket($s, PF_INET, SOCK_STREAM, getprotobyname('tcp')) ||
        die "socket: $!";
    connect($s, sockaddr_in($rserve_port, inet_aton($rserve_host))) ||
        die "connect: $!";
    $s->read($response, 32);
    die "Unrecognized server ID" unless
        substr($response, 0, 12) eq 'Rsrv0103QAP1';
}
else {
    plan skip_all => "Cannot connect to Rserve server at localhost:6311";
}
use Test::Fatal;

use Statistics::R::IO::Rserve;
use Statistics::R::IO::REXPFactory;

use lib 't/lib';
use ShortDoubleVector;
use TestCases;


sub check_rserve_eval_variants {
    my ($rexp, $expected, $message) = @_;
    
    subtest 'rserve eval ' . $message => sub {
        ## some tests can only be executed when Rserve's host and/or
        ## port are at a default location, localhost:6311
        plan tests => 5 - (
            2*exists($ENV{RSERVE_HOST}) ||
            3*exists($ENV{RSERVE_PORT}));
        
        ## NOTE: I'm switching the order of comparisons to ensure
        ## ShortDoubleVector's 'eq' overload is used
        unless (exists($ENV{RSERVE_HOST}) || exists($ENV{RSERVE_PORT})) {
            is($expected,
               Statistics::R::IO::Rserve->new->eval($rexp),
               $message . ' no arg constructor');
        }
        unless (exists $ENV{RSERVE_PORT}) {
            is($expected,
               Statistics::R::IO::Rserve->new($rserve_host)->eval($rexp),
               $message . ' localhost arg');
        }
        
        is($expected,
           Statistics::R::IO::Rserve->new($rserve)->eval($rexp),
           $message . ' handle arg');

        is($expected,
           Statistics::R::IO::Rserve->new($s)->eval($rexp),
           $message . ' socket arg');
        
        unless (exists($ENV{RSERVE_HOST}) || exists($ENV{RSERVE_PORT})) {
            is($expected,
               Statistics::R::IO::Rserve->new(_usesocket => 1)->eval($rexp),
               $message . ' usesocket arg');
        }
    }
}


## integer vectors
## serialize 1:3, XDR: true
check_rserve_eval_variants('1:3',
   Statistics::R::REXP::Integer->new([ 1, 2, 3 ]),
   'int vector no atts');

## serialize a=1L, b=2L, c=3L, XDR: true
check_rserve_eval_variants('c(a=1L, b=2L, c=3L)',
   Statistics::R::REXP::Integer->new(
       elements => [ 1, 2, 3 ],
       attributes => {
           names => Statistics::R::REXP::Character->new(['a', 'b', 'c'])
       }),
   'int vector names att');


## double vectors
## serialize 1234.56, XDR: true
check_rserve_eval_variants('1234.56',
   ShortDoubleVector->new([ 1234.56 ]),
   'double vector no atts');

## serialize foo=1234.56, XDR: true
check_rserve_eval_variants('c(foo=1234.56)',
   ShortDoubleVector->new(
       elements => [ 1234.56 ],
       attributes => {
           names => Statistics::R::REXP::Character->new(['foo'])
       }),
   'double vector names att');


## character vectors
## serialize letters[1:3], XDR: true
check_rserve_eval_variants('letters[1:3]',
   Statistics::R::REXP::Character->new([ 'a', 'b', 'c' ]),
   'character vector no atts');

## serialize A='a', B='b', C='c', XDR: true
check_rserve_eval_variants('c(A="a", B="b", C="c")',
   Statistics::R::REXP::Character->new(
       elements => [ 'a', 'b', 'c' ],
       attributes => {
           names => Statistics::R::REXP::Character->new(['A', 'B', 'C'])
       }),
   'character vector names att - xdr');


## raw vectors
## serialize as.raw(c(1:3, 255, 0), XDR: true
check_rserve_eval_variants('as.raw(c(1,2,3,255, 0))',
   Statistics::R::REXP::Raw->new([ 1, 2, 3, 255, 0 ]),
   'raw vector');


## list (i.e., generic vector)
## serialize list(1:3, list('a', 'b', 11), 'foo'), XDR: true
check_rserve_eval_variants("list(1:3, list('a', 'b', 11), 'foo')",
   Statistics::R::REXP::List->new([
       Statistics::R::REXP::Integer->new([ 1, 2, 3]),
       Statistics::R::REXP::List->new([
           Statistics::R::REXP::Character->new(['a']),
           Statistics::R::REXP::Character->new(['b']),
           ShortDoubleVector->new([11]) ]),
       Statistics::R::REXP::Character->new(['foo']) ]),
   'generic vector no atts');

## serialize list(foo=1:3, list('a', 'b', 11), bar='foo'), XDR: true
check_rserve_eval_variants("list(foo=1:3, list('a', 'b', 11), bar='foo')",
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
   'generic vector names att - xdr');


## matrix

## serialize matrix(-1:4, 2, 3), XDR: true
check_rserve_eval_variants('matrix(-1:4, 2, 3)',
   Statistics::R::REXP::Integer->new(
       elements => [ -1, 0, 1, 2, 3, 4 ],
       attributes => {
           dim => Statistics::R::REXP::Integer->new([2, 3]),
       }),
   'int matrix no atts');

## serialize matrix(-1:4, 2, 3, dimnames=list(c('a', 'b'))), XDR: true
check_rserve_eval_variants("matrix(-1:4, 2, 3, dimnames=list(c('a', 'b')))",
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


## data frames
## serialize head(cars)
check_rserve_eval_variants('head(cars)',
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
check_rserve_eval_variants('head(mtcars)',
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
check_rserve_eval_variants('head(iris)',
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

## serialize lm(mpg ~ wt, data = head(mtcars))
check_rserve_eval_variants('lm(mpg ~ wt, data = head(mtcars))',
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
                   '.Environment' => Statistics::R::REXP::Unknown->new(sexptype => 4),
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
                           '.Environment' => Statistics::R::REXP::Unknown->new(sexptype => 4),
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
    check_rserve_eval_variants($value->{expr},
                               $value->{value},
                               $value->{desc});
  }
}
