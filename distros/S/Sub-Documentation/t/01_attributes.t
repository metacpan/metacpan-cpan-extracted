#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 1;
use Test::Differences;
use Sub::Documentation 'get_documentation';

package Foo;
use Sub::Documentation::Attributes;
our $__DOC : Purpose(test class for demonstrating doc attributes) :
  Author(Marcel Gruenauer <marcel@cpan.org>);
our $VERSION = '0.05';
our %blah : Purpose(the blah hash);
our $say : Purpose(what we say) : Default(abc);

sub new : Purpose(constructs a %p object) : Returns(the %p object) :
  Throws(exception 1) : Throws(exception 2) : Throws(exception 3) {
    bless {}, shift;
}

sub say : Purpose(prints its arguments, appending a newline) :
  Param(@text; the text to be printed) : Deprecated(use Perl6::Say instead) {
    my $self = shift;
    print @_, "\n";
}

package main;
my $expected = [
    {   'documentation' => 'test class for demonstrating doc attributes',
        'name'          => '__DOC',
        'type'          => 'purpose',
        'glob_type'     => 'SCALAR',
        'package'       => 'Foo'
    },
    {   'documentation' => 'Marcel Gruenauer <marcel@cpan.org>',
        'name'          => '__DOC',
        'type'          => 'author',
        'glob_type'     => 'SCALAR',
        'package'       => 'Foo'
    },
    {   'documentation' => 'the blah hash',
        'name'          => 'blah',
        'type'          => 'purpose',
        'glob_type'     => 'HASH',
        'package'       => 'Foo'
    },
    {   'documentation' => 'what we say',
        'name'          => 'say',
        'type'          => 'purpose',
        'glob_type'     => 'SCALAR',
        'package'       => 'Foo'
    },
    {   'documentation' => 'abc',
        'name'          => 'say',
        'type'          => 'default',
        'glob_type'     => 'SCALAR',
        'package'       => 'Foo'
    },
    {   'documentation' => 'constructs a Foo object',
        'name'          => 'new',
        'type'          => 'purpose',
        'glob_type'     => 'CODE',
        'package'       => 'Foo'
    },
    {   'documentation' => 'the Foo object',
        'name'          => 'new',
        'type'          => 'returns',
        'glob_type'     => 'CODE',
        'package'       => 'Foo'
    },
    {   'documentation' => 'exception 1',
        'name'          => 'new',
        'type'          => 'throws',
        'glob_type'     => 'CODE',
        'package'       => 'Foo'
    },
    {   'documentation' => 'exception 2',
        'name'          => 'new',
        'type'          => 'throws',
        'glob_type'     => 'CODE',
        'package'       => 'Foo'
    },
    {   'documentation' => 'exception 3',
        'name'          => 'new',
        'type'          => 'throws',
        'glob_type'     => 'CODE',
        'package'       => 'Foo'
    },
    {   'documentation' => 'prints its arguments, appending a newline',
        'name'          => 'say',
        'type'          => 'purpose',
        'glob_type'     => 'CODE',
        'package'       => 'Foo'
    },
    {   'documentation' => '@text; the text to be printed',
        'name'          => 'say',
        'type'          => 'param',
        'glob_type'     => 'CODE',
        'package'       => 'Foo'
    },
    {   'documentation' => 'use Perl6::Say instead',
        'name'          => 'say',
        'type'          => 'deprecated',
        'glob_type'     => 'CODE',
        'package'       => 'Foo'
    }
];
eq_or_diff(scalar(get_documentation()), $expected, 'doc hash');
