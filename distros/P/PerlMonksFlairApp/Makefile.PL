use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'PerlMonksFlairApp',
    AUTHOR              => q{Gideon Israel Dsouza <gideon@cpan.org>},
    VERSION_FROM        => 'lib/PerlMonksFlairApp.pm',
    ABSTRACT            => 'A neat way to share your achievements on perlmonks.org',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'YAML'               => 0,
        'Dancer'             => 1.3116,
		'HTML::TokerParser'  => 3.69,
		'WWW::Mechanize'     => 1.73,
		'GD'                 => 2.50
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PerlMonksFlairApp-*' },
	(ExtUtils::MakeMaker->VERSION >= 6.46 ? 
	        (META_MERGE   => {
                        'meta-spec' => { version => 1.4 },
                        resources => {
                            homepage   => 'http://www.perlmonksflair.com',
                            bugtracker => 'https://github.com/gideondsouza/perlmonksflair/issues/new',
                            repository => 'https://github.com/gideondsouza/perlmonksflair',
                        },
                     },     
	        ) 
	        : ()
	    )
);
