use inc::Module::Install;

name 'Mojo-UserAgent-Cached';

# These override things fetched by 'all_from' below.
# They must come *before* the call to 'all_from'.
perl_version '5.010001';
license 'perl'; # the license type ('all_from' needs this)

author 'Nicolas Mendoza <mendoza@pvv.ntnu.no>';
version_from 'lib/Mojo/UserAgent/Cached.pm';

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
requires 'Mojolicious' => '7.15';
requires 'POSIX';
requires 'Readonly';
requires 'String::Truncate';
requires 'Time::HiRes';

test_requires 'Test::More';
test_requires 'Time::HiRes';
test_requires 'IO::Compress::Gzip';

tests_recursive;

WriteAll;
