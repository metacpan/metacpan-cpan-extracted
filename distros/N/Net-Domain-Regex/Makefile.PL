use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::Domain::Regex',
    VERSION_FROM => 'lib/Net/Domain/Regex.pm',
    AUTHOR       => 'Peter Blair (pblair@cpan.org)',
    ABSTRACT     => 'Class to extract domain names from text',
    PREREQ_PM    => {
			'LWP::UserAgent' => '6.03',
                    },
);
