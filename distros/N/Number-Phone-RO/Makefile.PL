use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Number::Phone::RO',
	VERSION_FROM      => 'lib/Number/Phone/RO.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Number::Phone 0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=number-phone-ro.git',
		},
	}
);
