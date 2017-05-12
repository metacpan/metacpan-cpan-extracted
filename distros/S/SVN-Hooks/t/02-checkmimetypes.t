# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 5;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t = reset_repo();

set_hook(<<'EOS');
use SVN::Hooks::CheckMimeTypes;
EOS

set_conf(<<'EOS');
CHECK_MIMETYPES();
EOS

my $file = catfile($t, 'wc', 'file.txt');

work_nok('miss svn:mime-type' => 'property svn:mime-type is not set for', <<"EOS");
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mx $file
EOS

work_nok('miss svn:eol-style on text file', 'property svn:eol-style is not set for', <<"EOS");
svn ps svn:mime-type "text/plain" $file
svn ci -mx $file
EOS

work_nok('miss svn:keywords on text file', 'property svn:keywords is not set for', <<"EOS");
svn ps svn:eol-style native $file
svn ci -mx $file
EOS

work_ok('all set on text file' => <<"EOS");
svn ps svn:keywords Id $file
svn ci -q -mx $file
EOS

my $binary = catfile($t, 'wc', 'binary.exe');

work_ok('set only svn:mime-type on non-text file', <<"EOS");
echo bin >$binary
svn add -q --no-auto-props $binary
svn ps svn:mime-type "application/octet-stream" $binary
svn ci -mx $binary
EOS
