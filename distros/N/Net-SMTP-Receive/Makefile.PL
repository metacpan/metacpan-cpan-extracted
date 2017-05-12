
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'Net::SMTP::Receive',
	'DISTNAME' => 'Net-SMTP-Receive',
	'VERSION_FROM' => 'Receive.pm',
	'PREREQ_PM' => {
		'File::Slurp' => 96.042202,
		'File::Flock' => 101.05_18_01,
		'Time::CTime' => 99.06_22_01,
		'Net::Ident' => 1.20,
		'Storable' => 0.611,
		'File::Sync' => 0.09,
	},
	($] >= 5.005 
		?	
			(
				ABSTRACT	=> 'Receive mail via SMTP',
				AUTHOR		=> 'David Muir Sharnoff <cpan@dave.sharnoff.org>',
				META_MERGE     => {
					resources  => {
						repository => 'http://github.com/muir/Net-SMTP-Receive',
					},
				},
			) 
		: ()
	),
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);


package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: Receive.pod
\tpod2text Receive.pod >README

END_OF_POSTAMBLE
}
