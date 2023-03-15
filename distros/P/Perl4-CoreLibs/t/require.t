use warnings;
use strict;

use Test::More tests => 2*33;

# None of the libraries set a lexical warning state, so they're all
# subject to the -w switch.  Turn that on here so that we'll detect
# warnings that would only show up under -w.
$^W = 1;

foreach my $libfile (qw(
	abbrev.pl assert.pl bigfloat.pl bigint.pl bigrat.pl cacheout.pl
	chat2.pl complete.pl ctime.pl dotsh.pl exceptions.pl fastcwd.pl find.pl
	finddepth.pl flush.pl ftp.pl getcwd.pl getopt.pl getopts.pl hostname.pl
	importenv.pl look.pl newgetopt.pl open2.pl open3.pl pwd.pl
	shellwords.pl stat.pl syslog.pl tainted.pl termcap.pl timelocal.pl
	validate.pl
)) {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };
	require_ok $libfile;
	if($libfile eq "syslog.pl" && @warnings &&
			$warnings[0] =~ /\AYou\ should\ 'use\ Sys::Syslog'
						\ instead;\ continuing\ /x) {
		shift @warnings;
	}
	is_deeply \@warnings, [];
}

1;
