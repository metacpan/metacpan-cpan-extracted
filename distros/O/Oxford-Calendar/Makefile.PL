use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    'NAME'		    => 'Oxford::Calendar',
    'VERSION_FROM'	=> 'lib/Oxford/Calendar.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Text::Abbrev    => 0,
        Date::Calc      => 0,
        YAML            => 0,
        Time::Seconds   => 0,
    }, # e.g., Module::Name => 1.1
    'AUTHOR'        => [
        'Dominic Hargreaves <dom@earth.li>',
    ],
    'ABSTRACT_FROM' => 'lib/Oxford/Calendar.pm',
    'TEST_REQUIRES' => {
        Test::More      => 0,
        Test::Exception => 0,
        Time::Piece     => 0,
    },
    'LICENSE'       => 'artistic_2',
    'META_MERGE'    => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/jmdh/Oxford-Calendar.git',
                web => 'https://github.com/jmdh/Oxford-Calendar',
            },
        },
    },
    
);
