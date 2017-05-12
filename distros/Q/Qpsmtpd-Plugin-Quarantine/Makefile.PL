
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'Qpsmtpd::Plugin::Quarantine',
	'DISTNAME' => 'Qpsmtpd-Plugin-Quarantine',
	'VERSION_FROM' => 'lib/Qpsmtpd/Plugin/Quarantine.pm',
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Outbound SPAM Quarantine',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'},
	'PREREQ_PM' => {
		'OOPS'			=> 0.2001,
		'Qpsmtpd'		=> 0.32,
		'File::Slurp'		=> 0,
		'Digest::MD5'		=> 0,
		'Time::HiRes'		=> 0,
		'Template'		=> 0,
		'CGI'			=> 0,
		'Sys::Hostname'		=> 0,
		'Net::Netmask'		=> 0,
		'Mail::SPF::Query'	=> 0,
		'Mail::Field'		=> 0,
		'Net::SMTP'		=> 0,
		'Mail::Address'		=> 0,
		'DB_File'		=> 0,
		'Mail::Field::Received'	=> 0,
		'Sys::Hostname'		=> 0,
		'IO::Handle'		=> 0,
		'Mail::SendVarious'	=> 0,
	 },
);

package MY;

sub postamble {
    <<'END_OF_POSTAMBLE';

pm_to_blib: README

README: lib/Qpsmtpd/Plugin/Quarantine.pod
	pod2text lib/Qpsmtpd/Plugin/Quarantine.pod >README

END_OF_POSTAMBLE
}
