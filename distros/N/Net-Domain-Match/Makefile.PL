use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::Domain::Match',
    VERSION_FROM => 'lib/Net/Domain/Match.pm',
    AUTHOR       => 'Peter Blair (cpan@petermblair.com)',
    ABSTRACT     => 'Class to extract domain names from text',
    PREREQ_PM    => {
			'LWP::UserAgent' => '6.03',
                    },
);
