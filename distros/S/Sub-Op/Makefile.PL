use 5.010;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'Sub-Op';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my %PREREQ_PM = (
 'B::Hooks::EndOfScope' => 0,
 'DynaLoader'           => 0,
 'Scalar::Util'         => 0,
 'Variable::Magic'      => '0.40',
);

my %META = (
 configure_requires => {
  'ExtUtils::Depends'   => 0,
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'Cwd'                 => 0,
  'ExtUtils::Depends'   => 0,
  'ExtUtils::MakeMaker' => 0,
  'File::Spec'          => 0,
  'POSIX'               => 0,
  'Test::More'          => 0,
  'blib'                => 0,
  %PREREQ_PM,
 },
 dynamic_config => 1,
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

use ExtUtils::Depends;

my $ed = ExtUtils::Depends->new($name);
$ed->add_xs('Op.xs');
$ed->add_pm($file => do { local $_ = $file; s/^lib/\$(INST_LIB)/; $_ });
$ed->install('sub_op.h');
$ed->save_config('Files.pm');

my %ed_vars = $ed->get_makefile_vars;
$ed_vars{clean}->{FILES} .= ' ' . join ' ',
      "$dist-*",
      'Files.pm',
      qw{*.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt};

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 PL_FILES         => {},
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => 5.010,
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 FUNCLIST         => [ qw/sub_op_register boot_Sub__Op/ ],
 %ed_vars,
);

{
 my $args_dat = './args.dat';

 open my $fh, '>', $args_dat or die "open(>$args_dat): $!";
 for (@ARGV) {
  my $arg = $_;
  $arg =~ s{\s*(['"])\s*(.*)\s*\1\s*$}{$2}s;
  $arg =~ s{([^=/.a-zA-Z0-9-])}{sprintf "[%d]", ord $1}ge;
  print $fh "$arg\n";
 }
}

sub MY::postamble {
 <<' POSTAMBLE';
configure_test.pl: args.dat

t/Sub-Op-LexicalSub/Makefile: configure_test.pl
	$(FULLPERLRUN) configure_test.pl

all clean:: t/Sub-Op-LexicalSub/Makefile
	cd t/Sub-Op-LexicalSub && $(MAKE) $@

clean::
	$(RM_RF) args.dat
 POSTAMBLE
}
