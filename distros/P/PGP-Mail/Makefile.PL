use ExtUtils::MakeMaker;

WriteMakefile(
	    NAME => "PGP::Mail",
	    VERSION_FROM => "Mail.pm",
	    PREREQ_PM => { "GnuPG::Interface" => 0 , "MIME::Tools" => 0 },
);
