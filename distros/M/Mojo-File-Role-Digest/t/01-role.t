use strict;
use warnings;
use utf8;
use v5.24;

use FindBin;
use Test::More;
use Mojo::File;

ok my $class = Mojo::File->with_roles('+Digest'), 'Create class';
ok $class->does('Mojo::File::Role::Digest'), 'Role is applied';
can_ok $class, $_, for qw|md5_sum quickxor_hash sha1_sum sha256_sum|;

my %digests = (
  'longer_text.txt' => {
    md5    => '7d766e0a8e5578b67adb103fd716206b',
    qx     => 'MyNPbFMLAm5Ol0JF4iqBwtfLtf8=',
    sha1   => 'f39e71c32680671dfa7f3012230cb7cb60cc6ca0',
    sha256 => '1e81a2ece02f4d6b4cb4731a57cfde7755170799d41f2e9c01cfff259dad1b13',
  },
  'perl_camel.png' => {
    md5    => 'bb2b38eda5ea3d4807f7b5a0a903c9a1',
    qx     => 'btGJtuvrt57YpSgEUpMJKkNQywA=',
    sha1   => 'c19f53f4c4dc77d1c47dbdc3ec4d96220f88c229',
    sha256 => '700ed00e450167a266ef0611263f4733e28d7782dc66dfffb252101833967c35',
  },
  'perl_logo.svg' => {
    md5    => '768b7635b5d973eec7e397b1498fbc9f',
    qx     => 't+ivKo9P9+OBdXUVle2LDwOmIzI=',
    sha1   => '452d431b108d196d2b288eaeb608fda7ef7d71ca',
    sha256 => 'ef19f97bf9c63e15743b103374302fed4ff8db62808817dbcba584e7efe270c7',
  },
  'short_text.txt' => {
    md5    => 'c07d31a920faac8e48bac5c1589a3b0f',
    qx     => 'QQDBHNDwBjnQAQR0JAMe6AAAAAA=',
    sha1   => 'b72d2dff7a76afe102dd538defd2cd1d9c81aeef',
    sha256 => 'ebac0ba4824f8da924dce83a103570a2382f04992e3038787cae889039abcbfe',
  },
);

for my $path (sort keys %digests) {
  ok my $file = $class->new("$FindBin::Bin/resources/$path"), "File object for $path";

  for my $type (qw|md5 sha1 sha256|) {
    my $fn = "${type}_sum";
    is $file->$fn, $digests{$path}{$type}, "$path: correct $type sum";
  }

  if ($file->SUPPORTS_QX) {
    is $file->quickxor_hash, $digests{$path}{qx}, "$path: correct quickxor hash";
  } else {
    eval { $file->quickxor_hash; };
    like $@, qr/Digest::QuickXor not available!/, "$path: QX not available, correct error";
  }
}

done_testing();
