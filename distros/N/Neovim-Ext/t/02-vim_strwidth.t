#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

is $vim->strwidth ('abc'), 3;

# 6 + (neovim)
# 19 * 2 (each japanese character occupies two cells)
is $vim->strwidth ('neovimのデザインかなりまともなのになってる。'), 44;

done_testing();
