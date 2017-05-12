use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Search-OpenSearch';
perl_version '5.8.3';
all_from 'lib/Search/OpenSearch.pm';

requires 'Test::More'                => 0;
requires 'JSON'                      => 0;
requires 'Moose'                     => 0;
requires 'MooseX::StrictConstructor' => 0;
requires 'Type::Tiny'                => 0.008;
requires 'namespace::autoclean'      => 0;
requires 'Scalar::Util'              => 0;
requires 'URI::Encode'               => 0;
requires 'Data::Pageset'             => 0;
requires 'Search::Tools'             => '1.000';
requires 'CHI'                       => 0;
requires 'Data::UUID'                => 0;
requires 'Sort::SQL'                 => 0;

license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/search-opensearch-perl';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch';
repository 'http://github.com/karpet/search-opensearch-perl';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Search-OpenSearch-* ' },
);
