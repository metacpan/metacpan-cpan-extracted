use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Proc::InvokeEditor',
    'VERSION_FROM'	=> 'lib/Proc/InvokeEditor.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                       'File::Temp' => 0.12,
                       'Test::More' => 0.08,
                       'Carp::Assert' => 0.11,
                       'File::Spec' => 0.82,
                       'IPC::Cmd' => 0,
    }, # e.g., Module::Name => 1.1
    'dist' => {
                'COMPRESS' => 'gzip -9f',
                'SUFFIX'    => 'gz',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Interface to external editor from perl', 
       AUTHOR     => 'Michael Stevens <mstevens@etla.org>') : ()),
    'LICENSE' => 'perl',
);
