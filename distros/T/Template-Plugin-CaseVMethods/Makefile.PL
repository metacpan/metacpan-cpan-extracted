    use ExtUtils::MakeMaker;
    WriteMakefile
      ('DISTNAME' => 'Template-Plugin-CaseVMethods',
       'VERSION' => '0.01',
       'PL_FILES' => {},
       'PREREQ_PM' => {
			'Test::More' => '0',
			'Template::Plugin::VMethods' => '0',

		      },
      );
