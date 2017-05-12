#!perl
use strict;
use warnings;

use Test::More;

use PerlIO::Util;
BEGIN{
	if(!PerlIO::Layer->find('dir')){
		plan skip_all => 'without directory functions';
		exit;
	}
	else{
		plan tests => 22;
	}
}
use IO::Dir;
use FindBin qw($Bin);
use File::Spec;
use IO::Seekable qw(SEEK_SET SEEK_CUR SEEK_END);

ok open(my $dir, '<:dir', '.'), 'open:dir';
is_deeply [$dir->get_layers()], ['dir'], 'only :dir layer';

my @dirs = <$dir>;

is_deeply \@dirs, [ map{ "$_\n" } IO::Dir->new('.')->read() ], '<$dir>';
ok eof($dir), "eof:dir";

seek $dir, 0, 0; # rewind
ok !eof($dir), 'eof:dir after seek:dir (cleared)';


my $first  = <$dir>;
is $first, $dirs[0], 'seek:dir (rewind 1st)';

seek $dir, 0, 0; # rewind

$first = <$dir>;
is $first, $dirs[0], 'seek:dir (rewind 2nd)';

ok close($dir), 'close:dir';

STDIN->push_layer(dir => '.');
is_deeply [ <STDIN> ], \@dirs, 'push_layer:dir';
is(STDIN->pop_layer(), 'dir', 'pop_layer:dir');

ok open($dir, '<:dir:utf8', '.'), 'open:dir';

ok utf8::is_utf8(scalar <$dir>), 'with :utf8';
binmode $dir;
ok !utf8::is_utf8(scalar <$dir>), 'without :utf8';

ok open($dir, '<:dir', '.'), 'open:dir';
ok !seek($dir, 1, SEEK_SET), 'SEEK_SET (NK)';
ok !seek($dir, 1, SEEK_CUR), 'SEEK_CUR (NG)';
ok !seek($dir, 1, SEEK_END), 'SEEK_END (NG)';


$! = 0;
ok !open($dir, '>:dir', '.'), "open:dir for writing (\$!='$!')";
#ok $!{EPERM}, "... permission denied (\$!=$!)";
ok !open($dir, '+<:dir', '.'), "open:dir for update (\$!='$!')";
#ok $!{EPERM}, "... permission denied (\$!=$!)";

ok !open($dir, '<:dir', File::Spec->join($Bin, 'util', '.lock')), "open:dir for a file (\$!='$!')";
#ok $!{ENOTDIR}, "... not a directory (\$!=$!)";

ok !open($dir, '<:dir', File::Spec->join($Bin, 'util', '@@@')), "open:dir no such directory (\$!='$!')";
#ok $!{ENOENT}, "... no such file or directory (\$!=$!)";

ok !binmode(STDIN, ':dir'), ':dir without an argument';
