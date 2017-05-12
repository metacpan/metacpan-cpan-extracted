
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl wrapper for talking with Bullfinch",
  "AUTHOR" => "Cory G Watson <gphat\@cpan.org>, Stevan Little <stevan.little\@iinteractive.com>, Jay Hannah <jay.hannah\@iinteractive.com>, Trey Bianchini <trey.bianchini\@iinteractive.com>, Jesse Luehrs <doy\@tozt.net>, Florian Ragwitz <rafl\@debian.org>",
  "BUILD_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Bullfinch",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Bullfinch",
  "PREREQ_PM" => {
    "Data::Stream::Bulk" => 0,
    "Data::Stream::Bulk::DoneFlag" => 0,
    "Data::UUID" => 0,
    "JSON::XS" => 0,
    "Memcached::Client" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Params::Validate" => 0,
    "MooseX::Types::DateTime" => 0
  },
  "VERSION" => "0.16",
  "test" => {
    "TESTS" => "t/*.t"
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



