use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

WriteMakefile(
    NAME                => 'PDL::Stats',
    AUTHOR              => 'Maggie J. Xiong  <maggiexyz users.sourceforge.net>',
    VERSION_FROM        => 'Stats.pm',
    ABSTRACT_FROM       => 'Stats.pm',
    MIN_PERL_VERSION => '5.016', # https://github.com/Perl/perl5/issues/11835
    LICENSE=> 'perl',
    PREREQ_PM => {
        'PDL'  => '2.073', # PDL_IF_BAD
    },
    CONFIGURE_REQUIRES => {
        'PDL'  => '2.073',
    },
    BUILD_REQUIRES => {
        'PDL'  => '2.073',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88', # done_testing
        'Test::PDL' => '0.21',
    },
    dist                => { PREOP => '$(PERL) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)' },
    clean               => { FILES => ['PDL-Stats-*'] },
    META_MERGE          => {
      "meta-spec" => { version => 2 },
      prereqs => {
        develop => {
          requires => {
            'CPAN::Changes' => 0,
          },
        },
        runtime => {
          recommends => {
            'PDL::Graphics::PGPLOT' => 0,
            'PDL::GSL' => 0,
            'PDL::Slatec' => 0,
          },
        },
      },
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/PDLPorters/PDL-Stats',
          web => 'https://github.com/PDLPorters/PDL-Stats',
        },
      },
    },
);

sub MY::postamble {
  my $oneliner = PDL::Core::Dev::_oneliner(qq{exit if \$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(shift); }});
  qq|\ninstall :: pure_install\n\t$oneliner \$(NAME)\n|;
}
