
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Install modules I like',
  'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
  'BUILD_REQUIRES' => {
    'Carp' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Task-BeLike-hanekomu',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Task::BeLike::hanekomu',
  'PREREQ_PM' => {
    'AnyEvent' => '0',
    'App::Ack' => '0',
    'App::Rgit' => '0',
    'App::cpanminus' => '0',
    'App::cpanoutdated' => '0',
    'App::distfind' => '0',
    'Coro' => '0',
    'DB::Pluggable' => '0',
    'DB::Pluggable::StackTraceAsHTML' => '0',
    'DBD::SQLite' => '0',
    'DBI' => '0',
    'Devel::Loaded' => '0',
    'Devel::NYTProf' => '0',
    'Devel::SearchINC' => '0',
    'Dist::Zilla' => '0',
    'Dist::Zilla::Plugin::Git::Init' => '0',
    'Dist::Zilla::PluginBundle::MARCEL' => '0',
    'File::Slurp' => '0',
    'File::Which' => '0',
    'LWP' => '0',
    'Perl::Tidy' => '0',
    'Pod::Coverage::TrustPod' => '0',
    'Pod::Weaver::PluginBundle::MARCEL' => '0',
    'Pod::Wordlist::hanekomu' => '0',
    'Task::Plack' => '0',
    'Test::Differences' => '0',
    'Web::Scraper' => '0',
    'YAML' => '0'
  },
  'VERSION' => '1.103620',
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



