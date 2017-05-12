use ExtUtils::MakeMaker;

my %opts = (
    'NAME'	=> 'Sort::Tree',
    'VERSION_FROM' => 'lib/Sort/Tree.pm' # finds $VERSION
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{AUTHOR}   = 'Bryce Harrington';
    $opts{ABSTRACT} = 'Sorts data structure into child/parent hierarchy';
}

WriteMakefile( %opts )

