use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

WriteMakefile(
    NAME                => 'PDL::Stats',
    AUTHOR              => 'Maggie J. Xiong  <maggiexyz users.sourceforge.net>',
    VERSION_FROM        => 'lib/PDL/Stats.pm',
    ABSTRACT_FROM       => 'lib/PDL/Stats.pm',
    MIN_PERL_VERSION => '5.016', # https://github.com/Perl/perl5/issues/11835
    LICENSE=> 'perl',
    PREREQ_PM => {
        'PDL'  => '2.096', # deep mode
    },
    CONFIGURE_REQUIRES => {
        'PDL'  => '2.096',
    },
    BUILD_REQUIRES => {
        'PDL'  => '2.096',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88', # done_testing
        'Test::PDL' => '0.21',
    },
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

{
my @pd_srcs;
package MY; # so that "SUPER" works right
sub init_PM {
  my ($self) = @_;
  $self->SUPER::init_PM;
  @pd_srcs = ::pdlpp_eumm_update_deep($self);
}
sub postamble { ::pdlpp_postamble_int(@pd_srcs) }
}
