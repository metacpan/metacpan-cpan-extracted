use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'PostScript::MailLabels',
    'VERSION_FROM' => "lib/PostScript/MailLabels.pm", 
	EXE_FILES => [qw(demo/print_addrs)],
    'LICENSE'		=> 'perl',
);
