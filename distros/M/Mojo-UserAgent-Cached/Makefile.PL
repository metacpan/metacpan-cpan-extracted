use inc::Module::Install;

name 'Mojo-UserAgent-Cached';
# These override things fetched by 'all_from' below.
# They must come *before* the call to 'all_from'.
perl_version '5.010001';
#license 'perl'; # the license type ('all_from' needs this)

author 'Nicolas Mendoza <mendoza@pvv.ntnu.no>';
all_from 'lib/Mojo/UserAgent/Cached.pm';

resources
  license    => 'http://dev.perl.org/licenses/',
  bugtracker => 'https://github.com/nicomen/mojo-useragent-cached/issues',
  repository => 'http://github.com/nicomen/mojo-useragent-cached',
;

configure_requires 'Module::Install' => 0;

requires 'Algorithm::LCSS';
requires 'CHI';
requires 'Data::Serializer';
requires 'Devel::StackTrace';
requires 'English';
requires 'File::Basename';
requires 'File::Path';
requires 'File::Spec';
requires 'List::Util' => '1.29';
requires 'Mojolicious' => '8.72';
requires 'POSIX';
requires 'Readonly';
requires 'String::Truncate';
requires 'Time::HiRes';

test_requires 'Test::More';
test_requires 'Time::HiRes';
test_requires 'IO::Compress::Gzip';

tests_recursive;

WriteAll;
