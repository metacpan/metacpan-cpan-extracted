use ExtUtils::MakeMaker;

WriteMakefile (
    NAME         => 'PApp::SQL',
    VERSION_FROM => 'SQL.pm',
    'dist'	=> {
	            PREOP	=> 'pod2text SQL.pm | tee README >$(DISTVNAME)/README; '.
                                   'chown -R root.root .; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'PREREQ_PM'	=> {
                    DBI		=> 1.609,
		   },
);

