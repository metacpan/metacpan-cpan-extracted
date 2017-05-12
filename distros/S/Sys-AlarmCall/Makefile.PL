use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sys::AlarmCall',
    'PREREQ_PM'       => {
			  'Test::More' => 0,
			 },
    VERSION_FROM      => 'AlarmCall.pm',
    ABSTRACT_FROM     => 'AlarmCall.pm', # retrieve abstract from module
    AUTHOR            => 'Ask Bjoern Hansen <ask@develooper.com>',
);
