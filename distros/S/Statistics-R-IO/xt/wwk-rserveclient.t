#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More;
my $rserve_host = $ENV{RSERVE_HOST} || 'localhost';
my $rserve_port = $ENV{RSERVE_PORT} || 6311;

if (IO::Socket::INET->new(PeerAddr => $rserve_host,
                          PeerPort => $rserve_port)) {
    plan tests => 61;
}
else {
    plan skip_all => "Cannot connect to Rserve server at localhost:6311";
}
use Test::Fatal;
use Test::MockObject::Extends;

use Statistics::R::IO::Rserve;
use Statistics::R::REXP::Integer;

use lib 't/lib';
use ShortDoubleVector;
use TestCases;

## load the RserveClient macro
my $problemSeed = 1234;         # var provided by WWk env
my $Rserve = {host => $rserve_host}; # fake configuration

use File::Spec;
use File::Path;
use Path::Class;
use File::Slurp qw(read_file);

my $PG = Test::MockObject::Extends->new();

## return the last segment of the path
$PG->mock('fileFromPath',
          sub {
              my ($self, $path) = (shift, shift);
              (File::Spec->splitpath($path))[-1];
          });
## creates all of the intermediate directories between the tempDirectory
$PG->mock('surePathToTmpFile',
          sub {
              my ($self, $file) = (shift, shift);

              my $file_path = Path::Class::file($file);
              my $file_dir = $file_path->dir;
              
              my $tmp_dir = Path::Class::dir(File::Spec->tmpdir);
              $file_dir = File::Spec->catdir($tmp_dir, $file_dir) unless
                  $tmp_dir->subsumes($file_dir);
              File::Path::make_path($file_dir);

              File::Spec->catdir($file_dir, $file_path->basename)
          });
$PG->mock('warning_message',
          sub {
              state @WARNING_messages;
              
              my ($self, @messages) = @_;
              push @WARNING_messages, @messages;
          });

open(my $macrofile, 'extras/WebWork/RserveClient.pl') ||
    die "Cannot open file: $!";
eval join('', <$macrofile>) ||
    die "Evaluating the macro file failed: $@";

sub check_rserve_eval {
    my ($rexp, $expected, $message) = @_;
    my @expected_value = (ref($expected) eq ref([]) ?
                          @{$expected} : $expected);
    
    subtest 'rserve eval ' . $message => sub {
        plan tests => 2;
        ## NOTE: I'm switching the order of comparisons to ensure
        ## ShortDoubleVector's 'eq' overload is used

        ## test the one-time query
        my @result = rserve_query($rexp);
        is_deeply(\@expected_value,
                  \@result,
                  $message);
        
        ## test the persistent connection
        @result = rserve_eval($rexp);
        is_deeply(\@expected_value,
                  \@result,
                  $message)
    }
}

## integer vectors
## serialize 1:3, XDR: true
check_rserve_eval(
    '1:3',
    Statistics::R::REXP::Integer->new([ 1, 2, 3 ])->to_pl,
    'int vector no atts');

## serialize a=1L, b=2L, c=3L, XDR: true
check_rserve_eval(
    'c(a=1L, b=2L, c=3L)',
    Statistics::R::REXP::Integer->new(
        elements => [ 1, 2, 3 ],
        attributes => {
            names => Statistics::R::REXP::Character->new(['a', 'b', 'c'])
        })->to_pl,
    'int vector names att');


## double vectors
## serialize 1234.56, XDR: true
check_rserve_eval(
   '1234.56',
    ShortDoubleVector->new([ 1234.56 ])->to_pl,
   'double vector no atts');

## serialize foo=1234.56, XDR: true
check_rserve_eval(
    'c(foo=1234.56)',
    ShortDoubleVector->new(
        elements => [ 1234.56 ],
        attributes => {
            names => Statistics::R::REXP::Character->new(['foo'])
        })->to_pl,
   'double vector names att');


## character vectors
## serialize letters[1:3], XDR: true
check_rserve_eval(
    'letters[1:3]',
    Statistics::R::REXP::Character->new([ 'a', 'b', 'c' ])->to_pl,
    'character vector no atts');

## serialize A='a', B='b', C='c', XDR: true
check_rserve_eval(
    'c(A="a", B="b", C="c")',
    Statistics::R::REXP::Character->new(
        elements => [ 'a', 'b', 'c' ],
        attributes => {
            names => Statistics::R::REXP::Character->new(['A', 'B', 'C'])
        })->to_pl,
    'character vector names att - xdr');


## raw vectors
## serialize as.raw(c(1:3, 255, 0), XDR: true
check_rserve_eval(
    'as.raw(c(1,2,3,255, 0))',
    Statistics::R::REXP::Raw->new([ 1, 2, 3, 255, 0 ])->to_pl,
    'raw vector');


## list (i.e., generic vector)
## serialize list(1:3, list('a', 'b', 11), 'foo'), XDR: true
check_rserve_eval(
    "list(1:3, list('a', 'b', 11), 'foo')",
    Statistics::R::REXP::List->new([
        Statistics::R::REXP::Integer->new([ 1, 2, 3]),
        Statistics::R::REXP::List->new([
            Statistics::R::REXP::Character->new(['a']),
            Statistics::R::REXP::Character->new(['b']),
            ShortDoubleVector->new([11]) ]),
        Statistics::R::REXP::Character->new(['foo']) ])->to_pl,
    'generic vector no atts');

## serialize list(foo=1:3, list('a', 'b', 11), bar='foo'), XDR: true
check_rserve_eval(
    "list(foo=1:3, list('a', 'b', 11), bar='foo')",
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
        })->to_pl,
    'generic vector names att - xdr');


## matrix

## serialize matrix(-1:4, 2, 3), XDR: true
check_rserve_eval(
    'matrix(-1:4, 2, 3)',
    Statistics::R::REXP::Integer->new(
        elements => [ -1, 0, 1, 2, 3, 4 ],
        attributes => {
            dim => Statistics::R::REXP::Integer->new([2, 3]),
        })->to_pl,
    'int matrix no atts');

## serialize matrix(-1:4, 2, 3, dimnames=list(c('a', 'b'))), XDR: true
check_rserve_eval(
    "matrix(-1:4, 2, 3, dimnames=list(c('a', 'b')))",
    Statistics::R::REXP::Integer->new(
        elements => [ -1, 0, 1, 2, 3, 4 ],
        attributes => {
            dim => Statistics::R::REXP::Integer->new([2, 3]),
            dimnames => Statistics::R::REXP::List->new([
                Statistics::R::REXP::Character->new(['a', 'b']),
                Statistics::R::REXP::Null->new
                                                       ]),
        })->to_pl,
    'int matrix rownames');


## data frames
## serialize head(cars)
check_rserve_eval(
    'head(cars)',
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
        })->to_pl,
    'the cars data frame');

## serialize head(mtcars)
check_rserve_eval(
    'head(mtcars)',
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
        })->to_pl,
    'the mtcars data frame');

## serialize head(iris)
check_rserve_eval(
   'head(iris)',
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
       })->to_pl,
   'the iris data frame');


## Call lm(mpg ~ wt, data = head(mtcars))
check_rserve_eval(
    'lm(mpg ~ wt, data = head(mtcars))$call',
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
        })->to_pl,
    'language lm(mpg~wt, head(mtcars))');


## serialize lm(mpg ~ wt, data = head(mtcars))
check_rserve_eval(
    'lm(mpg ~ wt, data = head(mtcars))',
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
                class => Statistics::R::REXP::Character->new(['lm']) })->to_pl,
    'lm mpg~wt, head(mtcars)');


while ( my ($name, $value) = each %{TEST_CASES()} ) {
  SKIP: {
      skip "not applicable in WebWork macros", 1 if ($value->{skip} || '' =~ 'webwork');

      ## If the expected value is wrapped in 'RexpOrUnknown', it will
      ## be XT_UNKNOWN over Rserve
      my $expected = $value->{value}->isa('RexpOrUnknown') ?
          undef : $value->{value}->to_pl;
      
      check_rserve_eval($value->{expr},
                        $expected,
                        $value->{desc});
    }
}


subtest 'R runtime errors' => sub {
    plan tests => 2;
    
    like(exception {
            rserve_eval('1+"a"')
         }, qr/Error in 1 \+ "a" : non-numeric argument to binary operator/,
         'rserve_eval');
    
    like(exception {
            rserve_query('1+"a"')
         }, qr/Error in 1 \+ "a" : non-numeric argument to binary operator/,
         'rserve_query');
};


subtest 'Rserve plot' => sub {
    plan tests => 4;
    
    my $remote = rserve_start_plot();
    rserve_eval('plot(1)');
    my $local = rserve_finish_plot($remote);
    my $png_contents = read_file($local);
    ok(-e $local, 'plot file');
    ok($png_contents =~ qr/^.PNG\r\n.*IHDR\0\0\x01\xE0\0\0\x01\xE0/s,
       'default figure dimensions (480x480)') or
           diag('True file type: ' . `file $local`);
    Path::Class::file($local)->remove;

    
    $remote = rserve_start_plot('png', 800, 732);
    rserve_eval('plot(1)');
    $local = rserve_finish_plot($remote);
    $png_contents = read_file($local);
    ok(-e $local, 'plot file');
    ok($png_contents =~ qr/^.PNG\r\n.*IHDR\0\0\x03\x20\0\0\x02\xDC/s,
       'custom figure dimensions') or
           diag('True file type: ' . `file $local`);
    Path::Class::file($local)->remove;
};


my $remote = (rserve_eval("file.path(system.file(package='base'), 'DESCRIPTION')"))[0];
my $local = rserve_get_file($remote);
ok(-e $local, 'rserve remote file');
Path::Class::file($local)->remove;

subtest 'missing configuration' => sub {
    plan tests => 2;

    undef $Rserve;
    $PG->clear;
    rserve_query('pi');
    my ($request, $args) = $PG->next_call();

    is($request,
       'warning_message', 'call warning message');
    like($args->[1], qr/Calling testing::function is disabled unless Rserve host is configured/,
       'missing configuration message')
};


## mock for the Value::traceback function
package Value;
sub traceback {
    return " in testing::function at line 123 of some_file"
}
