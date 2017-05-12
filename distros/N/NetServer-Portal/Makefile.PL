use ExtUtils::MakeMaker;

WriteMakefile(
	      PREREQ_PM => {
			    Event => '0.70',
			    'Event::Stats' => 0.8,
			    Storable => '0.6',
			    'Scalar::Util' => '0.1'
			   },
	      VERSION_FROM => "./lib/NetServer/Portal.pm",
	      NAME => 'NetServer::Portal',
	     );
