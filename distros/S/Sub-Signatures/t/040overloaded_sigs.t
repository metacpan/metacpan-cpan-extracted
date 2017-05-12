#!/usr/bin/perl
# '$Id: 20overloaded_sigs.t,v 1.2 2004/12/05 21:19:33 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 2;

BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
}
use Sub::Signatures;

sub foo($bar) {
    $bar;
}

is_deeply foo({this => 'one'}), {this => 'one'},    
    '... even if we call it by its original name';

sub foo($bar, $baz) {
    return [$bar, $baz];
}

is_deeply foo(1,2), [1,2],
    '... even if we call it by its original name';
