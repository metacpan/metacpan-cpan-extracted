#!perl
use warnings;
use Test::More tests => 22;
use Regexp::NamedCaptures;

$OPEN_NAME = '<';
$CLOSE_NAME = '>';
do "t/basic";

$OPEN_NAME = '\'';
$CLOSE_NAME = '\'';
do "t/basic";
