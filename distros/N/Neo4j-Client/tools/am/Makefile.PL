use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $mm = Alien::Build::MM->new;

WriteMakefile($mm->mm_args(
  ABSTRACT => 'Portable instance of automake (v1.16.3)',
  AUTHOR => ['Mark A. Jensen (majensen -at- cpan -dot- org)'],
  DISTNAME => 'tool-AM',
  NAME => 'tool::AM',
  VERSION_FROM => 'lib/tool/AM.pm',
  LICENSE => 'gpl_3',
  PREREQ_PM => {
    'Alien::Base' => 0,
  }

 ));

sub MY::postamble {
  $mm->mm_postamble;
}
