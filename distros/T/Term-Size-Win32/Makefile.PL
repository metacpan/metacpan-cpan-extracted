
use 5;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    'NAME'            => 'Term::Size::Win32',
    'VERSION_FROM'    => 'lib/Term/Size/Win32.pm',
    'PREREQ_PM'       => {
        'Win32::Console' => 0,
        'Test::More'     => 0, # build 
    }, 
    ($] >= 5.005 ? (
        'ABSTRACT_FROM' => 'lib/Term/Size/Win32.pod',
        'AUTHOR'        => 'Adriano R. Ferreira <ferreira@cpan.org>'
    ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
        LICENSE => 'perl', 
    ) :()),

);
