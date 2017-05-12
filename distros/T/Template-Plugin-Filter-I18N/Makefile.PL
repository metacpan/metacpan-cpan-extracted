use 5.008006;
use ExtUtils::MakeMaker 6.48;

WriteMakefile(
	NAME => "Template::Plugin::Filter::I18N",
	VERSION_FROM => "lib/Template/Plugin/Filter/I18N.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Denis Isaev <denis.isaev@gmail.com>',
	MIN_PERL_VERSION => '5.8.6',
	PREREQ_PM => {
		'Locale::gettext'    => '1.05',
		'POSIX'    				=> 0,
		'Template'   => '2.19',
		'ExtUtils::MakeMaker' => '6.48',
	}
);
