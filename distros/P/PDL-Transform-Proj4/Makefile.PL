use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use Alien::proj;

my @pd_srcs;
undef &MY::init_PM; # suppress warning
*MY::init_PM = sub {
  package MY; # so that "SUPER" works right
  my ($self) = @_;
  $self->SUPER::init_PM;
  @pd_srcs = ::pdlpp_eumm_update_deep($self);
};
sub MY::postamble { pdlpp_postamble(@pd_srcs) }

WriteMakefile(
  NAME  => 'PDL::Transform::Proj4',
  VERSION_FROM => 'lib/PDL/Transform/Proj4.pd',
  MIN_PERL_VERSION => '5.016',
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'PDL' => '2.096',
    'Alien::proj' => '1.29', # guarantee minimum PROJ 7.1 as need degree_output
  },
  PREREQ_PM => {
    'PDL' => '2.096',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
  INC => Alien::proj->cflags,
  LIBS => [Alien::proj->libs],
  clean => { FILES => join ' ', qw(MANIFEST.bak) },
  NO_MYMETA => 1,
);
