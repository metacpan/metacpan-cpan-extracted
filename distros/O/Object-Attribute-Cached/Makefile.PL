use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'      => 'Object::Attribute::Cached',
	'VERSION_FROM' => 'lib/Object/Attribute/Cached.pm', 
	'PREREQ_PM' => {
		'Test::More' => 0.32,
	},
);
