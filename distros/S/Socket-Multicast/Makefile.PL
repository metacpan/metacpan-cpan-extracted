use 5.008008;
use ExtUtils::Constant qw(WriteConstants);
use ExtUtils::MakeMaker;

WriteConstants(
	NAME => 'Socket::Multicast',
	NAMES => [qw(
		IP_MULTICAST_IF
		IP_MULTICAST_TTL
		IP_MULTICAST_LOOP
		IP_ADD_MEMBERSHIP
		IP_DROP_MEMBERSHIP
	)],
);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Socket::Multicast',
    VERSION_FROM      => 'lib/Socket/Multicast.pm', # finds $VERSION
    PREREQ_PM         => {
    	ExtUtils::Constant => 0,
	Socket => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Socket/Multicast.pm',
       AUTHOR         => 'Jonathan Steinert <hachi@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
