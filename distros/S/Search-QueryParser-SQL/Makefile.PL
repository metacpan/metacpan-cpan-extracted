use strict;
use warnings;

use inc::Module::Install;

# Define metadata
name 'Search-QueryParser-SQL';
all_from 'lib/Search/QueryParser/SQL.pm';

requires 'Test::More'          => 0;
requires 'Search::QueryParser' => '0.93';
requires 'Scalar::Util'        => 0;
requires 'Data::Dump'          => 0; # just for devel
requires 'Class::Accessor::Fast' => 0;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/search-queryparser-sql';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-QueryParser-SQL';
repository 'https://github.com/karpet/search-queryparser-sql.git';

WriteAll;
