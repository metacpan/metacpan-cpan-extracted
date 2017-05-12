use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'PGP::FindKey',
    'VERSION_FROM' => 'FindKey.pm', # finds $VERSION
    'PREREQ_PM' => { LWP::UserAgent => 0, URI::Escape => 0, HTTP::Request => 0 } );
