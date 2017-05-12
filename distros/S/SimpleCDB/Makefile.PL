use ExtUtils::MakeMaker;
use 5.003;

WriteMakefile
(
	NAME			=> 'SimpleCDB',
	VERSION_FROM	=> 'SimpleCDB.pm',
	dist			=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

print <<EOM;

Now do the following to install SimpleCDB:

	% make 
	% make test  (runs an elementary test for approximately 2-5 minutes)
	% make install

EOM

