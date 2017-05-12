use ExtUtils::MakeMaker;

WriteMakefile(NAME => 'TM::View',
	      VERSION    => '0.5',
	      AUTHOR => 'Alexander Zangerl <alphazulu@cpan.org>',
	      PREREQ_PM => { 
		  "TM" => 1.43 ,
		  "Test::More"    => 0.47,
		  "XML::Writer" => 0,
		  "Data::Dumper" => 0,
	      }
	      );
