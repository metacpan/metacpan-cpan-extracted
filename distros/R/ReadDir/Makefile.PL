use ExtUtils::MakeMaker;

($^O eq "linux") or ($^O eq "solaris") or warn <<EOD;
############
### This module uses some non-portable C (according to the readdir(3)
### man page) and so may not work on your system.  Use at your own
### risk.
############
EOD

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'ReadDir',
    'VERSION_FROM'	=> 'ReadDir.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ReadDir.pm', # retrieve abstract from module
       AUTHOR     => 'Sam Vilain <sam@vilain.net>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
