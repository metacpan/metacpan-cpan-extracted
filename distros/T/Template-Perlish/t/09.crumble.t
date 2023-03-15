# vim: filetype=perl :
use strict;
use warnings;

use Test::More;    # tests => 4; # last test to print
use Template::Perlish qw< crumble >;

my @tests = (
   ['', [], 'empty path'],
   ['one',               [qw< one >],           'simple single element'],
   ['one.two',           [qw< one two >],       'two elements'],
   ['one.two.3.four',    [qw< one two 3 four>], 'many simple elements'],
   ['"o^ne"."tw-o"',     [qw< o^ne tw-o >],     'double quotes'],
   [q<'o^ne'.'tw-o'>,    [qw< o^ne tw-o >],     'single quotes'],
   [q<"o^ne"."tw\-o">,   [qw< o^ne tw-o >],     'double quotes escapes'],
   [q<"o^ne"."tw\\-o">,  [qw< o^ne tw-o >],     'double quotes escapes 2'],
   [q<"o^ne"."tw\\\-o">, [qw< o^ne tw\-o >],    'double quotes escapes 3'],
   [q<"o^ne"."tw\\\\-o">, [qw< o^ne tw\-o >], 'double quotes escapes 4'],
   [q<'o^ne'.'tw\-o'>,    [qw< o^ne tw\-o >], 'single quotes no escapes'],
   [q<'o^ne'.'tw\\-o'>, [qw< o^ne tw\-o >],  'single quotes no escapes 2'],
   [q<'{"1":1}'.'[2]'>, [qw< {"1":1} [2] >], 'hashes and arrays'],
   [
      q<"{\\"1\\":1}"."[2]">, [qw< {"1":1} [2] >],
      'hashes and arrays, dquotes'
   ],
   [q<'one.two'>, [qw< one.two >], 'one element seeming two'],
   [q<'runaway.boh>, undef, 'wrong input'],
   [q<''>, [''], 'one empty element, only'],
   [q<''.boh>, ['', 'boh'], 'one empty element, at beginning'],
   [q<''.boh.''>, ['', 'boh', ''], 'empty elements at extremes'],
   [q<boh.''.bah>, ['boh', '', 'bah'], 'one empty element, inside'],
   [q<boh.''>, ['boh', ''], 'one empty element, at end'],
   [q<'"ciao"'>,     [q<"ciao">], 'double quotes in single quotes'],
   [q<"'ciao'">,     [q<'ciao'>], 'single quotes in double quotes'],
   [q<"\\"ciao\\"">, [q<"ciao">], 'double quotes in double quotes'],
);

for my $spec (@tests) {
   my ($path, $expected, $message) = @$spec;
   my $got = crumble($path);
   if (defined $expected) {
      is_deeply $got, $expected, $message;
   }
   else {
      ok((!defined $got), $message);
   }
} ## end for my $spec (@tests)

my @additional = (
   [ 'foo.bar:baz', [qw< foo bar >], 7, 'partial match with pos' ],
   [ q<'runaway.boh>, undef, undef, 'wrong input' ],
   [q<''.boh.''=f.b.>, ['', 'boh', ''], 9, 'elements at extremes'],
);
for my $spec (@additional) {
   my ($path, $exp_crumbs, $exp_pos, $message) = @$spec;
   my ($got_crumbs, $got_pos) = crumble($path, 'partial is OK');
   if (defined $exp_crumbs) {
      is_deeply $got_crumbs, $exp_crumbs, $message;
      is $got_pos, $exp_pos, $message . ' (position)';
   }
   else {
      ok((! defined $got_crumbs), $message);
      ok((! defined $got_pos), $message . ' (position)');
   }
}


done_testing(scalar(@tests) + 2 * scalar(@additional));
