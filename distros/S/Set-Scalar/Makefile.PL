print "Welcome to Set::Scalar!\n" unless -f "Makefile";

require 5.004_04;

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'         => 'Set::Scalar',
	      'VERSION_FROM' => 'lib/Set/Scalar.pm',
	      'dist'         => { 'COMPRESS' => 'gzip' },
              PREREQ_PM       => { },
              AUTHOR => 'Jarkko Hietaniemi <jhi@iki.fi>',
              META_MERGE => {
                'meta-spec' => { version => 2 },
                resources => {
                  repository => {
                    type => 'git',
                    url => 'https://github.com/daoswald/Set-Scalar.git',
                    web => 'https://github.com/daoswald/Set-Scalar',
                  },
                },
              },
              ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
	       ('LICENSE'=> 'perl', ) : ()),
	      )
and
print <<__EOF__;
Now issue 'make' and then 'make test', and if all looks good, 'make install'.
__EOF__
