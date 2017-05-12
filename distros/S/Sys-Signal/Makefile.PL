use 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Sys::Signal',
    'VERSION_FROM' => 'Signal.pm', # finds $VERSION
#    'DEFINE' => '-g',
    'dist'    => { 
        PREOP => 'pod2text Signal.pm > README', 
    }, 
    'macro' => {
	  CVSROOT => 'modperl.com:/local/cvs_repository',
    },
);

sub MY::postamble { 
    return <<'EOF'; 

cvs_tag :
	cvs -d $(CVSROOT) tag v$(VERSION_SYM) . 
	@echo update Signal.pm VERSION now 
EOF
} 
