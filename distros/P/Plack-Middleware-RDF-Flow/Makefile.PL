
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Serve RDF as Linked Data for RDF::Flow',
  'AUTHOR' => 'Jakob Voß <voss@gbv.de>',
  'BUILD_REQUIRES' => {
    'Data::Dumper' => '0',
    'English' => '0',
    'HTTP::Request' => '0',
    'HTTP::Request::Common' => '0',
    'Plack::Builder' => '0',
    'Plack::Test' => '0',
    'RDF::Flow::Dummy' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Plack-Middleware-RDF-Flow',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Plack::Middleware::RDF::Flow',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Encode' => '0',
    'Exporter' => '0',
    'Log::Contextual' => '0',
    'Log::Contextual::WarnLogger' => '0',
    'Plack::Middleware' => '0',
    'Plack::Request' => '0',
    'Plack::Util::Accessor' => '0',
    'RDF::Flow' => '0',
    'RDF::Trine' => '0',
    'RDF::Trine::NamespaceMap' => '0',
    'RDF::Trine::Serializer' => '0',
    'Scalar::Util' => '0',
    'Try::Tiny' => '0',
    'parent' => '0'
  },
  'VERSION' => '0.171',
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



