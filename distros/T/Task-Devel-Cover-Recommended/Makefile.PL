use 5.008002;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'Task-Devel-Cover-Recommended';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my $CONFIGURE_PREREQS = {
 'ExtUtils::MakeMaker' => '0',
};

my $BUILD_PREREQS = {
 'ExtUtils::MakeMaker' => '0',
 'Test::More'          => '0',
};

my $RUN_PREREQS = {
 'Browser::Open'               => '0',
 'Capture::Tiny'               => '0',
 'Class::XSAccessor'           => '0',
 'Digest::MD5'                 => '0',
 'JSON::PP'                    => '0',
 'Moo'                         => '0',
 'PPI::HTML'                   => '1.07',
 'Parallel::Iterator'          => '0',
 'Pod::Coverage'               => '0.06',
 'Pod::Coverage::CountParents' => '0',
 'Storable'                    => '0',
 'Template'                    => '2.00',
 'namespace::clean'            => '0',
 'Devel::Cover'                => '1.20',
};

my %META = (
 configure_requires => $CONFIGURE_PREREQS,
 build_requires     => $BUILD_PREREQS,
 dynamic_config     => 0,
 resources          => {
  bugtracker => "http://rt.cpan.org/Dist/Display.html?Name=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 PL_FILES         => {},
 BUILD_REQUIRES   => $BUILD_PREREQS,
 PREREQ_PM        => $RUN_PREREQS,
 MIN_PERL_VERSION => '5.008002',
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text -u $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt*"
 }
);
