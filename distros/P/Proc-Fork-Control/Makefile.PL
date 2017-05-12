use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'Proc::Fork::Control',
    'VERSION_FROM' => 'lib/Proc/Fork/Control.pm', # finds $VERSION 
    'dist' => { COMPRESS => "gzip", SUFFIX=>"gz" },
    ($] ge '5.10')
        ? (
            'AUTHOR' => 'Colin Faber <cfaber@fpsn.net>',
            'ABSTRACT' => 'A management front end to fork()',
           )
         : (),
    
);

sub MY::test {
  package MY;
  my $make = shift->SUPER::test();
  $make =~ s/(PERL_DL_NONLAZY)=1/$1=0/g;
  return $make;
}
