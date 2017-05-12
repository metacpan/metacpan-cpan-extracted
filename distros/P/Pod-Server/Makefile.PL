use ExtUtils::MakeMaker;

WriteMakefile (
  NAME          => 'Pod::Server',
  AUTHOR        => 'John BEPPU <beppu@cpan.org>',
  LICENSE       => 'mit',
  VERSION_FROM  => 'lib/Pod/Server.pm',
  ABSTRACT_FROM => 'lib/Pod/Server.pm',
  EXE_FILES     => [ 'bin/pod_server' ],
  PREREQ_PM     => {
    'Squatting'           => 0.81,
    'Pod::Simple::HTML'   => 0,
    'Pod::Simple::Search' => 0,
    'HTML::AsSubs'        => 0,
    'File::Which'         => 0,
    'Text::VimColor'      => 0,
    'aliased'             => 0,
  },
);

sub MY::libscan {
  my $self = shift;
  $_       = shift;
  # $self appears to be a blessed hashref that contains
  # all the attributes/value pairs passed to WriteMakeFile()
  # plus some other MakeMaker-related info.
  return 0 if /\.sw.$/ || /~$/;
  return $_;
}

sub MY::postamble {q{
}}
