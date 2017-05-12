use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts = (
    'NAME'	       => 'OpenInteract2::Action::RSS',
    'VERSION_FROM' => 'lib/OpenInteract2/Action/RSS.pm',
    'PL_FILES'     => {},
    'NO_META'      => 1,
    'PREREQ_PM'    => {
        'OpenInteract2::Action' => 1.51, # proxy for 2.0b5
        'XML::Feed'             => 0,
    },
);

if ( $ExtUtils::MakeMaker::VERSION >= 5.43 ) {
    $opts{AUTHOR}   = 'Chris Winters <chris@cwinters.com>';
    $opts{ABSTRACT} = 'OpenInteract2 action to retrieve and display an RSS feed.';
}

WriteMakefile( %opts );
