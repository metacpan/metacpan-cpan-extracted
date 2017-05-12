#!/usr/bin/perl

use strict;
use warnings;
use utf8;

my @tests;
my %templates;
BEGIN{@tests=(
  # definition of a single field
  # input parameters
  # expected output

  # required / default
  { param => 'name' },
  [],
  { name => undef, _err => [[ 'name', 'required', 1 ]] },

  { param => 'name' },
  [ name => '' ],
  { name => '', _err => [[ 'name', 'required', 1 ]] },

  { param => 'name', required => 'x' },
  [ name => '' ],
  { name => '', _err => [[ 'name', 'required', 'x' ]] },

  { param => 'name', required => 0 },
  [ name => '' ],
  { name => '' },

  { param => 'name', required => 0, default => undef },
  [ name => '' ],
  { name => undef },

  { param => 'name' },
  [ name => '0' ],
  { name => '0' },

  # rmwhitespace
  { param => 'name' },
  [ name => " Va\rlid \n " ],
  { name => 'Valid' },

  { param => 'name', rmwhitespace => 0 },
  [ name => " Va\rlid \n " ],
  { name => " Va\rlid \n " },

  { param => 'name' },
  [ name => '  ' ],
  { name => '', _err => [[ 'name', 'required', 1 ]] },

  # minlength / maxlength
  { param => 'msg', minlength => 2 },
  [ msg => 'ab' ],
  { msg => 'ab' },

  { param => 'msg', minlength => 2 },
  [ msg => 'a' ],
  { msg => 'a', _err => [[ 'msg', 'minlength', 2 ]] },

  { param => 'msg', maxlength => 2 },
  [ msg => 'ab' ],
  { msg => 'ab' },

  { param => 'msg', maxlength => 2 },
  [ msg => 'abc' ],
  { msg => 'abc', _err => [[ 'msg', 'maxlength', 2 ]] },

  { param => 'msg', minlength => 2 },
  [ msg => '  a  ' ],
  { msg => 'a', _err => [[ 'msg', 'minlength', 2 ]] },

  { param => 'msg', maxlength => 2 },
  [ msg => '     ab     ' ],
  { msg => 'ab' },

  # enum
  { param => 'type', enum => ['a'..'z'] },
  [ type => 'a' ],
  { type => 'a' },

  { param => 'type', enum => ['a'..'z'] },
  [ type => 'y' ],
  { type => 'y' },

  { param => 'type', enum => ['a'..'z'] },
  [ type => 'Y' ],
  { type => 'Y', _err => [[ 'type', 'enum', ['a'..'z'] ]] },

  # multi / maxcount / mincount
  { param => 'board' },
  [ board => 1, board => 2 ],
  { board => 1 }, # Not sure I like this behaviour.

  { param => 'board', multi => 1 },
  [ board => 1, board => 2 ],
  { board => [1,2] },

  { param => 'board', multi => 1 },
  [ board => 1 ],
  { board => [1] },

  { param => 'board', multi => 1 },
  [ board => '' ],
  { board => [''], _err => [[ 'board', 'required', 1 ]] },

  { param => 'board', multi => 1, template => 'int', min => 1 },
  [ board => 0 ],
  { board => [0], _err => [[ 'board', 'template', 'int' ]] },

  { param => 'board', multi => 1, maxcount => 1 },
  [ board => 1 ],
  { board => [1] },

  { param => 'board', multi => 1, maxcount => 1 },
  [ board => 1, board => 2 ],
  { board => [1,2], _err => [[ 'board', 'maxcount', 1 ]] },

  { param => 'board', multi => 1, mincount => 1 },
  [ board => 1 ],
  { board => [1] },

  { param => 'board', multi => 1, mincount => 2 },
  [ board => 1 ],
  { board => [1], _err => [[ 'board', 'mincount', 2 ]] },

  # regex
  do { my $r = qr/^[0-9a-f]{3}$/i; (
  { param => 'hex', regex => $r },
  [ hex => '0F3' ],
  { hex => '0F3' },

  { param => 'hex', regex => $r },
  [ hex => '0134' ],
  { hex => '0134', _err => [[ 'hex', 'regex', $r ]] },

  { param => 'hex', regex => $r },
  [ hex => '03X' ],
  { hex => '03X', _err => [[ 'hex', 'regex', $r ]] },

  { param => 'hex', regex => [$r, 1,2,3] },
  [ hex => '03X' ],
  { hex => '03X', _err => [[ 'hex', 'regex', [$r, 1,2,3] ]] },
  )},

  # func
  do { my $f = sub { $_[0] =~ y/a-z/A-Z/; $_[0] =~ /^$_[1]{start}/ }; (
  { param => 't', func => $f, start => 'X' },
  [ t => 'xyz' ],
  { t => 'XYZ' },

  { param => 't', func => $f, start => 'X' },
  [ t => 'zyx' ],
  { t => 'ZYX', _err => [[ 't', 'func', $f ]] },

  { param => 't', func => [$f,1,2,3], start => 'X' },
  [ t => 'zyx' ],
  { t => 'ZYX', _err => [[ 't', 'func', [$f,1,2,3] ]] },
  )},

  # template
  do {
    $templates{hex} = { regex => qr/^[0-9a-f]+$/i };
    $templates{crc32} = { template => 'hex', minlength => 8, maxlength => 8 };
    $templates{prefix} = { func => sub { $_[0] =~ /^$_[1]{prefix}/ }, inherit => ['prefix'] };
    $templates{bool} = { required => 0, default => 0, func => sub { $_[0] = $_[0]?1:0 } };
    $templates{rawtuple} = { rmwhitespace => 0, template => 'tuple' };
    $templates{tuple} = { multi => 1, mincount => 2, maxcount => 2 };
  ()},
  { param => 'crc', template => 'hex' },
  [ crc => '12345678' ],
  { crc => '12345678' },

  { param => 'crc', template => 'crc32' },
  [ crc => '12345678' ],
  { crc => '12345678' },

  { param => 'crc', template => 'hex' },
  [ crc => '12x45678' ],
  { crc => '12x45678', _err => [[ 'crc', 'template', 'hex' ]] },

  { param => 'crc', template => 'crc32' },
  [ crc => '123456789' ],
  { crc => '123456789', _err => [[ 'crc', 'template', 'crc32' ]] },

  { param => 'x', template => 'prefix', prefix => 'he' },
  [ x => 'hello world' ],
  { x => 'hello world' },

  { param => 'x', template => 'prefix', prefix => 'he' },
  [ x => 'hullo' ],
  { x => 'hullo', _err => [[ 'x', 'template', 'prefix' ]] },

  { param => 'issexy', template => 'bool' },
  [],
  { issexy => 0 },

  { param => 'issexy', required => 1, template => 'bool' },
  [],
  { issexy => undef, _err => [['issexy', 'required', 1]] },

  { param => 'issexy', template => 'bool' },
  [ issexy => 'HI IM SEXY!' ],
  { issexy => 1 },

  { param => 'tuple', template => 'rawtuple' },
  [ tuple => ' so much space ', tuple => ' more space ' ],
  { tuple => [' so much space ', ' more space ' ]},

  { param => 'tuple', template => 'rawtuple' },
  [ tuple => 1 ],
  { tuple => [1], _err => [['tuple', 'mincount', 2]] }, # This error reporting is confusing

  { param => 'tuple', template => 'rawtuple' },
  [ tuple => 1, tuple => 2, tuple => 3 ],
  { tuple => [1,2,3], _err => [['tuple', 'maxcount', 2]] }, # Likewise

  # num / int / uint templates
  { param => 'age', template => 'num' },
  [ age => 0 ],
  { age => 0 },

  { param => 'age', template => 'num' },
  [ age => '0.5' ],
  { age => 0.5 },

  { param => 'age', template => 'num' },
  [ age => '0.5e3' ],
  { age => 500 },

  { param => 'age', template => 'num' },
  [ age => '-0.5E-3' ],
  { age => -0.0005 },

  { param => 'age', template => 'int' },
  [ age => '0.5e10' ],
  { age => '0.5e10', _err => [[ 'age', 'template', 'int' ]] },

  { param => 'age', template => 'num' },
  [ age => '0600' ],
  { age => '0600', _err => [[ 'age', 'template', 'num' ]] },

  { param => 'age', template => 'uint' },
  [ age => '50' ],
  { age => 50 },

  { param => 'age', template => 'uint' },
  [ age => '-1' ],
  { age => -1, _err => [[ 'age', 'template', 'uint' ]] },

  { param => 'age', template => 'num', min => 0, max => 0 },
  [ age => '0' ],
  { age => 0 },

  { param => 'age', template => 'num', max => 0 },
  [ age => '0.5' ],
  { age => 0.5, _err => [[ 'age', 'template', 'num' ]] },

  { param => 'age', template => 'int', max => 0 },
  [ age => 1 ],
  { age => 1, _err => [[ 'age', 'template', 'int' ]] },

  { param => 'age', template => 'uint', max => 0 },
  [ age => 1 ],
  { age => 1, _err => [[ 'age', 'template', 'uint' ]] },

  { param => 'age', template => 'num', min => 1 },
  [ age => 0 ],
  { age => 0, _err => [[ 'age', 'template', 'num' ]] },

  { param => 'age', template => 'int', min => 1 },
  [ age => 0 ],
  { age => 0, _err => [[ 'age', 'template', 'int' ]] },

  { param => 'age', template => 'uint', min => 1 },
  [ age => 0 ],
  { age => 0, _err => [[ 'age', 'template', 'uint' ]] },

  # email template
  (map +(
    { param => 'mail', template => 'email' },
    [ mail => $_->[1] ],
    { mail => $_->[1], $_->[0] ? () : (_err => [[ 'mail', 'template', 'email' ]]) },
  ),
    [ 0, 'abc.com' ],
    [ 0, 'abc@localhost' ],
    [ 0, 'abc@10.0.0.' ],
    [ 0, 'abc@256.0.0.1' ],
    [ 0, '<whoami>@blicky.net' ],
    [ 0, 'a @a.com' ],
    [ 0, 'a"@a.com' ],
    [ 0, 'a@[:]' ],
    [ 0, 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx@xxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxx.xxxxx' ],
    [ 1, 'a@a.com' ],
    [ 1, 'a@a.com.' ],
    [ 1, 'a@127.0.0.1' ],
    [ 1, 'a@[::1]' ],
    [ 1, 'é@yörhel.nl' ],
    [ 1, 'a+_0-c@yorhel.nl' ],
    [ 1, 'é@x-y_z.example' ],
    [ 1, 'abc@x-y_z.example' ],
  ),

  # weburl template
  (map +(
    { param => 'url', template => 'weburl' },
    [ url => $_->[1] ],
    { url => $_->[1], $_->[0] ? () : (_err => [[ 'url', 'template', 'weburl' ]]) },
  ),
    [ 0, 'http' ],
    [ 0, 'http://' ],
    [ 0, 'http:///' ],
    [ 0, 'http://x/' ],
    [ 0, 'http://x/' ],
    [ 0, 'http://256.0.0.1/' ],
    [ 0, 'http://blicky.net:050/' ],
    [ 0, 'ftp//blicky.net/' ],
    [ 1, 'http://blicky.net/' ],
    [ 1, 'http://blicky.net:50/' ],
    [ 1, 'https://blicky.net/' ],
    [ 1, 'https://[::1]:80/' ],
    [ 1, 'https://l-n.x_.example.com/' ],
    [ 1, 'https://blicky.net/?#Who\'d%20ever%22makeaurl_like-this/!idont.know' ],
  ),
)}

use Test::More tests => 1+@tests/3;

BEGIN { use_ok('TUWF::Misc', 'kv_validate') };

sub getfield {
  my($n, $f) = @_;
  map +($f->[$_*2] eq $n ? $f->[$_*2+1] : ()), @$f ? 0..$#$f/2 : ();
}

for my $i (0..$#tests/3) {
  my($fields, $params, $exp) = ($tests[$i*3], $tests[$i*3+1], $tests[$i*3+2]);
  is_deeply(
    kv_validate({ param => sub { getfield($_[0], $params) } }, \%templates, [$fields]),
    $exp,
    sprintf '%s = %s', $fields->{param}, join ',', getfield($fields->{param}, $params)
  );
}
