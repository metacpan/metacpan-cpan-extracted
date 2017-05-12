#!/usr/bin/perl -w

use strict;
use Benchmark           qw[];
use String::Numeric::PP qw[];
use String::Numeric::XS qw[];
use Scalar::Util        qw[];

{
    my $string = '12345.12345';

    Benchmark::cmpthese( -2, {
        'SN::PP::is_numeric' => sub { 
            String::Numeric::PP::is_numeric($string);
        },
        'SN::XS::is_numeric' => sub { 
            String::Numeric::XS::is_numeric($string);
        },
        'SU::looks_like_number' => sub { 
            Scalar::Util::looks_like_number($string);
        }
    });
}

{
    my $string = '12345';

    Benchmark::cmpthese( -2, {
        'pp is_uint16' => sub { 
            String::Numeric::PP::is_uint16($string);
        },
        'xs is_uint16' => sub { 
            String::Numeric::XS::is_uint16($string);
        }
    });
}


