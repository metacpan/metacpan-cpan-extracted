use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $mm = Alien::Build::MM->new;

WriteMakefile($mm->mm_args(
  ABSTRACT => 'Portable instance of autoconf (v2.68)',
  AUTHOR => ['Mark A. Jensen (majensen -at- cpan -dot- org)'],
  DISTNAME => 'tool-AC',
  NAME => 'tool::AC',
  VERSION_FROM => 'lib/tool/AC.pm',
  LICENSE => 'gpl_3',
  CONFIGURE_REQUIRES => {
    'Alien::Build::MM' => 0,
  },
  PREREQ_PM => {
    'Alien::Base' => 0,
  }

 ));

sub MY::postamble {
  $mm->mm_postamble;
}
