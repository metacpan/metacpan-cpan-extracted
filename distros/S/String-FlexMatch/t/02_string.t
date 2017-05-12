#!/usr/bin/env perl
use warnings;
use strict;
use YAML;
use Test::More tests => 13;
use String::FlexMatch::Test;
BEGIN { use_ok('String::FlexMatch') }
my $data = Load do { local $/; <DATA> };
my $msg = 'Error 1 at file /foo/bar/lib/Baz.pm line 73';
is_deeply_flex($data->{pure_str},   $msg, 'a - pure string');
is_deeply_flex($data->{flex_str},   $msg, 'a - flex string');
is_deeply_flex($data->{flex_regex}, $msg, 'a - flex regex');
is_deeply_flex($data->{flex_code},  $msg, 'a - flex code');
is_deeply_flex($data->{ok_regex},   $msg, 'a - ok regex');
is_deeply_flex($data->{ok_code},    $msg, 'a - ok code');
$msg = 'Error 2 at file /frob/nule/lib/Baz.pm line 61';
is_deeply_flex($data->{flex_regex}, $msg, 'b - flex regex');
is_deeply_flex($data->{flex_code},  $msg, 'b - flex code');
is_deeply_flex($data->{ok_regex},   $msg, 'b - ok regex');
is_deeply_flex($data->{ok_code},    $msg, 'b - ok code');
$msg = 'foobar';
is_deeply_flex($data->{ok_regex}, $msg, 'c - ok regex');
is_deeply_flex($data->{ok_code},  $msg, 'c - ok code');
__DATA__
pure_str: Error 1 at file /foo/bar/lib/Baz.pm line 73
flex_str: !perl/String::FlexMatch
  string: Error 1 at file /foo/bar/lib/Baz.pm line 73
flex_regex: !perl/String::FlexMatch
  regex: Error \d+ at file .*/lib/Baz.pm line \d+
flex_code: !perl/String::FlexMatch
  code: sub { $_[0] =~ m!Error \d+ at file .*/lib/Baz.pm line \d+! }
ok_regex: !perl/String::FlexMatch
  regex: '.'
ok_code: !perl/String::FlexMatch
  code: sub { 1 }
