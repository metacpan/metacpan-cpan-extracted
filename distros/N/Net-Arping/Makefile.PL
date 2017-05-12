use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Arping',
    'VERSION_FROM'	=> 'Arping.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Arping.pm', # retrieve abstract from module
       AUTHOR     => 'Oleg Prokopyev <riiki@gu.net>') : ()),
    'LIBS'		=> ['-lnet -lpcap'], # e.g., '-lm'
    'DEFINE'		=> `libnet-config --defines`, # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> `libnet-config --cflags`, # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
