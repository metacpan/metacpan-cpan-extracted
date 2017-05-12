use ExtUtils::MakeMaker;
WriteMakefile(
	      'NAME'              => 'Regexp::Log::Helix',
	      'VERSION_FROM'      => 'lib/Regexp/Log/Helix.pm',
	      'PREREQ_PM'         => {
		  Regexp::Log => 0.04,
		},
	      'dist'         => {
                        'COMPRESS' => 'gzip -9f', 
                        'SUFFIX'   => 'gz',
                        'DIST_DEFAULT'   => 'all tardist',
                        'PREOP'    => 'perldoc -t ' .
                                      'lib/Regexp/Log/Helix.pm > README',
			}
	      );

