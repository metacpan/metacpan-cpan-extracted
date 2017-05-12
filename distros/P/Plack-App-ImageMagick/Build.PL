
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Plack::Builder' => '0',
    'Plack::Test' => '0',
    'Test::More' => '0',
    'Test::NoWarnings' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Image::Magick' => '6.5.0',
    'Module::Build' => '0.3601',
    'Plack' => '0.9976'
  },
  'dist_abstract' => 'Create and manipulate images with Image::Magick',
  'dist_author' => [
    'Alex J. G. Burzyński <ajgb@cpan.org>'
  ],
  'dist_name' => 'Plack-App-ImageMagick',
  'dist_version' => '1.110990',
  'license' => 'perl',
  'module_name' => 'Plack::App::ImageMagick',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Digest::MD5' => '0',
    'File::Spec' => '0',
    'HTTP::Date' => '0',
    'Image::Magick' => '0',
    'JSON::XS' => '0',
    'Plack::App::File' => '0',
    'Plack::Component' => '0',
    'Plack::Request' => '0',
    'Plack::Util' => '0',
    'Plack::Util::Accessor' => '0',
    'String::Bash' => '0',
    'Try::Tiny' => '0',
    'parent' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
