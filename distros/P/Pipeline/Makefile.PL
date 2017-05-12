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
	      NAME => 'Pipeline',
	      VERSION_FROM => 'lib/Pipeline.pm',
	      PREREQ_PM => {
			    Scalar::Util => '0.01',
			    Class::ISA   => '0.01',
			    Test::More => '0.01',
			    Error      => '0.15',
			    IO::Null   => '0.01',
			    IO::String => '0.01',
			    Data::UUID => '0.01',
			    Data::Structure::Util => '0.04',
			   }
	     );

1;

