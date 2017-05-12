#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 4;

BEGIN { use_ok 'Resource::Dispose' };


{
    eval q{
        resource;
    };
    like $@, qr/^Syntax error/;
}

{
    eval q{
        resource keyword;
    };
    like $@, qr/^Syntax error/;
}

{
    eval q{
        resource my(keyword);
    };
    like $@, qr/^Can't declare constant item/; #'
}
