use 5.000;
use ExtUtils::MakeMaker;

my $PREREQ_PM = {
	'Test'        =>  0,
	'File::Path'  =>  0,
	'File::Spec'  =>  0,
	'File::Temp'  =>  0,
	'File::Copy'  =>  0,
	'POSIX'       =>  0,
	'Carp'        =>  0,
};

if ($^O =~ m/^MSWin/) {
    $PREREQ_PM->{Win32} = 0;
    $PREREQ_PM->{Win32::Process} = 0;
    $PREREQ_PM->{Win32::Job} = 0;
}

WriteMakefile(
    NAME              => 'Proc::PersistentControl',
    VERSION_FROM      => 'lib/Proc/PersistentControl.pm', # finds $VERSION
    PREREQ_PM         => $PREREQ_PM,
    PREREQ_PM         => {'Test'        =>  0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Proc/PersistentControl.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Staats <michael.staats@gmx.eu>') : ()),
);
