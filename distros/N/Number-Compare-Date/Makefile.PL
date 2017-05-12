    use ExtUtils::MakeMaker;
    WriteMakefile
      ('DISTNAME' => 'Number-Compare-Date',
       'VERSION' => '0.02',
       'PL_FILES' => {},
       'PREREQ_PM' => {
			'Test::More' => '0',
			'Number::Compare' => '0.01',
			'Date::Parse' => '2.27',

		      },
      );
