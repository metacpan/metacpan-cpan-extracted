
use strict;
use warnings;

use 5.004040;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Subversion repository web frontend",
  "AUTHOR" => "Dean Hamstead <dean\@fragfest.com.au>",
  "BUILD_REQUIRES" => {
    "Cwd" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::Path" => 0,
    "Test::More" => 0,
    "Test::WWW::Mechanize" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "SVN-Web",
  "EXE_FILES" => [
    "bin/svnweb-install"
  ],
  "LICENSE" => "perl",
  "NAME" => "SVN::Web",
  "PREREQ_PM" => {
    "Alien::SVN" => 0,
    "Carp" => 0,
    "Encode" => 0,
    "Exception::Class" => "1.22",
    "File::Basename" => 0,
    "File::Path" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "IO::File" => 0,
    "List::Util" => 0,
    "Locale::Maketext" => 0,
    "Locale::Maketext::Lexicon" => 0,
    "Number::Format" => 0,
    "POSIX" => 0,
    "Plack" => 0,
    "Template" => 0,
    "Template::Plugin::Number::Format" => 0,
    "Time::Zone" => 0,
    "URI::Escape" => 0,
    "YAML" => 0,
    "base" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.63",
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



