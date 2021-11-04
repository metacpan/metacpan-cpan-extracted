use strict;
use warnings;
use ExtUtils::MakeMaker;

my(%param, $emv, $name);

%param = (
    NAME                   => 'Net::STOMP::Client',
    AUTHOR                 => 'Lionel Cons <lionel.cons@cern.ch>',
    VERSION                => '2.5',
    ABSTRACT_FROM          => 'lib/Net/STOMP/Client.pm',
    LICENSE                => 'perl',
    PL_FILES               => {},
    BUILD_REQUIRES => {
        # optional: Pod::Coverage
        'Test::More'       => 0,
        # optional: Test::Pod
        # optional: Test::Pod::Coverage
    },
    PREREQ_PM => {
	# optional: Authen::Credential
        'Encode'           => 0,
        'IO::Socket::INET' => 0,
        'IO::Socket::IP'   => 0,
	# optional: IO::Socket::SSL
        'List::Util'       => 0,
	# optional: Messaging::Message
        'No::Worries'      => '1.2',
        'Params::Validate' => 0,
        'POSIX'            => 0,
        'Time::HiRes'      => 0,
    },
    dist                   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                  => { FILES => 'Net-STOMP-Client-*' },
);

($emv = $ExtUtils::MakeMaker::VERSION) =~ s/_//;
if ($emv < 6.5503) {
    # missing BUILD_REQUIRES
    foreach $name (keys(%{ $param{BUILD_REQUIRES} })) {
	$param{PREREQ_PM}{$name} = $param{BUILD_REQUIRES}{$name};
    }
    delete($param{BUILD_REQUIRES});
}
if ($emv < 6.31) {
    # missing LICENSE
    delete($param{LICENSE});
}

WriteMakefile(%param);
