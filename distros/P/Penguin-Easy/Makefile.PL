use ExtUtils::MakeMaker;
WriteMakefile (
	NAME => 'Penguin::Easy',
	VERSION => '1.1',
    	'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'}
);
