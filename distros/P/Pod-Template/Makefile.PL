use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Pod::Template',
    VERSION_FROM    => 'lib/Pod/Template.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => { 
                        'Test::More'                => 0, 
                        'Locale::Maketext::Simple'  => 0,
                        'File::Spec'                => 0,
                        'Params::Check'             => 0,
                    },
    #AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	#ABSTRACT        => 'Templated based param validation'
);     

print qq[
After installation, please refer to
    
    perldoc Pod::Template

for documentation on the usage of this module.

You are also encouraged to take a look at the samples directory
in this distribution for examples on how to use Pod::Template.

];

sleep 2;    
    
