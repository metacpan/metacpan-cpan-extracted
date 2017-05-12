use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'String::CodiceFiscale',
    'VERSION_FROM'  => 'CodiceFiscale.pm', 
    'PREREQ_PM'     => {
        'Test::More'                =>  0,
        'Time::Piece'               =>  0,
        'Class::Data::Inheritable'  =>  0,
    }, 
    AUTHOR          => 'Giulio Motta <giulienk@cpan.org>',
);


