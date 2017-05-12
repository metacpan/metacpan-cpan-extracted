use strict;
use warnings;
use Test::More;
use Sys::Cmd::Template qw/cmd_template/;

my $cmd = cmd_template('stuff');

isa_ok $cmd, 'Sys::Cmd::Template';

done_testing();
