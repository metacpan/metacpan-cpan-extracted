use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'SWISH-Prog-Lucy';
all_from 'lib/SWISH/Prog/Lucy.pm';

requires 'Test::More'                   => 0;
requires 'Lucy'                         => '0.003002';
requires 'SWISH::Prog'                  => 0.75;
requires 'SWISH::3'                     => 1.000006;
requires 'Sort::SQL'                    => 0.06;
requires 'Search::Query'                => 0.17;
requires 'Search::Query::Dialect::Lucy' => 0.04;
requires 'LucyX::Search::WildcardQuery' => 0.05;
requires 'Path::Class::File::Lockable'  => 0;
requires 'Path::Class::File::Stat'      => 0.03;
requires 'Sys::Hostname'                => 0;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'http://dev.swish-e.org/wiki/perl';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-Lucy';
repository 'http://svn.swish-e.org/perl/SWISH-Prog-Lucy/';

install_script 'bin/lucyx-dump-terms';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SWISH-Prog-Lucy-* t/index.swish' },
);
