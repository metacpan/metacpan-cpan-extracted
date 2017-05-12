# vi:set syntax=perl:

require 5.006001;

use strict;
use ExtUtils::MakeMaker;

my $termsize = "Term::Size";
if( $^O =~ m/Win32/i ) {
    $termsize = "Term::Size::Win32";
}

WriteMakefile(
    'NAME'         => 'Term::GentooFunctions',
    'VERSION_FROM' => 'GentooFunctions.pm',
    'PREREQ_PM'    => { 
        $termsize          => 0,
        'Term::ANSIColor'  => 0,
        'Term::ANSIScreen' => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => [qw(einfo ebegin eend)],
                resources=> {
                    repository => 'http://github.com/jettero/term--gentoofunctions',
                },
            },

        LICENSE	=> 'LGPL',
    ) : ()),
);
