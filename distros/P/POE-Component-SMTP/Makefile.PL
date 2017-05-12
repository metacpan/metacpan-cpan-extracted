use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POE::Component::SMTP',
    'VERSION_FROM'	=> 'lib/POE/Component/Server/SMTP.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'POE' => 0, 'POE::Session::MultiDispatch' => 0, 'Test::More' => 0 }, # e.g., Module::Name => 1.1
);
