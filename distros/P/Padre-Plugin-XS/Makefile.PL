use strict;
use warnings;

use inc::Module::Install 1.06;

name 'Padre-Plugin-XS';
all_from 'lib/Padre/Plugin/XS.pm';

perl_version '5.010001';

requires 'Padre'              => '1';
requires 'Perl::APIReference' => '0.15';
requires 'Try::Tiny'          => '0.18';
requires 'YAML::Tiny'         => '1.56';
requires 'constant'           => '1.27';
requires 'parent'             => '0.228';

test_requires 'Exporter'               => '5.68';
test_requires 'File::Find::Rule'       => '0.33';
test_requires 'File::Find::Rule::Perl' => '1.13';
test_requires 'File::Slurp'            => '9999.19';
test_requires 'Parse::CPAN::Meta'      => '1.4409';
test_requires 'Software::LicenseUtils' => '0.103008';
test_requires 'Test::Builder'          => '1.001002';
test_requires 'Test::More'             => '1.001002';
test_requires 'Test::Requires'         => '0.07';

recommends 'ExtUtils::MakeMaker'   => '6.84';
recommends 'File::Spec::Functions' => '3.4';
recommends 'List::Util'            => '1.35';
recommends 'Test::Pod'             => '1.48';
recommends 'Test::Pod::Coverage'   => '1.08';

no_index 'directory' => qw{ inc share t };

homepage 'http://padre.perlide.org/trac/wiki/PadrePluginXS';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-XS';

install_share_with_mofiles;

WriteAll;
