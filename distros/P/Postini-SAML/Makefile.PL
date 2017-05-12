
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Do SAML-based sign-in to Postini services',
  'AUTHOR' => 'Robert Norris <rob@eatenbyagrue.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Postini-SAML',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Postini::SAML',
  'PREREQ_PM' => {
    'Crypt::OpenSSL::RSA' => '0',
    'Data::Random' => '0',
    'Date::Format' => '0',
    'Digest::SHA1' => '0',
    'MIME::Base64' => '0',
    'XML::CanonicalizeXML' => '0',
    'XML::Spice' => '0'
  },
  'VERSION' => '0.001',
  'test' => {
    'TESTS' => ''
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



