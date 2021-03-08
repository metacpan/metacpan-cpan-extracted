#!perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Path::Tiny qw(path);
use lib path(__FILE__)->sibling('lib')->stringify;

use T::SomeClass;

my $t = T::SomeClass->new();

$t->uri('http://nuts');
is( ref $t->uri(), 'URI::http', 'Coerced URI from string' );

is( exception { $t->username('fred') }, undef, 'no exception for valid username' );

like( exception { $t->username('bad:vibes') },
      qr/^\QValue "bad:vibes" did not pass type constraint "Username"/,
      'exception for invalid username' );

my $body_part = { name => 'foo', filename => path(__FILE__) };
$t->body_part($body_part);
pass('set BodyPart');
$t->single_body_part([$body_part]);
pass('set SingleBodyPart');

like( exception { $t->body_part({}) }, qr/^\QReference {} did not pass type constraint/,
      'exception for invalid body part');

like( exception { $t->body_part({ name => 'foo', data => 'xyz', filename => path(__FILE__)}) },
      qr/^\QA body part needs either data OR a filename/,
      'exception for invalid body part');

like( exception { $t->single_body_part([]) }, qr/^Exactly one archive to add is needed/,
      'exception for invalid single body part');

like( exception { $t->single_body_part([{}]) }, qr/^\QReference [{}] did not pass type constraint/,
      'exception for invalid single body part contents');

had_no_warnings();
done_testing();
