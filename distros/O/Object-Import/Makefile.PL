use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => "Object::Import",
	ABSTRACT => "import methods of an object as functions to a package",
	VERSION_FROM => "lib/Object/Import.pm",
	PREREQ_PM => {
		"MRO::Compat" => 0, # alternately mro 0 is okay
		"Scalar::Util" => 0,
		"warnings" => 0,
		"IO::Handle" => 0,
		"strict" => 0,
	},
	MIN_PERL_VERSION => 5.00800, # /\pL/
	BUILD_REQUIRES => {
		"MRO::Compat" => 0, # alternately mro 0 is okay
		"Scalar::Util" => 0,
		"warnings" => 0,
		"IO::Handle" => 0,
		"strict" => 0,
		"Test::More" => 0.47, # used in tests
		"Math::BigInt" => 1.59, # used in tests
		"File::Temp" => 0, # used in tests
	},
);
