use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $mm = Alien::Build::MM->new;

WriteMakefile($mm->mm_args(
  ABSTRACT => 'Portable instance of m4 (v1.4.18)',
  AUTHOR => ['Mark A. Jensen (majensen -at- cpan -dot- org)'],
  DISTNAME => 'tool-M4',
  NAME => 'tool::M4',
  VERSION_FROM => 'lib/tool/M4.pm',
  LICENSE => 'gpl_3',
  PREREQ_PM => {
    'Alien::Base' => 0,
  }

 ));

sub MY::postamble {
  $mm->mm_postamble;
}
