# vim: filetype=perl :
use strict;
use warnings;

use Storable 'dclone';
use Test::More;# tests => 31; # last test to print
use Template::Perlish qw< traverse >;

my $hash = {
   one   => 'ONE',
   two   => 'TWO',
   three => 'THREE',
   4     => 'FOUR, but in digits',
};

my $array = [0 .. 3, 'four'];

my $data = {
   hash         => $hash,
   array        => $array,
   complex_hash => {
      hash      => $hash,
      array     => $array,
      something => {more => 1},
      hey       => [qw< you all >],
   },
   complex_array => [$hash, $array, {something => 'more'}, ['hey']],
};
my $ref = \$data;

my @tests = (
   [[$data], $data, 'root, no ref'],
   [[$data, 'complex_hash.array'],   $array, 'down in hashes'],
   [[$data, 'complex_hash.array.4'], 'four', 'down in hashes and array'],
   [[$data, 'complex_array.0'],      $hash,  'down in hash and array'],
   [[$data, 'complex_hash.array.4'], 'four', 'down in hashes and array'],
   [
      [$data, 'complex_hash.hash.4'],
      'FOUR, but in digits',
      'down in hashes to the leaf'
   ],
   [
      [$data, ['hash', {4 => 1}]],
      'FOUR, but in digits',
      'down in hashes, with constraint'
   ],
   [[$data, ['hash', [4]]], '', 'down in hashes, failed constraint'],
   [[$data, 'inexistent'], '', 'inexistent key'],

   [[$ref], $ref, 'root, ref'],
   [[$ref, 'complex_hash.array'], \$array, 'down in hashes, ref'],
   [[$ref, 'complex_array.0'],    \$hash,  'down in hash and array, ref'],
   [
      [$ref, ['complex_hash', {array => 1}]],
      \$array,
      'down in hashes, with constraint, ref'
   ],
   [
      [$ref, 'inexistent'],
      sub { \($data->{inexistent}) },
      'inexistent key, ref'
   ],
   [
      [$ref, ['inexistent', {4 => 1}]],
      sub { \($data->{inexistent}{4}) },
      'inexistent key 2, ref'
   ],
   [
      [$data, ['inexistent', {4 => 1}, 2]],
      '',
      'yet to auto-vivify index has no value now'
   ],
   [
      [$ref, ['inexistent', {4 => 1}, 2]],
      sub { \($data->{inexistent}{4}[2] = 42) },
      'inexistent index, ref'
   ],
   [
      [$data, ['inexistent', {4 => 1}, 2]],
      42,
      'auto-vivified index has right value now'
   ],
   [
      [$data, ['inexistent', {4 => 1}, 2], {traverse_methods => 1}],
      42, 'set traverse_methods to 1, unblessed stuff'
   ],
   [
      [
         $data,
         ['inexistent', {4 => 1}, 2],
         {traverse_methods => 1, strict_blessed => 1}
      ],
      42,
      'traverse_methods and strict_blessed, unblessed stuff'
   ],
   [
      [
         $data,
         ['inexistent2'],
         {missing => undef},
      ],
      undef,
      'options missing set to undef'
   ],
);

for my $spec (@tests) {
   my ($inputs, $expected, $message) = @$spec;
   my $got = traverse(@$inputs);
   $expected = $expected->() if ref($expected) eq 'CODE';
   if (defined $expected) {
      is_deeply $got, $expected, $message;
   }
   else {
      ok((!defined $got), $message)
        or diag("got [$got] instead!");
   }
} ## end for my $spec (@tests)

{
   use Data::Dumper;
   my $var;
   my $ref_to_value = traverse(\$var, "some.0.'comp-lex'.path");
   $$ref_to_value = 42;    # note double sigil for indirection
   is $var->{some}[0]{'comp-lex'}{path}, 42, 'starting from undef var';
}

$data->{objects}{hash} = Some::Thing->new({foobar => 'baz', on => 1});
$data->{objects}{array} = Some::Thing->new(['a' .. 'd']);
{
   my $got = traverse($data, [qw< objects hash foobar >]);
   is $got, 'baz', 'default does not consider blessed objects';

   $got =
     traverse($data, [qw< objects hash foobar >], {traverse_methods => 1});
   is $got, 'baz', 'default key wins on method';

   $got =
     traverse($data, [qw< objects hash baz >], {traverse_methods => 1});
   is $got, 'hey', 'default fallback on method';

   $got =
     traverse($data, [qw< objects hash on >],
      {traverse_methods => 1, method_over_key => 1});
   is $got, 1, 'fallback from method to key';

   $got =
     traverse($data, [qw< objects hash foobar what >],
      {traverse_methods => 1, method_over_key => 1});
   is $got, 'ever', 'method_over_key, method wins';

   $got =
     traverse($data, [qw< objects hash on >],
      {traverse_methods => 1, strict_blessed => 1});
   is $got, '', 'no fallback from method to key with strict_blessed';

   $got = traverse($data, [qw< objects array 0 >]);
   is $got, 'a', 'default does not consider blessed objects (aref)';

   $got =
     traverse($data, [qw< objects array 2 >],
      {traverse_methods => 1, method_over_key => 1});
   is $got, 'c', 'fallback from method to key (aref)';

   $got =
     traverse($data, [qw< objects array foobar what >],
      {traverse_methods => 1, method_over_key => 1});
   is $got, 'ever', 'method_over_key, method wins (aref)';

   $got =
     traverse($data, [qw< objects array 2 >],
      {traverse_methods => 1, strict_refs => 1});
   is $got, 'c', 'no fallback from method to key with strict_blessed (aref)';
}

{
   my $data = { foo => {}, bar => undef };
   my $original = dclone($data);
   my $opts = {};
   my $got;

   $got = traverse($data, [qw< foo inexistent >], $opts);
   is $got, '', 'plain default return on inexistent final key';
   is_deeply $data, $original, 'no auto-vivification';

   $got = traverse($data, [qw< foo inexistent and then some >], $opts);
   is $got, '', 'plain default return on inexistent deep key';
   is_deeply $data, $original, 'no auto-vivification';

   $opts = { missing => 42, undef => 84 };

   $got = traverse($data, [qw< foo inexistent >], $opts);
   is $got, 42, 'return on inexistent final key, missing is set';
   is_deeply $data, $original, 'no auto-vivification';

   $got = traverse($data, [qw< foo inexistent and then some >], $opts);
   is $got, 42, 'return on inexistent deep key, missing is set';
   is_deeply $data, $original, 'no auto-vivification';

   $got = traverse($data, [qw< bar >], $opts);
   is $got, 84, 'return on existing undef, undef is set';
}

done_testing();

package Some::Thing;

sub new {
   my $package = shift;
   my $self    = shift;
   return bless $self, $package;
}

sub foobar {
   return {what => 'ever'};
}

sub baz { return 'hey' }

1;
