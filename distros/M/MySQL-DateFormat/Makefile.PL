use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'MySQL::DateFormat',
    'VERSION_FROM' => 'DateFormat.pm', # finds $VERSION
    'AUTHOR'       => 'Nick Tonkin (1nickt@gmail.com)',
    'PREREQ_PM'    => { 'Date::Calc' => '0', 'Moose' => '0', 'Moose::Util::TypeConstraints' => '0' },
    'LICENSE'  => 'perl'
);
