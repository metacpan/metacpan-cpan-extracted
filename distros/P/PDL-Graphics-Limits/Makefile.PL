use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

WriteMakefile(
  NAME => 'PDL::Graphics::Limits',
  VERSION_FROM => 'Limits.pm',
  AUTHOR => 'Diab Jerius <djerius@cpan.org>',
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.016',
  CONFIGURE_REQUIRES => {
    'PDL' => '2.095',
    'ExtUtils::MakeMaker' => '7.14',
  },
  PREREQ_PM => {
    'PDL' => '2.095',
    'PDL::Fit::Polynomial' => 0,
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
    'Test::Exception' => 0,
    'Test::PDL' => '0.21',
    'PDL' => '2.095', # Test::PDL
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>'https://github.com/PDLPorters/PDL-Graphics-Limits/issues'},
      repository  => {
        url => 'git://github.com/PDLPorters/PDL-Graphics-Limits.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/PDL-Graphics-Limits',
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
);

sub MY::postamble {
  my $oneliner = PDL::Core::Dev::_oneliner(qq{exit if \$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(shift); }});
  qq|\ninstall :: pure_install\n\t$oneliner \$(NAME)\n|;
}
