
use 5;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;
my $is_win32 = ($^O =~ /MSWin/i);

WriteMakefile(
	'NAME'          => 'Term::Size',
	'VERSION_FROM'  => 'Size.pm',
	'PREREQ_PM'     => {
		'Test::More'            => 0, # build
	}, 
	($] >= 5.005 ? (
		'ABSTRACT_FROM' => 'Size.pm',
	) : ()),
        ($EUMM_VERSION >= 6.30_01 ? (
	        LICENSE => 'perl', # needs EEUU > 6.30_01
        ) : ()),

) unless $is_win32;

ExtUtils::MakeMaker::WriteEmptyMakefile(
	'NAME'          => 'Term::Size',
	'VERSION_FROM'  => 'Size.pm',
) if $is_win32;


