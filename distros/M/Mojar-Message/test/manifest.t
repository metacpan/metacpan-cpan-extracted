use Mojo::Base -strict;
use Test::More;
use ExtUtils::Manifest;

plan skip_all => 'set RELEASE_TESTING to enable this test (developer only!)'
  unless $ENV{RELEASE_TESTING};

is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';

done_testing;
