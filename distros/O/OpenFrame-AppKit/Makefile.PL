use ExtUtils::MakeMaker;

# Enable "make cover" target
sub MY::postamble {
  return <<EOF
cover:
\trm -rf cover_db
\tPERL5OPT=-MDevel::Cover make test || true
\tcover -report html cover_db > /dev/null
EOF
}

WriteMakefile(
	      NAME => 'OpenFrame::AppKit',
	      VERSION_FROM => 'lib/OpenFrame/AppKit.pm', 
	      PREREQ_PM => {
			    'Test::More'       => '0.01',
			    'Test::Simple'     => '0.01',
			    'OpenFrame'        => '3.00',
			    'Cache::Cache'     => '0.01',
			    'Template'         => '0.01',
			    'Games::GuessWord' => '0.01',
          'Pipeline'         => '3.01',
		    }
	     );
