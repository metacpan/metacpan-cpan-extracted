use Mojo::Base -strict;
use Test::More;
use SolarBeam::Util qw(escape escape_chars unescape_chars);

is escape('"+f-o&o*"'), '"\+f\-o\&o*"', 'escape wilds';
is escape(\'"+f-o&o*"'), '\"\+f\-o\&o\*\"', 'escape all';

is escape_chars('"f?oo"'),      '\"f\?oo\"', 'escape_chars';
is unescape_chars('\"f\?oo\"'), '"f?oo"',    'unescape_chars';

done_testing;
