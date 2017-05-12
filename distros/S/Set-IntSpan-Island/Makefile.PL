use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
     'PREREQ_PM'   => { Set::IntSpan => 1.13, parent => 0 },
     'NAME'	   => 'Set::IntSpan::Island',
     'AUTHOR'      => "Martin Krzywinski (martink@bcgsc.ca)",
     'ABSTRACT'    => "Extension for Set::IntSpan to handle islands, holes and covers.",
     'VERSION_FROM' => 'Island.pm', # finds $VERSION
);
