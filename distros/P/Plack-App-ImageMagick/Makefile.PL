
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Create and manipulate images with Image::Magick',
  'AUTHOR' => 'Alex J. G. Burzyński <ajgb@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Plack::Builder' => '0',
    'Plack::Test' => '0',
    'Test::More' => '0',
    'Test::NoWarnings' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Image::Magick' => '6.5.0',
    'Module::Build' => '0.3601',
    'Plack' => '0.9976'
  },
  'DISTNAME' => 'Plack-App-ImageMagick',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Plack::App::ImageMagick',
  'PREREQ_PM' => {
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
  'VERSION' => '1.110990',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



