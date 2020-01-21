#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

use Object::Depot;

subtest no_class => sub{
    my $depot = Object::Depot->new();

    like(
      dies{ $depot->fetch() },
      qr{No key was passed to fetch},
      'fetch without a key fails',
    );

    is(
      $depot->fetch('foo'), undef,
      'fetching an unkown key returns undef',
    );

    { package Test::basics::no_class; use Moo }
    my $object = Test::basics::no_class->new();
    $depot->store( foo => $object );

    is(
      $depot->fetch('foo'), $object,
      'fetched a known key',
    );

    $depot->remove( 'foo' );

    is(
      $depot->fetch('foo'), undef,
      'key was removed',
    );
};

subtest class => sub{
    { package Test::basics::class; use Moo }

    my $depot = Object::Depot->new(
        class => 'Test::basics::class',
    );

    like(
      dies{ $depot->fetch() },
      qr{No key was passed to fetch},
      'fetch without a key fails',
    );

    my $object = $depot->fetch('foo');

    ref_is(
      $depot->fetch('foo'), $object,
      'fetching an unkown key works',
    );

    $depot->remove( 'foo' );

    ref_is_not(
      $depot->fetch('foo'), $object,
      'key was removed and the object re-stored',
    );
};

done_testing;
