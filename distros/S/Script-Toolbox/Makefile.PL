use 5.006;
use ExtUtils::MakeMaker;
#use ExtUtils::Manifest qw(maniread);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Script::Toolbox',
    'VERSION_FROM'	=> 'Toolbox.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				IO::File     => 1.00,
				IO::Dir      => 1.00,
				File::stat   => 1.00,
				Data::Dumper => 2.00,
				Fatal        => 1.00,
				UNIVERSAL    => 1.00,
				Time::ParseDate => 1.00,
			   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Toolbox.pm', # retrieve abstract from module
       AUTHOR     => 'Matthias Eckardt <me@imunixx.de>') : ()),
);
