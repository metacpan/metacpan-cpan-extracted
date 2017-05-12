use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts = (
    'NAME'	       => 'OpenInteract2::Observer::UsePerlPost',
    'VERSION_FROM' => 'lib/OpenInteract2/Observer/UsePerlPost.pm',
    'PL_FILES'     => {},
    'NO_META'      => 1,
    'PREREQ_PM'    => {
        'OpenInteract2::Action' => 1.51, # proxy for 1.99_05
        'Net::Blogger'          => 0.87,
    },
);

if ( $ExtUtils::MakeMaker::VERSION >= 5.43 ) {
    $opts{AUTHOR}   = 'Chris Winters <chris@cwinters.com>';
    $opts{ABSTRACT} = 'Observer of OpenInteract2 actions to post a use.perl article';
}

WriteMakefile( %opts );
