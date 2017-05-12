#!perl -T
use strict;
use warnings;

use Test::More tests => 28;

BEGIN { use_ok('String::Truncate'); }

package String::Truncate::ELIDE;

eval { String::Truncate->import(qw(elide)); };

main::ok(__PACKAGE__->can('elide'),  "elide is exported on request");
main::ok(!__PACKAGE__->can('trunc'), "trunc is not exported sans request");

package String::Truncate::TRUNC;

String::Truncate->import(qw(trunc));

main::ok(__PACKAGE__->can('trunc'),  "trunc is exported on request");
main::ok(!__PACKAGE__->can('elide'), "elide is not exported sans request");

package String::Truncate::BOTH;

String::Truncate->import(qw(trunc elide));

main::ok(__PACKAGE__->can('trunc'), "trunc is exported on request");
main::ok(__PACKAGE__->can('elide'), "elide is exported on request");

package String::Truncate::ALL;

eval { String::Truncate->import(qw(:all)); };

main::ok(__PACKAGE__->can('trunc'), "trunc is exported for ':all'");
main::ok(__PACKAGE__->can('elide'), "elide is exported for ':all'");

package String::Truncate::JUNK;

eval { String::Truncate->import(qw(huggalugga)); };
main::like(
  $@,
  qr/"huggalugga" is not exported by the String::Truncate module/,
  "don't accept bogus exports"
);

package String::Truncate::DEFAULT_ELIDE;

String::Truncate->import(elide => defaults => { marker => '--', length => 10 });

main::ok(__PACKAGE__->can('elide'),  "elide is exported on request");
main::ok(!__PACKAGE__->can('trunc'), "trunc is not exported sans request");

main::is(
  elide("123456789ABCDEF"),
  "12345678--",
  "elide with default marker/length",
);

package String::Truncate::DEFAULT_TRUNC;

String::Truncate->import(
  trunc => defaults => { truncate => 'left', length => 10 }
);

main::ok(__PACKAGE__->can('trunc'),  "trunc is exported on request");
main::ok(!__PACKAGE__->can('elide'), "elide is not exported sans request");

main::is(
  trunc("123456789ABCDEF"),
  "6789ABCDEF",
  "trunc with default truncate/length",
);

package String::Truncate::DEFAULT_ALL;

String::Truncate->import(
  ':all' => defaults => { truncate => 'left', length => 10, marker => '--' }
);

main::ok(__PACKAGE__->can('trunc'),  "trunc is exported on request");
main::ok(__PACKAGE__->can('elide'),  "elide is exported on request");

main::is(
  elide("123456789ABCDEF"),
  "--89ABCDEF",
  "elide with default truncate/length",
);

main::is(
  elide("123456789ABCDEF", 11),
  "--789ABCDEF",
  "elide with overridden default length",
);


main::is(
  elide("123456789ABCDEF", undef, { truncate => 'right' }),
  "12345678--",
  "elide with overridden default truncate",
);

main::is(
  trunc("123456789ABCDEF"),
  "6789ABCDEF",
  "trunc with default truncate/length",
);

package String::Truncate::DEFAULT_ARG;

String::Truncate->import(
  -all => { truncate => 'left', length => 10, marker => '--' }
);

main::ok(__PACKAGE__->can('trunc'),  "trunc is exported on request");
main::ok(__PACKAGE__->can('elide'),  "elide is exported on request");

main::is(
  elide("123456789ABCDEF"),
  "--89ABCDEF",
  "elide with default truncate/length",
);

main::is(
  elide("123456789ABCDEF", 11),
  "--789ABCDEF",
  "elide with overridden default length",
);


main::is(
  elide("123456789ABCDEF", undef, { truncate => 'right' }),
  "12345678--",
  "elide with overridden default truncate",
);

main::is(
  trunc("123456789ABCDEF"),
  "6789ABCDEF",
  "trunc with default truncate/length",
);
