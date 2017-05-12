use strict;
use warnings;
use inc::Module::Install;
use 5.006;

name 'Path-Class-File-Stat';
all_from 'lib/Path/Class/File/Stat.pm';
requires 'Test::More'  => 0;
requires 'Path::Class' => '0.32';

perl_version '5.6.0';
license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/path-class-file-stat';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Path-Class-File-Stat';
repository 'http://github.com/karpet/path-class-file-stat';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Path-Class-File-Stat-*' },
);
