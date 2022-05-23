use strict;
use warnings;
use ExtUtils::MakeMaker;

use Getopt::Long;

my $force;
my $result = GetOptions("force"=>\$force);

if ($] >= 5.015000 and $] < 5.015009 and !$force) {
    warn "Perl version bewteen 5.15.0 and 5.15.8 detected. Sheepishly bailing out of installation because of perl and PDL :lvalue subroutine issue. Use --force with 'perl Makefile.PL' to attemp a build anyways. For more information, please see perl bug ticket #107366 https://rt.perl.org/rt3//Public/Bug/Display.html?id=107366\n";
    exit;
}

my $got_PDL = eval { require PDL::Core::Dev };

WriteMakefile(
    NAME                => 'PDL::Stats',
    AUTHOR              => 'Maggie J. Xiong  <maggiexyz users.sourceforge.net>',
    VERSION_FROM        => 'Stats.pm',
    ABSTRACT_FROM       => 'Stats.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_PM => {
        'PDL'  => '2.057', # ->sum etc return ndarray not Perl scalar
    },
    CONFIGURE_REQUIRES => {
        'PDL::Core'  => 2.008,
    },
    BUILD_REQUIRES => {
        'PDL::Core'  => 2.008,
    },
    TEST_REQUIRES => {
        'PDL::Core'  => 2.008,
        'Test::More' => '0.88', # done_testing
    },
    $got_PDL ? () : (DIR => []), # just write MYMETA if no PDL
    dist                => { PREOP => 'gsl-config --version && $(PERL) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)' },
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
