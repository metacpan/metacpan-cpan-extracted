use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::SMS::Web',
    'VERSION_FROM'	=> 'Web.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Class::Struct   => 0,
        LWP::UserAgent  => 0,
        CGI::Enurl      => 0,
        URI             => 0,
        CGI::Lite       => 0,
    }, # e.g., Module::Name => 1.1
);
