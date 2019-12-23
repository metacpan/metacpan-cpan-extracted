use 5.006006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Template::Plugin::Thumbalizr',
    VERSION_FROM      => 'lib/Template/Plugin/Thumbalizr.pm', # finds $VERSION
    PREREQ_PM         => {
	Template::Plugin	=> 0,
	WebService::Thumbalizr	=> 0,
    },
    META_MERGE => {
	'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/juliensobrier/Template-Plugin-Thumbalizr.git',
				web => 'https://github.com/juliensobrier/Template-Plugin-Thumbalizr',
			},
		},
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/Thumbalizr.pm', # retrieve abstract from module
       AUTHOR         => 'Julien Sobrier <jsobrier@localdomain>') : ()),
);
