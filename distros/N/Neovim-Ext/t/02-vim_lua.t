#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $lua_code = q#
local a = vim.api
local y = ...
function pynvimtest_func(x)
    return x+y
end

local function setbuf(buf,lines)
   a.nvim_buf_set_lines(buf, 0, -1, true, lines)
end


local function getbuf(buf)
   return a.nvim_buf_line_count(buf)
end

pynvimtest = {setbuf=setbuf,getbuf=getbuf}

return "eggspam"
#;

is $vim->exec_lua ($lua_code, 7), 'eggspam';
is $vim->lua->pynvimtest_func->call (3), 10;

my $testmod = $vim->lua->pynvimtest;
my $buf = tied (@{$vim->current->buffer});
$testmod->setbuf->call ($buf, ["a", "b", "c", "d"], async_ => 1);
is $testmod->getbuf->call ($buf), 4;

done_testing();

