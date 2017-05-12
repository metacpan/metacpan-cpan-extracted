use inc::Module::Install 1.06;

name     'SWISH-Filters-ImageToMD5Xml';
all_from 'lib/SWISH/Filters/ImageToMD5Xml.pm';
author   q{Logan Bell <loganbell@gmail.com>};
license  'perl';

requires 'SWISH::Filter'                    => 0;
requires 'Search::Tools::XML'               => 0.06;
requires 'MIME::Base64'                     => 0;
requires 'Digest::MD5'                      => 0;
requires 'XML::Simple'                      => 0;
test_requires 'Test::More';

repository 'https://github.com/logie17/SWISH-Filters-ImageMD5ToXml';

WriteAll;

