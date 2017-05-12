#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;
use Test::Fatal;

use Statistics::R::IO::Parser qw(:all);
use Statistics::R::IO::ParserState;
use Statistics::R::IO::REXPFactory qw(:all);

use lib 't/lib';
use ShortDoubleVector;


subtest 'integer vectors' => sub {
    plan tests => 9;
    
    ## serialize 1:3, XDR: true
    my $noatt_123_xdr = Statistics::R::IO::ParserState->new(
        data => "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x0d\0\0\0\5" .
        "\xff\xff\xff\xff" . "\0\0\0\0" . "\0\0\0\1" . "\0\0\0\2" . "\0\0\0\3");

    is_deeply(Statistics::R::IO::REXPFactory::header->($noatt_123_xdr)->[0],
              [ "X\n", 2, 0x030002, 0x020300 ],
              'XDR header');

    is_deeply(bind(Statistics::R::IO::REXPFactory::header,
                   sub {
                       Statistics::R::IO::REXPFactory::unpack_object_info
                   })->($noatt_123_xdr)->[0],
              { is_object => 0,
                has_attributes => 0,
                has_tag => 0,
                object_type => 13,
                levels => 0,
                flags => 13},
              'header plus object info - no atts');

    is(unserialize($noatt_123_xdr->data)->[0],
       Statistics::R::REXP::Integer->new([ -1, 0, 1, 2, 3 ]),
       'no atts');

    ## serialize 1:3, XDR: false
    my $noatt_123_bin = Statistics::R::IO::ParserState->new(
        data => "\x42\x0a\2\0\0\0\2\0\3\0\0\3\2\0\x0d\0\0\0\5\0\0\0" .
        "\xff\xff\xff\xff" . "\0\0\0\0" . "\1\0\0\0" . "\2\0\0\0" . "\3\0\0\0");

    is_deeply(Statistics::R::IO::REXPFactory::header->($noatt_123_bin)->[0],
              [ "B\n", 2, 0x030002, 0x020300 ],
              'binary header');

    is_deeply(bind(Statistics::R::IO::REXPFactory::header,
                   sub {
                       Statistics::R::IO::REXPFactory::unpack_object_info
                   })->($noatt_123_bin)->[0],
              { is_object => 0,
                has_attributes => 0,
                has_tag => 0,
                object_type => 13,
                levels => 0,
                flags => 13 },
              'binary header plus object info - no atts');

    is(unserialize($noatt_123_bin->data)->[0],
       Statistics::R::REXP::Integer->new([ -1, 0, 1, 2, 3 ]),
       'no atts - binary');


    ## serialize a=1L, b=2L, c=3L, XDR: true
    my $abc_123l_xdr = "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\2\x0d\0\0\0\3\0\0\0" .
        "\1\0\0\0\2\0\0\0\3\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\5" .
        "\x6e\x61\x6d\x65\x73\0\0\0\x10\0\0\0\3\0\4\0\x09\0\0\0\1\x61\0\4\0" .
        "\x09\0\0\0\1\x62\0\4\0\x09\0\0\0\1\x63\0\0\0\xfe";

    is(unserialize($abc_123l_xdr)->[0],
       Statistics::R::REXP::Integer->new(
           elements => [ 1, 2, 3 ],
           attributes => {
               names => Statistics::R::REXP::Character->new(['a', 'b', 'c'])
           }),
       'names att - xdr');


    ## handling of negative integer vector length
    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x0d\xff\xff\xff\xff" .
                    "\0\0\0\0" . "\0\0\0\1")
         }, qr/TODO: Long vectors are not supported/, 'long length');

    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x0d\xff\xff\xff\x0")
         }, qr/Negative length/, 'negative length');
};


subtest 'double vectors' => sub {
    plan tests => 7;
    
    ## serialize 1234.56, XDR: true
    my $noatt_123456_xdr = Statistics::R::IO::ParserState->new(
        data => "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x0e\0\0\0\1\x40\x93\x4a".
        "\x3d\x70\xa3\xd7\x0a");

    is_deeply(bind(Statistics::R::IO::REXPFactory::header,
                   sub {
                       Statistics::R::IO::REXPFactory::unpack_object_info
                   })->($noatt_123456_xdr)->[0],
              { is_object => 0,
                has_attributes => 0,
                has_tag => 0,
                object_type => 14,
                levels => 0,
                flags => 14 },
              'header plus object info - no atts');

    is(ShortDoubleVector->new([ 1234.56 ]),
       unserialize($noatt_123456_xdr->data)->[0],
       'no atts');


    ## serialize 1234.56, XDR: false
    my $noatt_123456_bin = Statistics::R::IO::ParserState->new(
        data => "\x42\x0a\2\0\0\0\2\0\3\0\0\3\2\0\x0e\0\0\0\1\0\0\0\x0a\xd7\xa3".
        "\x70\x3d\x4a\x93\x40");

    is_deeply(bind(Statistics::R::IO::REXPFactory::header,
                   sub {
                       Statistics::R::IO::REXPFactory::unpack_object_info
                   })->($noatt_123456_bin)->[0],
              { is_object => 0,
                has_attributes => 0,
                has_tag => 0,
                object_type => 14,
                levels => 0,
                flags => 14 },
              'binary header plus object info - no atts');

    is(ShortDoubleVector->new([ 1234.56 ]),
       unserialize($noatt_123456_bin->data)->[0],
       'no atts - binary');


    ## serialize foo=1234.56, XDR: true
    my $foo_123456_xdr = "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\2\x0e\0\0\0\1\x40\x93\x4a" .
        "\x3d\x70\xa3\xd7\x0a\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\5\x6e\x61\x6d\x65" .
        "\x73\0\0\0\x10\0\0\0\1\0\4\0\x09\0\0\0\3\x66\x6f\x6f\0\0\0\xfe";

    is(ShortDoubleVector->new(
           elements => [ 1234.56 ],
           attributes => {
               names => Statistics::R::REXP::Character->new(['foo'])
           }),
       unserialize($foo_123456_xdr)->[0],
       'names att - xdr');


    ## handling of negative double vector length
    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x0e\xff\xff\xff\xff" .
                    "\0\0\0\0" . "\0\0\0\1")
         }, qr/TODO: Long vectors are not supported/, 'long length');

    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x0e\xff\xff\xff\x0")
         }, qr/Negative length/, 'negative length');
};

subtest 'character vectors' => sub {
    plan tests => 7;
    
    ## serialize letters[1:3], XDR: true
    my $noatt_abc_xdr = Statistics::R::IO::ParserState->new(
        data => "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x10\0\0\0\3\0\4\0" .
        "\x09\0\0\0\1\x61\0\4\0\x09\0\0\0\1\x62\0\4\0\x09\0\0\0\1\x63");

    is_deeply(bind(Statistics::R::IO::REXPFactory::header,
                   sub {
                       Statistics::R::IO::REXPFactory::unpack_object_info
                   })->($noatt_abc_xdr)->[0],
              { is_object => 0,
                has_attributes => 0,
                has_tag => 0,
                object_type => 16,
                levels => 0,
                flags => 16 },
              'header plus object info - no atts');

    is(unserialize($noatt_abc_xdr->data)->[0],
       Statistics::R::REXP::Character->new([ 'a', 'b', 'c' ]),
       'no atts');


    ## serialize A='a', B='b', C='c', XDR: true
    my $ABC_abc_xdr = "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\2\x10\0\0\0\3\0\4\0" .
        "\x09\0\0\0\1\x61\0\4\0\x09\0\0\0\1\x62\0\4\0\x09\0\0\0\1\x63\0" .
        "\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\5\x6e\x61\x6d\x65\x73\0\0\0\x10\0" .
        "\0\0\3\0\4\0\x09\0\0\0\1\x41\0\4\0\x09\0\0\0\1\x42\0\4\0\x09" .
        "\0\0\0\1\x43\0\0\0\xfe";

    is(unserialize($ABC_abc_xdr)->[0],
       Statistics::R::REXP::Character->new(
           elements => [ 'a', 'b', 'c' ],
           attributes => {
               names => Statistics::R::REXP::Character->new(['A', 'B', 'C'])
           }),
       'names att - xdr');


    ## handling of negative character vector length
    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x10\xff\xff\xff\xff" .
                    "\0\0\0\0" . "\0\0\0\1")
         }, qr/TODO: Long vectors are not supported/, 'long length');

    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x10\xff\xff\xff\x0")
         }, qr/Negative length/, 'negative length');


    ## handling of negative charsxp length
    
    # Length "-1" is used as the encoding for a NA string
    is(unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x10\0\0\0\1".
                   "\0\4\0\x09" . "\xff\xff\xff\xff")->[0],
       Statistics::R::REXP::Character->new(
           elements => [ undef ]),
       'NA_STRING');
    
    # Other negative lengths are illegal
    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x10\0\0\0\1".
                    "\0\4\0\x09" . "\xff\xff\xff\xf0")
         }, qr/Negative length/, 'negative charsxp length');
};


subtest 'raw vectors' => sub {
    plan tests => 4;
    
    ## serialize as.raw(c(1:3, 255, 0), XDR: true
    my $noatt_raw_xdr = "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x18\0\0\0\5" .
        "\1\2\3\xff\0";

    is(unserialize($noatt_raw_xdr)->[0],
       Statistics::R::REXP::Raw->new([ 1, 2, 3, 255, 0 ]),
       'xdr');

    my $noatt_raw_bin = "\x42\x0a\2\0\0\0\2\0\3\0\0\3\2\0\x18\0\0\0\5\0\0\0" .
        "\1\2\3\xff\0";

    is(unserialize($noatt_raw_bin)->[0],
       Statistics::R::REXP::Raw->new([ 1, 2, 3, 255, 0 ]),
       'binary');


    ## handling of negative raw vector length
    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x18\xff\xff\xff\xff" .
                    "\0\0\0\0" . "\0\0\0\1")
         }, qr/TODO: Long vectors are not supported/, 'long length');

    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x18\xff\xff\xff\x0")
         }, qr/Negative length/, 'negative length');
};


subtest 'generic vector (list)' => sub {
    plan tests => 5;
    
    ## serialize list(1:3, list('a', 'b', 11), 'foo'), XDR: true
    my $noatt_list_xdr = Statistics::R::IO::ParserState->new(
        data => "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x13\0\0\0\3\0\0\0" .
        "\x0d\0\0\0\3\0\0\0\1\0\0\0\2\0\0\0\3\0\0\0\x13\0\0\0\3" .
        "\0\0\0\x10\0\0\0\1\0\4\0\x09\0\0\0\1\x61\0\0\0\x10\0\0\0\1" .
        "\0\4\0\x09\0\0\0\1\x62\0\0\0\x0e\0\0\0\1\x40\x26\0\0\0\0\0\0" .
        "\0\0\0\x10\0\0\0\1\0\4\0\x09\0\0\0\3\x66\x6f\x6f");

    is_deeply(bind(Statistics::R::IO::REXPFactory::header,
                   sub {
                       Statistics::R::IO::REXPFactory::unpack_object_info
                   })->($noatt_list_xdr)->[0],
              { is_object => 0,
                has_attributes => 0,
                has_tag => 0,
                object_type => 19,
                levels => 0,
                flags => 19 },
              'header plus object info - no atts');

    is(Statistics::R::REXP::List->new([
           Statistics::R::REXP::Integer->new([ 1, 2, 3]),
           Statistics::R::REXP::List->new([
               Statistics::R::REXP::Character->new(['a']),
               Statistics::R::REXP::Character->new(['b']),
               ShortDoubleVector->new([11]) ]),
           Statistics::R::REXP::Character->new(['foo']) ]),
       unserialize($noatt_list_xdr->data)->[0],
       'no atts');


    ## serialize list(foo=1:3, list('a', 'b', 11), bar='foo'), XDR: true
    my $foobar_list_xdr = "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\2\x13\0\0\0\3\0\0\0" .
        "\x0d\0\0\0\3\0\0\0\1\0\0\0\2\0\0\0\3\0\0\0\x13\0\0\0\3" .
        "\0\0\0\x10\0\0\0\1\0\4\0\x09\0\0\0\1\x61\0\0\0\x10\0\0\0\1" .
        "\0\4\0\x09\0\0\0\1\x62\0\0\0\x0e\0\0\0\1\x40\x26\0\0\0\0\0\0" .
        "\0\0\0\x10\0\0\0\1\0\4\0\x09\0\0\0\3\x66\x6f\x6f\0\0\4\2\0\0" .
        "\0\1\0\4\0\x09\0\0\0\5\x6e\x61\x6d\x65\x73\0\0\0\x10\0\0\0\3\0\4" .
        "\0\x09\0\0\0\3\x66\x6f\x6f\0\4\0\x09\0\0\0\0\0\4\0\x09\0\0\0\3" .
        "\x62\x61\x72\0\0\0\xfe";


    is(Statistics::R::REXP::List->new(
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
       unserialize($foobar_list_xdr)->[0],
       'names att - xdr');


    ## handling of negative generic vector length
    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x13\xff\xff\xff\xff" .
                    "\0\0\0\0" . "\0\0\0\1")
         }, qr/TODO: Long vectors are not supported/, 'long length');

    like(exception {
        unserialize("\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\x13\xff\xff\xff\x0")
         }, qr/Negative length/, 'negative length');
};


subtest 'matrix' => sub {
    plan tests => 3;

    ## serialize matrix(-1:4, 2, 3), XDR: true
    my $noatt_mat_xdr =
        "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\2\x0d\0\0\0\6\xff\xff\xff" .
        "\xff\0\0\0\0\0\0\0\1\0\0\0\2\0\0\0\3\0\0\0\4\0\0\4\2" .
        "\0\0\0\1\0\4\0\x09\0\0\0\3\x64\x69\x6d\0\0\0\x0d\0\0\0\2\0\0" .
        "\0\2\0\0\0\3\0\0\0\xfe";
    is(unserialize($noatt_mat_xdr)->[0],
       Statistics::R::REXP::Integer->new(
           elements => [ -1, 0, 1, 2, 3, 4 ],
           attributes => {
               dim => Statistics::R::REXP::Integer->new([2, 3])
           }),
       'int matrix no atts - xdr');

    ## serialize matrix(-1:4, 2, 3), XDR: false
    my $noatt_mat_noxdr =
        "\x42\x0a\2\0\0\0\2\0\3\0\0\3\2\0\x0d\2\0\0\6\0\0\0\xff\xff\xff" .
        "\xff\0\0\0\0\1\0\0\0\2\0\0\0\3\0\0\0\4\0\0\0\2\4\0\0" .
        "\1\0\0\0\x09\0\4\0\3\0\0\0\x64\x69\x6d\x0d\0\0\0\2\0\0\0\2\0" .
        "\0\0\3\0\0\0\xfe\0\0\0";
    is(unserialize($noatt_mat_noxdr)->[0],
       Statistics::R::REXP::Integer->new(
           elements => [ -1, 0, 1, 2, 3, 4 ],
           attributes => {
               dim => Statistics::R::REXP::Integer->new([2, 3])
           }),
       'int matrix no atts - binary');

    ## serialize matrix(-1:4, 2, 3, dimnames=list(c('a', 'b'))), XDR: true
    my $ab_mat_xdr =
        "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\2\x0d\0\0\0\6\xff\xff\xff" .
        "\xff\0\0\0\0\0\0\0\1\0\0\0\2\0\0\0\3\0\0\0\4\0\0\4\2" .
        "\0\0\0\1\0\4\0\x09\0\0\0\3\x64\x69\x6d\0\0\0\x0d\0\0\0\2\0\0" .
        "\0\2\0\0\0\3\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\x08\x64\x69\x6d" .
        "\x6e\x61\x6d\x65\x73\0\0\0\x13\0\0\0\2\0\0\0\x10\0\0\0\2\0\4\0\x09" .
        "\0\0\0\1\x61\0\4\0\x09\0\0\0\1\x62\0\0\0\xfe\0\0\0\xfe";
    is(unserialize($ab_mat_xdr)->[0],
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


subtest 'pairlist' => sub {
    plan tests => 5;

    my $names_attribute_pairlist = Statistics::R::IO::ParserState->new(
        data => "\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\5".
        "\x6e\x61\x6d\x65\x73\0\0\0\x10\0\0\0\3\0\4\0\x09\0\0\0\1\x61\0\4\0".
        "\x09\0\0\0\1\x62\0\4\0\x09\0\0\0\1\x63\0\0\0\xfe");

    is_deeply(Statistics::R::IO::REXPFactory::unpack_object_info->($names_attribute_pairlist)->[0],
              { is_object => 0,
                has_attributes => 0,
                has_tag => 1<<10,
                object_type => 2,
                levels => 0,
                flags => 1026 },
              'object info - names');

    is_deeply(Statistics::R::IO::REXPFactory::object_content->($names_attribute_pairlist)->[0],
              [ { tag => Statistics::R::REXP::Symbol->new('names'),
                  value => Statistics::R::REXP::Character->new([ 'a', 'b', 'c' ]) } ],
              'names attribute');


    ## a more complicated pairlist:
    ## attributes from a matrix(1:6, 2, 3, dimnames=list(c('a', 'b'))),
    ## i.e., dims = c(2,3) and dimnames = list(c('a', 'b'), NULL)
    my $matrix_dims_attribute_pairlist = Statistics::R::IO::ParserState->new(
        data => "\0\0\4\2" .
        "\0\0\0\1\0\4\0\x09\0\0\0\3\x64\x69\x6d\0\0\0\x0d\0\0\0\2\0\0" .
        "\0\2\0\0\0\3\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\x08\x64\x69\x6d" .
        "\x6e\x61\x6d\x65\x73\0\0\0\x13\0\0\0\2\0\0\0\x10\0\0\0\2\0\4\0\x09" .
        "\0\0\0\1\x61\0\4\0\x09\0\0\0\1\x62\0\0\0\xfe\0\0\0\xfe");

    is_deeply(Statistics::R::IO::REXPFactory::unpack_object_info->($matrix_dims_attribute_pairlist)->[0],
              { is_object => 0,
                has_attributes => 0,
                has_tag => 1<<10,
                object_type => 2,
                levels => 0,
                flags => 1026 },
              'object info - matrix dims');

    is_deeply(Statistics::R::IO::REXPFactory::object_content->($matrix_dims_attribute_pairlist)->[0],
              [ { tag => Statistics::R::REXP::Symbol->new('dim'),
                  value => Statistics::R::REXP::Integer->new([ 2, 3 ]) },
                { tag => Statistics::R::REXP::Symbol->new('dimnames'),
                  value => Statistics::R::REXP::List->new([
                      Statistics::R::REXP::Character->new([ 'a', 'b' ]),
                      Statistics::R::REXP::Null->new ]) } ],
              'matrix dims attributes');

    ## yet more complicated pairlist:
    ## attributes from the head of the 'cars' data frame,
    ## i.e., names = ['speed', 'dist'], row.names = 1..6, class = 'data.frame'
    my $cars_attribute_pairlist = Statistics::R::IO::ParserState->new(
        data => "\0\0\4\2" .
        "\0\0\0\1\0\4\0\x09\0\0\0\5" .
        "\x6e\x61\x6d\x65\x73\0\0\0\x10\0\0\0\2\0\4\0\x09\0\0\0\5\x73\x70\x65\x65" .
        "\x64\0\4\0\x09\0\0\0\4\x64\x69\x73\x74\0\0\4\2\0\0\0\1\0\4\0\x09" .
        "\0\0\0\x09\x72\x6f\x77\x2e\x6e\x61\x6d\x65\x73\0\0\0\x0d\0\0\0\2\x80\0\0\0" .
        "\0\0\0\6\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\5\x63\x6c\x61\x73\x73" .
        "\0\0\0\x10\0\0\0\1\0\4\0\x09\0\0\0\x0a\x64\x61\x74\x61\x2e\x66\x72\x61\x6d" .
        "\x65\0\0\0\xfe");

    is_deeply(Statistics::R::IO::REXPFactory::object_content->($cars_attribute_pairlist)->[0],
              [ { tag => Statistics::R::REXP::Symbol->new('names'),
                  value => Statistics::R::REXP::Character->new([ 'speed', 'dist' ]) },
                { tag => Statistics::R::REXP::Symbol->new('row.names'), # compact encoding
                  value => Statistics::R::REXP::Integer->new([ undef, 6 ]) },
                { tag => Statistics::R::REXP::Symbol->new('class'),
                  value => Statistics::R::REXP::Character->new([ 'data.frame' ]) },
              ],
              'cars dataframe attributes');
};


subtest 'language object' => sub {
    plan tests => 2;
    
    my $lm_language = Statistics::R::IO::ParserState->new(
        data => "\0\0\0\6" .
        "\0\0\0\1\0\4\0\x09\0\0\0\2\x6c\x6d\0\0\4\2\0\0\0" .
        "\1\0\4\0\x09\0\0\0\7\x66\x6f\x72\x6d\x75\x6c\x61\0\0\0\6\0\0\0\1" .
        "\0\4\0\x09\0\0\0\1\x7e\0\0\0\2\0\0\0\1\0\4\0\x09\0\0\0" .
        "\3\x6d\x70\x67\0\0\0\2\0\0\0\1\0\4\0\x09\0\0\0\2\x77\x74\0\0" .
        "\0\xfe\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\4\x64\x61\x74\x61\0\0" .
        "\0\6\0\0\0\1\0\4\0\x09\0\0\0\4\x68\x65\x61\x64\0\0\0\2\0\0" .
        "\0\1\0\4\0\x09\0\0\0\6\x6d\x74\x63\x61\x72\x73\0\0\0\xfe\0\0\0\xfe");
    is(Statistics::R::IO::REXPFactory::object_content->($lm_language)->[0],
       Statistics::R::REXP::Language->new(
           elements => [
               Statistics::R::REXP::Symbol->new('lm'),
               Statistics::R::REXP::Language->new([
                   Statistics::R::REXP::Symbol->new('~'),
                   Statistics::R::REXP::Symbol->new('mpg'),
                   Statistics::R::REXP::Symbol->new('wt'),
                                                  ]),
               Statistics::R::REXP::Language->new([
                   Statistics::R::REXP::Symbol->new('head'),
                   Statistics::R::REXP::Symbol->new('mtcars'),
                                                  ]),
           ],
           attributes => {
               names => Statistics::R::REXP::Character->new(['', 'formula', 'data'])
           }),
       'lm(formula=mpg~wt, head(mtcars))');


    ## lm(mpg~wt, head(mtcars)$terms has an interesting structure:
    ## a language with multiple classes, and plenty of attributes
    my $lm_terms_language = Statistics::R::IO::ParserState->new(
        data => ("\0\0\3\6" .
                 "\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\x09\x76\x61\x72\x69\x61\x62\x6c\x65\x73" .
                 "\0\0\0\6\0\0\0\1\0\4\0\x09\0\0\0\4\x6c\x69\x73\x74\0\0\0\2\0" .
                 "\0\0\1\0\4\0\x09\0\0\0\3\x6d\x70\x67\0\0\0\2\0\0\0\1\0\4\0" .
                 "\x09\0\0\0\2\x77\x74\0\0\0\xfe\0\0\4\2\0\0\0\1\0\4\0\x09\0\0" .
                 "\0\7\x66\x61\x63\x74\x6f\x72\x73\0\0\2\x0d\0\0\0\2\0\0\0\0\0\0\0\1" .
                 "\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\3\x64\x69\x6d\0\0\0\x0d\0\0" .
                 "\0\2\0\0\0\2\0\0\0\1\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0" .
                 "\x08\x64\x69\x6d\x6e\x61\x6d\x65\x73\0\0\0\x13\0\0\0\2\0\0\0\x10\0\0\0\2" .
                 "\0\4\0\x09\0\0\0\3\x6d\x70\x67\0\4\0\x09\0\0\0\2\x77\x74\0\0\0\x10" .
                 "\0\0\0\1\0\4\0\x09\0\0\0\2\x77\x74\0\0\0\xfe\0\0\4\2\0\0\0" .
                 "\1\0\4\0\x09\0\0\0\x0b\x74\x65\x72\x6d\x2e\x6c\x61\x62\x65\x6c\x73\0\0\0\x10\0" .
                 "\0\0\1\0\4\0\x09\0\0\0\2\x77\x74\0\0\4\2\0\0\0\1\0\4\0\x09" .
                 "\0\0\0\5\x6f\x72\x64\x65\x72\0\0\0\x0d\0\0\0\1\0\0\0\1\0\0\4\2" .
                 "\0\0\0\1\0\4\0\x09\0\0\0\x09\x69\x6e\x74\x65\x72\x63\x65\x70\x74\0\0\0\x0d" .
                 "\0\0\0\1\0\0\0\1\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\x08\x72" .
                 "\x65\x73\x70\x6f\x6e\x73\x65\0\0\0\x0d\0\0\0\1\0\0\0\1\0\0\4\2\0\0" .
                 "\0\1\0\4\0\x09\0\0\0\5\x63\x6c\x61\x73\x73\0\0\0\x10\0\0\0\2\0\4" .
                 "\0\x09\0\0\0\5\x74\x65\x72\x6d\x73\0\4\0\x09\0\0\0\7\x66\x6f\x72\x6d\x75\x6c" .
                 "\x61\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\x0c\x2e\x45\x6e\x76\x69\x72\x6f\x6e" .
                 "\x6d\x65\x6e\x74\0\0\0\xfd\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\x08\x70" .
                 "\x72\x65\x64\x76\x61\x72\x73\0\0\0\6\0\0\2\xff\0\0\0\2\0\0\3\xff\0\0" .
                 "\0\2\0\0\4\xff\0\0\0\xfe\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0" .
                 "\x0b\x64\x61\x74\x61\x43\x6c\x61\x73\x73\x65\x73\0\0\2\x10\0\0\0\2\0\4\0\x09\0" .
                 "\0\0\7\x6e\x75\x6d\x65\x72\x69\x63\0\4\0\x09\0\0\0\7\x6e\x75\x6d\x65\x72\x69\x63" .
                 "\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\5\x6e\x61\x6d\x65\x73\0\0\0\x10" .
                 "\0\0\0\2\0\4\0\x09\0\0\0\3\x6d\x70\x67\0\4\0\x09\0\0\0\2\x77\x74" .
                 "\0\0\0\xfe\0\0\0\xfe\0\0\0\1\0\4\0\x09\0\0\0\1\x7e\0\0\0\2" .
                 "\0\0\3\xff\0\0\0\2\0\0\4\xff\0\0\0\xfe"));
    is(Statistics::R::IO::REXPFactory::object_content->($lm_terms_language)->[0],
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
       'terms of lm(formula=mpg~wt, head(mtcars))');
};


subtest 'data frames' => sub {
    plan tests => 1;
    
    my $cars_xdr =
        "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\3\x13\0\0\0\2\0\0\0" .
        "\x0e\0\0\0\6\x40\x10\0\0\0\0\0\0\x40\x10\0\0\0\0\0\0\x40\x1c\0\0" .
        "\0\0\0\0\x40\x1c\0\0\0\0\0\0\x40\x20\0\0\0\0\0\0\x40\x22\0\0\0" .
        "\0\0\0\0\0\0\x0e\0\0\0\6\x40\0\0\0\0\0\0\0\x40\x24\0\0\0\0" .
        "\0\0\x40\x10\0\0\0\0\0\0\x40\x36\0\0\0\0\0\0\x40\x30\0\0\0\0\0" .
        "\0\x40\x24\0\0\0\0\0\0\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\5" .
        "\x6e\x61\x6d\x65\x73\0\0\0\x10\0\0\0\2\0\4\0\x09\0\0\0\5\x73\x70\x65\x65" .
        "\x64\0\4\0\x09\0\0\0\4\x64\x69\x73\x74\0\0\4\2\0\0\0\1\0\4\0\x09" .
        "\0\0\0\x09\x72\x6f\x77\x2e\x6e\x61\x6d\x65\x73\0\0\0\x0d\0\0\0\2\x80\0\0\0" .
        "\0\0\0\6\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\5\x63\x6c\x61\x73\x73" .
        "\0\0\0\x10\0\0\0\1\0\4\0\x09\0\0\0\x0a\x64\x61\x74\x61\x2e\x66\x72\x61\x6d" .
        "\x65\0\0\0\xfe";
    is(Statistics::R::REXP::List->new(
           elements => [
               ShortDoubleVector->new([ 4, 4, 7, 7, 8, 9]),
               ShortDoubleVector->new([ 2, 10, 4, 22, 16, 10]),
           ],
           attributes => {
               names => Statistics::R::REXP::Character->new(['speed', 'dist']),
               'row.names' => Statistics::R::REXP::Integer->new([1, 2, 3, 4, 5, 6]),
               class => Statistics::R::REXP::Character->new(['data.frame']) }),
       unserialize($cars_xdr)->[0],
       'cars');
};


subtest 'Environments' => sub {
    plan tests => 3;
    
    ## .GlobalEnv:
    my $globalenv_xdr = "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\xfd";
    is(unserialize($globalenv_xdr)->[0],
       Statistics::R::REXP::GlobalEnvironment->new,
       'global');

    my $env1 = "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\4\0\0\0\0\0\0\0" .
        "\xfd\0\0\0\xfe\0\0\0\x13\0\0\0\3\0\0\4\2\0\0\0\1\0\4\0\x09" .
        "\0\0\0\1\x78\0\0\0\x10\0\0\0\1\0\4\0\x09\0\0\0\3\x66\x6f\x6f\0" .
        "\0\0\xfe\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\1\x79\0\0\0\x10\0" .
        "\0\0\1\0\4\0\x09\0\0\0\3\x62\x61\x72\0\0\0\xfe\0\0\0\xfe\0\0\0" .
        "\xfe";
    is(unserialize($env1)->[0],
       Statistics::R::REXP::Environment->new(
           frame => {
               x => Statistics::R::REXP::Character->new(['foo']),
               y => Statistics::R::REXP::Character->new(['bar']),
           },
           enclosure => Statistics::R::REXP::GlobalEnvironment->new),
       'simple');

    my $env2 = "\x58\x0a\0\0\0\2\0\3\0\2\0\2\3\0\0\0\0\4\0\0\0\0\0\0\0" .
        "\4\0\0\0\0\0\0\0\xfd\0\0\0\xfe\0\0\0\x13\0\0\0\3\0\0\4\2" .
        "\0\0\0\1\0\4\0\x09\0\0\0\1\x78\0\0\0\x10\0\0\0\1\0\4\0\x09" .
        "\0\0\0\3\x66\x6f\x6f\0\0\0\xfe\0\0\4\2\0\0\0\1\0\4\0\x09\0\0" .
        "\0\1\x79\0\0\0\x10\0\0\0\1\0\4\0\x09\0\0\0\3\x62\x61\x72\0\0\0" .
        "\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\x13\0\0\0\x1d\0\0\0\xfe" .
        "\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\4\2\0\0\3\xff\0\0\0\x0d\0" .
        "\0\0\1\0\0\0\7\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0" .
        "\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0" .
        "\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe" .
        "\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0\0\0\xfe\0" .
        "\0\0\xfe\0\0\0\xfe\0\0\0\xfe";
    is(unserialize($env2)->[0],
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
       'nested');
};
