use Test::More tests => 46;

use lib 't/lib';
use PathTest;

my $opts = {};

test_pathing($opts,
   [qw(
      a[4]
      a[1].b.c.d
      a[3].turnip
      a[0][1][1][1][1].[2].too.long
   )],
   [qw(
      a[4]
      a[1].b.c.d
      a[3].turnip
      a[0][1][1][1][1][2].too.long
   )],
   'Basic',
);

test_pathing($opts,
   [qw(
      [4]
      [1].b.c.d
      [3].turnip
      [0][1][1][1][1].[2].too.long
   )],
   [qw(
      [4]
      [1].b.c.d
      [3].turnip
      [0][1][1][1][1][2].too.long
   )],
   'Array-is-first',
);

test_pathing($opts,
   [
      q{"This can't be a terrible mistake"[0].value},
      q{'"Oh, but it can..." said the spider'.[0].value},
   ],
   [
      q{"This can't be a terrible mistake"[0].value},
      q{'"Oh, but it can..." said the spider'[0].value},
   ],
   'Quoted without normalize',
);

test_pathing($opts,
   [
      'a.b...c[0].""."".' . "''",
   ],
   [
      'a.b...c[0].""."".' . "''",
   ],
   'Zero-length keys without normalize',
);

$opts = { auto_normalize => 1 };

test_pathing($opts,
   [
      q{'This can\'t be a terrible mistake'[0].value},
      q{"\"Oh, but it can...\" said the spider".[0].value},
   ],
   [
      q{"This can't be a terrible mistake"[0].value},
      q{'"Oh, but it can..." said the spider'[0].value},
   ],
   'Quoted with normalize',
);

test_pathing($opts,
   [
      'a.b...c[0].""."".' . "''",
   ],
   [
      "a.b.''.''.c[0].''.''.''",
   ],
   'Zero-length keys with normalize',
);

test_pathing_failures($opts,
   [qw(
      123[hash].1111
      "foo".["bar"]
      aaa[999999999].bbb
   ),
      '   aaa.bbb.ccc[1]   ',
   ],
   [
      qr/^Found unparsable step/,
      qr/^Found unparsable step/,
      qr/^Found unparsable step/,
      qr/^Found unparsable step/,
   ],
   'Fails',
);
