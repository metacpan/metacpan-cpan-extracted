use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::Digg',
    VERSION_FROM => 'lib/Net/Digg.pm', # finds \$VERSION
    AUTHOR       => 'Kurt Wilms wilms@cs.umn.edu',
    ABSTRACT     => 'Quickly interface with the Digg API. ',
    PREREQ_PM    => {
        'LWP::UserAgent'	=> 0,
        'Test::Simple'		=> 0.44,
		'JSON::Any'		=> 0,
                    },
);
