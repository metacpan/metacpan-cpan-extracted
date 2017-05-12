use strict;
use warnings;
use Test::More tests => 1;

use MooseX::Runnable::Util::ArgParser;

my $str = '-MFoo -Ilib -MBar +Plugout +Plugin --with-args -- MyApp --with  args';

my $args = MooseX::Runnable::Util::ArgParser->new(
    argv => [split ' ', $str],
);

local $^X = '/path/to/perl';
local $FindBin::Bin = '/path/to';
local $FindBin::Script = 'mx-run';
local @INC = ('foobar');
my @cmdline = $args->guess_cmdline(
    perl_flags => ['--X--'],
    without_plugins => ['Plugout'],
);

is join(' ', @cmdline),
  "/path/to/perl -Ifoobar --X-- /path/to/mx-run -Ilib -MFoo -MBar +Plugin --with-args -- MyApp --with args",
  'cmdline reverses reasonably';
