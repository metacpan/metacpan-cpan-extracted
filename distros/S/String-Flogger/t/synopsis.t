#!perl
use strict;
use warnings;
use Test::More tests => 5;
use String::Flogger qw(flog);

is(
  flog('simple!'),
  'simple!',
);

is(
  flog([ 'slightly %s complex', 'more' ]),
  'slightly more complex',
);

is(
  flog([ 'and inline some data: %s', { look => 'data!' } ]),
  'and inline some data: {{{"look": "data!"}}}',
);

is(
  flog([ 'and we can defer evaluation of %s if we want', sub { 'stuff' } ]),
  'and we can defer evaluation of stuff if we want',
);

is(
  flog(sub { 'while avoiding sprintfiness, if needed' }),
  'while avoiding sprintfiness, if needed',
);

