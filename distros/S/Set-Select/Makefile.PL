use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    dist	 => {
	             PREOP	=> 'pod2text lib/Set/Select.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	             COMPRESS	=> 'gzip -9v',
	             SUFFIX	=> '.gz',
	            },
    NAME              => 'Set::Select',
    VERSION_FROM      => 'lib/Set/Select.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Set/Select.pm', # retrieve abstract from module
    AUTHOR            => 'Peter Juhasz <pjuhasz@rt.cpan.org>',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => { web => "https://github.com/pjuhasz/Set-Select/issues" },
            license => [ "http://dev.perl.org/licenses/" ],
            repository => {
                type => "git",
                url => "https://github.com/pjuhasz/Set-Select"
            }
        }
    },

);
