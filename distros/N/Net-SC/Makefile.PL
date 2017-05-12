use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Net::SC',
	'EXE_FILES'		=> [ 'Contrib/telnet_over_socks_chain.pl', 'Contrib/scssh', 'Contrib/sctelnet' ],
	'VERSION_FROM'	=> 'lib/Net/SC.pm',
	'PREREQ_PM'		=> {
							'MIME::Base64'	=> undef
						},
	'AUTHOR'		=> 'Igor Okunev <igor@prv.mts-nn.ru>',
);

