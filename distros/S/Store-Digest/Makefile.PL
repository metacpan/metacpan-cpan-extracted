use 5.012;
use strict;
use warnings;
use inc::Module::Install;

name        'Store-Digest';
all_from    'lib/Store/Digest.pm';
readme_from 'lib/Store/Digest.pm';
author      q{Dorian Taylor <dorian@cpan.org>};
license     'apache';

perl_version 5.012;

tests_recursive('t');

resources (
   homepage   => 'https://github.com/doriantaylor/p5-store-digest',
   license    => 'http://www.apache.org/licenses/LICENSE-2.0',
   repository => 'git://github.com/doriantaylor/p5-store-digest.git',
   bugtracker => 'https://github.com/doriantaylor/p5-store-digest/issues',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
    'BerkeleyDB'               => '0.55',
    'Class::Load'              => '0.23',
    'DateTime'                 => '0.70',
    'File::Copy'               => '2.21',
    'MIME::Base32'             => '1.02',
    'Math::BigInt'             => '1.997',
    'Moose'                    => '2.0604',
    'MooseX::Params::Validate' => '0.18',
    'MooseX::Types'            => '0.35',
    'Path::Class'              => '0.24',
    'Role::MimeInfo'           => '0.01', # mine
    'String::RewritePrefix'    => '0.007',
    'URI::ni'                  => '0.03', # mine

    'DateTime::Format::HTTP'   => '0.40',   # http
    'HTTP::Negotiate'          => '6.00',   # http
    'Plack'                    => '1.0005', # http
    'XML::LibXML::LazyBuilder' => '0.05',   # http
);

clean_files 't/content';

install_as_cpan;
auto_install;
WriteAll;
