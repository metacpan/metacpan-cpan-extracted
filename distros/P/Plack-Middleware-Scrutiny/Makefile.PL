
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Scrutinize your [psgi] app with an [inline] debugger",
  "AUTHOR" => "Brock Wilcox <awwaiid\@thelackthereof.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Plack-Middleware-Scrutiny",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Plack::Middleware::Scrutiny",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Devel::ebug" => 0,
    "Devel::ebug::Backend" => 0,
    "Enbugger" => 0,
    "Enbugger::ebug" => 0,
    "Exporter" => 0,
    "File::ShareDir" => 0,
    "IO::Handle" => 0,
    "IO::String" => 0,
    "Plack::App::File" => 0,
    "Plack::Middleware" => 0,
    "Plack::Request" => 0,
    "Plack::Util" => 0,
    "Plack::Util::Accessor" => 0,
    "Storable" => 0,
    "Time::HiRes" => 0,
    "Try::Tiny" => 0,
    "Twiggy" => 0,
    "constant" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.02",
  "test" => {
    "TESTS" => ""
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

package
MY;
use File::ShareDir::Install qw(postamble);


