
use ExtUtils::MakeMaker;

WriteMakefile(
                'NAME'          => 'Net::SMS::MessageNet',
                'VERSION_FROM'  => 'lib/Net/SMS/MessageNet.pm',
                'PREREQ_PM'     => {
                                'Test::More' => 0,
				'LWP' => 0,
				'HTTP::Cookies' => 0,
				'URI::Escape' => 0,
				'Net::HTTPS' => 0,
				'Net::SSL' => 0,
				'Crypt::SSLeay' => 0,
                                        },
);
