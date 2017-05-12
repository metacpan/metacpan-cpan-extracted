
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Form Based Authentication for Plack (think L<CatalystX::SimpleLogin> but on Plack level)",
  "AUTHOR" => "Zbigniew Lukasiak <zby\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Spec" => 0,
    "HTTP::Message::PSGI" => 0,
    "HTTP::Request" => 0,
    "Plack::Builder" => 0,
    "Plack::Middleware::Lint" => 0,
    "Plack::Util" => 0,
    "Test::More" => 0,
    "Test::WWW::Mechanize::PSGI" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Plack-Middleware-Auth-Form",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Plack::Middleware::Auth::Form",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Plack::Middleware" => 0,
    "Plack::Middleware::Session" => 0,
    "Plack::Request" => 0,
    "Plack::Util::Accessor" => 0,
    "Scalar::Util" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.012",
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



