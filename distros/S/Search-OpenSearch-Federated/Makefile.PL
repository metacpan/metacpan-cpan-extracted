use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Search-OpenSearch-Federated';
perl_version '5.8.3';
all_from 'lib/Search/OpenSearch/Federated.pm';

requires 'Test::More'         => 0;
requires 'JSON'               => 0;
requires 'Scalar::Util'       => 0;
requires 'Data::Transformer'  => 0;
requires 'Search::Tools'      => '1.000';
requires 'Moo'                => 0;
requires 'Data::Dump'         => 0;
requires 'Parallel::Iterator' => 0;
requires 'LWP::UserAgent'     => 0;
requires 'XML::Simple'        => 0;
requires 'XML::Feed'          => 0;
requires 'Normalize'          => 0;

license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/search-opensearch-federated-perl';
bugtracker
    'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Federated';
repository 'http://github.com/karpet/search-opensearch-federated-perl';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Search-OpenSearch-Federated-* ' },
);
