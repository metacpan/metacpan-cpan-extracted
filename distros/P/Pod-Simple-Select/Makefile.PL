

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Pod::Simple::Select',
    VERSION_FROM => 'lib/Pod/Simple/Select.pm', # finds \$VERSION
    AUTHOR       => 'FranE<ccedil>ois Rappaz (rappazf@gmail.com)',
    ABSTRACT     => 'Select parts in a file using pod directives',
    PREREQ_PM    => {
                     'Test::More' => 1.001014,
                     'Log::Any' => 1.049,
                     'Carp' => 1.40,
                     'Data::Dumper' => 2.160,
                     'Tie::File' => 1.02,
                     'Pod::Simple' => 3.32,
                    },
   META_MERGE => {
        resources => {
            repository => 'https://sourceforge.net/projects/pod-simple-select/',
        },
    },		    
	TAR => 'ptar', 
	TARFLAGS => '-c -C -f',
       COMPRESS => q{perl -MIO::Compress::Gzip=gzip,:constants -e"my $$in = $$ARGV[0]; gzip($$in => qq($$in.gz), q(Level) => Z_BEST_COMPRESSION, q(BinModeIn) => 1) or die q(gzip failed); unlink $$in;"},	
);
