use strict;
use warnings;
use ExtUtils::MakeMaker;

use Getopt::Long;

my $force;
my $result = GetOptions("force"=>\$force);

if ($] >= 5.015000 and $] < 5.015009 and !$force) {
    warn "Perl version between 5.15.0 and 5.15.8 detected. Sheepishly bailing out of installation because of perl and PDLA :lvalue subroutine issue. Use --force with 'perl Makefile.PL' to attemp a build anyways. For more information, please see perl bug ticket #107366 https://rt.perl.org/rt3//Public/Bug/Display.html?id=107366\n";
    exit;
}

WriteMakefile(
    NAME                => 'PDLA::Stats',
    AUTHOR              => 'Maggie J. Xiong  <maggiexyz users.sourceforge.net>',
    VERSION_FROM        => 'Stats.pm',
    ABSTRACT_FROM       => 'Stats.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_PM => {
        'PDLA::Core'  => 2.008,
        'PDLA::Graphics::PGPLOT' => 0,
        'PGPLOT' => 0,
        'PDLA::Slatec' => 0,
    },
    CONFIGURE_REQUIRES => {
        'PDLA::Core'  => 2.008,
    },
    BUILD_REQUIRES => {
        'PDLA::Core'  => 2.008,
        'PDLA::Graphics::PGPLOT' => 0,
        'PGPLOT' => 0,
        'PDLA::Slatec' => 0,
    },
    TEST_REQUIRES => {
        'PDLA::Core'  => 2.008,
        'Test::More' => 0,
        'PDLA::Graphics::PGPLOT' => 0,
        'PGPLOT' => 0,
        'PDLA::Slatec' => 0,
    },
    DIR                 => ['Basic', 'Distr', 'GLM', 'Kmeans', 'GSL', 'TS'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => ['PDLA-Stats-*'] },
    META_MERGE          => {
      "meta-spec" => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/PDLPorters/pdla-stats',
          web => 'https://github.com/PDLPorters/pdla-stats',
        },
      },
    },
);

sub MY::postamble {
    my $text =
'
install ::
	@echo "Updating PDLA documentation database ..."
	@$(PERL) add_doc.pl

';

    return $text;
}
