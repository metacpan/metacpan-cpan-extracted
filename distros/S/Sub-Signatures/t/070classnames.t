#!/usr/bin/perl
# '$Id: 65classnames.t,v 1.2 2004/12/05 21:19:33 ovid Exp $';
use warnings;
use strict;

use Test::More tests => 6;
#use Test::More 'no_plan';
use Test::Exception;

my $CLASS;

BEGIN {

    #    $ENV{DEBUG} = 1;
    chdir 't' if -d 't';
    unshift @INC => '../lib', 'test_lib';
    $CLASS = 'Sub::Signatures';
    use_ok('ClassA::Subclass') or die;
}
use Sub::Signatures;

my $object = ClassA::Subclass->new;
isa_ok $object, 'ClassA::Subclass';

sub this($o, $ref) {
    $o->foo($ref);
}

is this( $object, [] ), 'arrayref with 0 elements',
  '... and we should be able to use inheritance';

is_deeply this( $object, {} ), { this => 1 },
  '... but dispatching is handled manually';

ok my $code = $object->subref(3),
  'Methods which return anonymous subroutines should work';
is $code->('Ovid'), "3 Ovid", '... and they should behave correctly';
