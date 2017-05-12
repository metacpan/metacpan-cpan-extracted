#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Net::SFTP::Foreign;

plan tests => 17;

my $s = 'Net::SFTP::Foreign';

is($s->join('/', '.'), '/');
is($s->join('/.', '.'), '/');
is($s->join('/./', '.'), '/');
is($s->join('/./.', '.'), '/');
is($s->join('/.', '././.'), '/');
is($s->join('.', '/./'), '/');
is($s->join('./', '././'), '.');
is($s->join('./.', '././'), '.');
is($s->join('./.', '././.'), '.');
is($s->join('foo', '/./'), '/');
is($s->join('foo', '././'), 'foo');
is($s->join('./foo/.', '././'), 'foo');
is($s->join('./foo/./bar/.', '././'), 'foo/./bar');
is($s->join('//foo', 'bar'), '//foo/bar');
is($s->join('//foo', '/bar'), '/bar');
is($s->join('//foo', '//bar'), '//bar');
is($s->join('/foo', './bar/.'), '/foo/bar');
