use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Finance::Bank::PNC',
    'VERSION_FROM'  => 'PNC.pm', # finds $VERSION
    'AUTHOR'        => 'Dylan Armstrong <dylanarmstrong116@gmail.com>', 
    'PREREQ_PM'     => { WWW::Mechanize => 0, HTML::TokeParser => 0 }
);