
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'Net::Netmask',
	'DISTNAME' => 'Net-Netmask',
	'VERSION_FROM' => 'lib/Net/Netmask.pm',
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'},
	($] >= 5.005 
		?	
			(
				ABSTRACT	=> 'Understand and manipulate IP netmaks',
				AUTHOR		=> 'David Muir Sharnoff <cpan@dave.sharnoff.org>',
				META_MERGE     => {
					resources  => {
						repository => 'http://github.com/muir/Net-Netmask',
					},
				},
			) 
		: ()
	),
);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: lib/Net/Netmask.pod
\tpod2text lib/Net/Netmask.pod >README

END_OF_POSTAMBLE
}

