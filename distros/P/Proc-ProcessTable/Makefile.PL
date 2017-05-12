use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::c_o {
  package MY; # so that "SUPER" works right
  my $inherited = shift->SUPER::c_o(@_);
  $inherited =~ s/\$\*\.c/\$\(C_FILES\)/; 
  $inherited;
}

WriteMakefile(
    'ABSTRACT' => 'Perl extension to access the unix process table',
    'AUTHOR' => 'Jonathan Swartz <swartz@pobox.com>',
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'LDFROM'    => '$(O_FILES)',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'LICENSE' => 'perl',
    'NAME'	=> 'Proc::ProcessTable',
    'OBJECT'    => 'ProcessTable.o OS.o',
    'PREREQ_PM'    => { 'File::Find' => 0, 'Storable' => 0 },
    'VERSION_FROM' => 'ProcessTable.pm', # finds $VERSION
    'clean'     => { FILES => 'OS.c' },
    'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
    'test' => { 'TESTS' => 't/*.t' },
    'META_MERGE' => {
         resources => {
             repository  =>  'https://github.com/jwbargsten/perl-proc-processtable',
         },
    },
);
