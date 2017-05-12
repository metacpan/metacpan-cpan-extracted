use ExtUtils::MakeMaker;

if(system("rpm --version >run.log 2>&1")) {
    print STDERR "Error: RPM is missing\n";
}

my $abstract = "RPM::Make::Simple - a wrapper module for RPM::Make that is ".
               "(hopefully) simple";

WriteMakefile(
    'NAME'		=> 'RPM::Make::Simple',
    'VERSION_FROM'	=> 'Simple.pm',
    'PREREQ_PM'		=> {RPM::Make => 0.8},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => $abstract,
       AUTHOR     => 'Stephen Hardisty <moowahaha@hotmail.com>') : ()),
);
