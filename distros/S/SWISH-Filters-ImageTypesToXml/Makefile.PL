use inc::Module::Install;

name     'SWISH-Filters-ImageTypesToXml';
all_from 'lib/SWISH/Filters/ImageTypesToXml.pm';
author   q{Logan Bell <loganbell@gmail.com>};
license  'perl';

requires 'SWISH::Filters'                   => 0;
requires 'SWISH::Filter::MIMETypes'         => 0;
requires 'Search::OpenSearch::Engine::Lucy' => 0.06;
requires 'Mime::Base64'                     => 0;
build_requires 'Test::More';
repository 'git://github.com/logie17/SWISH-Filters-ImageTypesToXml.git';

auto_install;

WriteAll;

