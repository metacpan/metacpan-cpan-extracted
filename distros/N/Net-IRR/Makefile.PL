use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::IRR',
    'VERSION_FROM'	=> 'lib/Net/IRR.pm',
    'PREREQ_PM'		=> { 
                               Test::More       => 0,
                               IO::Socket::INET => 0,
                           },
    (($] ge '5.005') ?
        (   'AUTHOR'   => 'Todd Caine <todd.caine@gmail.com>',
            'ABSTRACT' => 'Perl interface to the Internet Route Registry daemon',
        ) : (),
    ),
);
