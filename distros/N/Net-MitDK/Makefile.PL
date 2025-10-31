use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME           => 'Net::MitDK',
	AUTHOR         => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM  => 'lib/Net/MitDK.pm',
	VERSION_FROM   => 'lib/Net/MitDK.pm',
        EXE_FILES      => [
		map { "bin/mitdk$_" } qw(2pop -dump -authenticate -renew-lease -install-win32),
	],
        LICENSE        => 'freebsd',
	PREREQ_PM      => {
		'LWP'             => 0,
		'IO::Lambda'      => 1.33,
		'DateTime'        => 0,
		'MIME::Entity'    => 0,
		'MIME::Base64'    => 0,
		'JSON::XS'        => 0,
		'Getopt::Long'    => 0,
		'Digest::SHA'     => 0,
		'IO::Socket::SSL' => 0,
	},
	MIN_PERL_VERSION  => 5.018,
	META_MERGE     => {
		resources => {
			repository => 'http://github.com/dk/Net-MitDK'
		},
	},
);

if ( $^O !~ /win32/i) {
	my $uid = getpwnam('nobody');
	warn "\n** Warning: user `nobody` not found. Run `sudo adduser nobody` if you need to run mitdk2pop\n"
		unless defined $uid;
	my $found;
	while (my @m = getgrent) {
		next unless $m[0] eq 'nobody';
		warn "\n** Warning: user `nobody` is not a member of group `nobody`. Run `sudo usermod -a -G nobody nobody` if you need to run mitdk2pop\n"
			unless $m[3] =~ /\bnobody\b/;
		$found = 1;
		last;
	}
	warn "\n** Warning: group `nobody` not found. Run `sudo addgroup nobody` if you need to run mitdk2pop\n"
		unless $found;
}

