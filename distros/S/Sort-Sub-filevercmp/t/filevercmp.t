#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'filevercmp',
    input     => [
        '.Foo-1.3.tgz',
        'foo-bar-1.2a.tar.gz',
        'foo-bar-1.2.tgz',
        'foo-bar-1.10.zip',
        '.foo-1.2.tar.gz',
        '.foo-1.4.tgz',
    ],

    output    => [
        '.Foo-1.3.tgz',
        '.foo-1.2.tar.gz',
        '.foo-1.4.tgz',
        'foo-bar-1.2.tgz',
        'foo-bar-1.2a.tar.gz',
        'foo-bar-1.10.zip',
    ],
    output_i   => [
        '.foo-1.2.tar.gz',
        '.Foo-1.3.tgz',
        '.foo-1.4.tgz',
        'foo-bar-1.2.tgz',
        'foo-bar-1.2a.tar.gz',
        'foo-bar-1.10.zip',
    ],
    output_ir   => [
        'foo-bar-1.10.zip',
        'foo-bar-1.2a.tar.gz',
        'foo-bar-1.2.tgz',
        '.foo-1.4.tgz',
        '.Foo-1.3.tgz',
        '.foo-1.2.tar.gz',
    ],
);

done_testing;
