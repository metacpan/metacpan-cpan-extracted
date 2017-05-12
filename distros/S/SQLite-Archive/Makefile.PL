use strict;
use inc::Module::Install;

name           'SQLite-Archive';
all_from       'lib/SQLite/Archive.pm';
requires       'Carp'             => 0;
requires       'File::Temp'       => 0;
requires       'File::Spec'       => '0.80';
requires       'IO::Zlib'         => '1.05';
requires       'Archive::Extract' => '0.22';
requires       'Parse::CSV'       => '1.00';
requires       'SQL::Script'      => '0.03';
requires       'DBI'              => '1.53';
requires       'DBD::SQLite'      => '1.09';
build_requires 'Test::More'       => '0.42';
build_requires 'File::Spec'       => '0.80';

WriteAll;
