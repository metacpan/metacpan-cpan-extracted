use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Template::Plugin::DBM::Deep',
    VERSION_FROM      => 'lib/Template/Plugin/DBM/Deep.pm', # finds $VERSION
    PREREQ_PM         => {
			  "Template" => 0,
			  "DBM::Deep" => 0,
			 },
);
