use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Perl6::Binding',
    VERSION_FROM      => 'lib/Perl6/Binding.pm', # finds $VERSION
    PREREQ_PM         => {
    	'PadWalker'		=>	'0.10',
    	'Filter::Util::Call'	=>	'1.0601',
    	'Text::Balanced'	=>	'1.95',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Perl6/Binding.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin Michael Vail <kevin@vaildc.net>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
