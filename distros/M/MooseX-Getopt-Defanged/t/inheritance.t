#!/usr/bin/env perl

use 5.010;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.18.0');


use File::Spec::Functions qw< catdir >;


use Test::More tests => 1;
use Test::Exception;


use lib catdir( qw< t inheritance.d lib > );


use MooseX::Getopt::Defanged::SubClass qw< >;


lives_ok(
    sub {
        MooseX::Getopt::Defanged::SubClass->new()->parse_command_line(
            [
                qw<
                    --test1 test1
                    --test2 test2
                    --test3 test3
                    --test4 test4
                >
            ]
        );
    },
    'Inherited options work.'
);

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :
