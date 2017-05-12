    use ExtUtils::MakeMaker;
    WriteMakefile
      ('DISTNAME' => 'Test-CGI-Untaint',
       'VERSION' => '1.10',
       'PL_FILES' => {},
       'PREREQ_PM' => {
			'Test::Builder::Tester' => '0.09',
			'CGI::Untaint' => '0.82',
			'Test::Builder' => '0',

		      },
      );
