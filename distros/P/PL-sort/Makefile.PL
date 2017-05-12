use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'PL::sort',
    'VERSION_FROM' => 'sort.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => '£ukasz Strzelecki <l.strzelecki@ita.wat.edu.pl>') : ()),
);
