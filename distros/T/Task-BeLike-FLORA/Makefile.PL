
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Modules FLORA uses',
  'AUTHOR' => 'Florian Ragwitz <rafl@debian.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Task-BeLike-FLORA',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Task::BeLike::FLORA',
  'PREREQ_PM' => {
    'Acme::MetaSyntactic' => '0',
    'App::Ack' => '0',
    'App::Metabase::Relayd' => '0',
    'App::Nopaste' => '0',
    'App::Software::License' => '0',
    'App::cpanminus' => '0',
    'App::cpanoutdated' => '0',
    'CPAN::Mini' => '0',
    'CPAN::Mini::Devel' => '0',
    'CPAN::Reporter' => '0',
    'CPAN::Uploader' => '0',
    'Carp::Always' => '0',
    'Carp::Always::Color' => '0',
    'Carp::REPL' => '0',
    'Catalyst::Model::KiokuDB' => '0',
    'Data::Visitor' => '0',
    'Devel::Cover' => '0',
    'Devel::NYTProf' => '0',
    'Devel::bt' => '0',
    'Dist::Zilla' => '0',
    'Dist::Zilla::PluginBundle::FLORA' => '0',
    'Email::MIME::Kit' => '0',
    'Email::MIME::Kit::Assembler::Markdown' => '0',
    'Email::MIME::Kit::Renderer::TT' => '0',
    'Email::Sender' => '0',
    'Function::Parameters' => '0',
    'Gitalist' => '0',
    'JSON' => '0',
    'List::AllUtils' => '0',
    'Method::Signatures::Simple' => '0',
    'Module::CPANTS::Analyse' => '0',
    'Module::Install' => '0.95',
    'Module::Install::AuthorRequires' => '0',
    'Module::Install::AuthorTests' => '0',
    'Module::Install::CheckConflicts' => '0',
    'Module::Install::ExtraTests' => '0',
    'Moose' => '0',
    'Moose::Autobox' => '0',
    'MooseX::Declare' => '0',
    'MooseX::LazyRequire' => '0',
    'MooseX::Types::Common' => '0',
    'MooseX::Types::DateTime' => '0',
    'MooseX::Types::Email' => '0',
    'MooseX::Types::LoadableClass' => '0',
    'MooseX::Types::Path::Class' => '0',
    'MooseX::Types::URI' => '0',
    'PadWalker' => '0',
    'Perl::Tidy' => '0',
    'Perl::Version' => '1.010',
    'Pod::Coverage::TrustPod' => '0',
    'Task::Catalyst' => '0',
    'Task::KiokuDB' => '0',
    'Task::Plack' => '0',
    'Task::SDK::Moose' => '0',
    'Term::ReadLine::Gnu' => '0',
    'Test::Aggregate' => '0',
    'Test::Pod' => '0',
    'Test::Pod::Coverage' => '0',
    'Test::Reporter' => '0',
    'Test::Reporter::Transport::Socket' => '0',
    'Test::WWW::Mechanize::Catalyst' => '0',
    'Test::Without::Module' => '0',
    'V' => '0'
  },
  'VERSION' => '0.06',
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



