use Test::More tests => 2;

use strict;
use warnings;
use Tapper::CLI::Utils qw/apply_macro/;

my $text = '
[% PROCESS "standard.inc" -%]
[% test %]
[% einstein %]
';
my $expected = '
result
albert
';


my $retval = apply_macro($text, {test => 'result'}, ['t/files/include']);
is($retval, $expected, 'Apply macro on text');

$retval = apply_macro('t/files/macro.tt', {test => 'result'}, ['t/files/include']);
is($retval, $expected, 'Apply macro on file');
