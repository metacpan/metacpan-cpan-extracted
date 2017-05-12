use strict;
use warnings;
use inc::Module::Install;

perl_version '5.008004';

name 'Sysync';
all_from 'lib/Sysync.pm';
license 'gpl';

requires 'Digest::MD5';
requires 'File::Copy';
requires 'File::Find';
requires 'File::Path';
requires 'YAML';
requires 'IPC::Open3';

no_index directory => 'defaults';
no_index file => 'post_install.PL';

resources
  homepage      => "http://sysync.nongnu.org",
  bugtracker    => "https://savannah.nongnu.org/bugs/?group=sysync",
  repository    => "git://git.savannah.nongnu.org/sysync.git",
  license       => "http://www.gnu.org/licenses/agpl-3.0.html";

makemaker_args(
    MAN1PODS => {
        'bin/sysync' => 'blib/man1/sysync.1',
    },
);

sub MY::postamble
{
    return "install::\n\tperl script/post_install.PL";
}

WriteAll();

