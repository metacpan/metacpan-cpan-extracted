# This Makefile.PL for POE-Component-Client-FTP was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.38.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Implements an FTP client POE Component",
  "AUTHOR" => "Michael Ching <michaelc\@wush.net>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.59",
    "Test::More" => "0.47",
    "Test::POE::Client::TCP" => "0.1",
    "Test::POE::Server::TCP" => "0.16"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "POE-Component-Client-FTP",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "POE::Component::Client::FTP",
  "PREREQ_PM" => {
    "POE" => "0.38"
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.47"
  },
  "VERSION" => "0.24",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

%WriteMakefileArgs = (
    %WriteMakefileArgs,
    clean => {FILES => "network.tests"},
);

my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => "6.59",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "POE" => "0.38",
  "Test::More" => "0.47",
  "Test::POE::Client::TCP" => "0.1",
  "Test::POE::Server::TCP" => "0.16"
);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.032
if (prompt_default_no('Do you want to enable optional TLS support ( requires POE::Component::SSLify )')) {
requires('POE::Component::SSLify','0.10')
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

my $value = prompt( 'Do you want live network tests [N/y]?', 'N' );
if ( $value =~ /^y$/i ) {
  open FH, "> network.tests" or die "$!\n";
  print FH "Bleh\n";
  close FH;
}

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.032
sub _add_prereq {
  my ($mm_key, $module, $version_or_range) = @_;
  $version_or_range ||= 0;
  warn "$module already exists in $mm_key -- need to do a sane metamerge!"
    if exists $WriteMakefileArgs{$mm_key}{$module}
      and $WriteMakefileArgs{$mm_key}{$module} ne '0'
      and $WriteMakefileArgs{$mm_key}{$module} ne $version_or_range;
  warn "$module already exists in FallbackPrereqs -- need to do a sane metamerge!"
    if exists $FallbackPrereqs{$module} and $FallbackPrereqs{$module} ne '0'
        and $FallbackPrereqs{$module} ne $version_or_range;
  $WriteMakefileArgs{$mm_key}{$module} = $FallbackPrereqs{$module} = $version_or_range;
  return;
}

sub prompt_default_no {
  prompt("$_[0] [y/N]", 'N') =~ /^y/i ? 1 :0;
}

sub requires { goto &runtime_requires }

sub runtime_requires {
  my ($module, $version_or_range) = @_;
  _add_prereq(PREREQ_PM => $module, $version_or_range);
}
