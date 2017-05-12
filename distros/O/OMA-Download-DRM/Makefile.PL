use 5.8.7;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'OMA::Download::DRM',
    VERSION_FROM      => 'lib/OMA/Download/DRM.pm', # finds $VERSION
    PREREQ_PM         => {
        Crypt::Rijndael => 0.04,
		MIME::Base64    => 0.01
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (LICENSE        => 'GPL_3',
	   ABSTRACT_FROM  => 'lib/OMA/Download/DRM.pm', # retrieve abstract from module
       AUTHOR         => 'Bernard Nauwelaerts <bpgn@cpan.org>') : ())
);
