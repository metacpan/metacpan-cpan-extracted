#!/usr/bin/perl

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);
use Test::More tests => 8;

BEGIN {
    use_ok('OIS');
    use_ok('OIS::Exception');
}

# XXX: this is wrong - the constants are "exported" no matter what
#use OIS::Exception qw(:OIS_ERROR);

# XXX: I can't figure out why &E_General won't work here;
# c.f. Ogre/examples/robot.pl where I use &ST_GENERIC;
# I don't see what the difference is that's making it not work here.
# Hmmm, it turns out that it's something to do with the tests...
# It works fine outside of tests.

my $type = OIS::Exception->E_General;

my $line = 42;
my $file = '090_exception.t';
my $text = 'a general error';

ok(looks_like_number($type), 'E_General is a number');

my $e = OIS::Exception->new($type, $text, $line, $file);
isa_ok($e, 'OIS::Exception');

is($e->eType, $type, 'exception object has correct eType');
is($e->eLine, $line, 'exception object has correct eLine');
is($e->eFile, $file, 'exception object has correct eFile');
is($e->eText, $text, 'exception object has correct eText');
