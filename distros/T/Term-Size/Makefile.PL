
use 5;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

die q{OS unsupported\n} if $^O =~ /MSWin/i;

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

);
