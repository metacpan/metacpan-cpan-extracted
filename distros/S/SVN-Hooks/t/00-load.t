# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 1;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t = reset_repo();

set_hook(<<'EOS');
use SVN::Hooks::AllowLogChange;
use SVN::Hooks::AllowPropChange;
use SVN::Hooks::CheckJira;
use SVN::Hooks::CheckLog;
use SVN::Hooks::CheckMimeTypes;
use SVN::Hooks::CheckProperty;
use SVN::Hooks::CheckStructure;
use SVN::Hooks::DenyChanges;
use SVN::Hooks::DenyFilenames;
use SVN::Hooks::Generic;
use SVN::Hooks::Mailer;
use SVN::Hooks::Notify;
use SVN::Hooks::UpdateConfFile;
EOS

my $file = catfile($t, 'wc', 'file');

work_ok('commit' => <<"EOS");
echo txt >$file
svn add -q --no-auto-props $file
svn ci -q -mx $file
EOS
