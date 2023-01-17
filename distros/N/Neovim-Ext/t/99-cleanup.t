#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;
use File::Path qw/remove_tree/;

unlink ('nvim.sock');

remove_tree ('Neovim');
remove_tree ('nvim-linux64');
remove_tree ('nvim-linux32');
remove_tree ('nvim-macos');

unlink ('nvim-linux64.tar.gz');
unlink ('nvim-linux32.tar.gz');
unlink ('nvim-macos.tar.gz');
unlink ('nvim-win32.zip');
unlink ('nvim-win64.zip');
unlink ('t/rplugin.vim');
unlink ('t/nvim.log');

ok (!-e 'Neovim');
ok (!-e 'nvim-linux64');
ok (!-e 'nvim-linux64');
ok (!-e 'nvim-macos');

done_testing();

