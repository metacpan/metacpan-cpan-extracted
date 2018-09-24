#
# $Id: Makefile.PL 1713 2018-09-12 05:57:50Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Getopt::Long;
use ExtUtils::MakeMaker;
use constant MM => eval $ExtUtils::MakeMaker::VERSION;


# See perldoc ExtUtils::MakeMaker for details of how to influence
# the contents of the Makefile that is written.

my @author = ( 'Dick Franks', 'Olaf Kolkman', 'Michael Fuhr' );

my %metadata = (
	NAME		 => 'Net::DNS',
	VERSION_FROM	 => 'lib/Net/DNS.pm',
	ABSTRACT_FROM	 => 'lib/Net/DNS.pm',
	AUTHOR		 => MM < 6.58 ? "$author[0] et al" : [@author],
	LICENSE		 => 'mit',
	MIN_PERL_VERSION => 5.006,
	);


my %platform = (			## platform-specific dependencies
	MSWin32 => {
		'Win32::IPHelper'    => 0.07,
		'Win32::API'	     => 0.55,
		'Win32::TieRegistry' => 0.24,
		} );

my $platform = $platform{$^O} || {};


my %prerequisite = (
	'Digest::HMAC'	 => 1.03,
	'Digest::MD5'	 => 2.13,
	'Digest::SHA'	 => 5.23,
	'File::Spec'	 => 0.86,
	'IO::File'	 => 1.08,
	'IO::Select'	 => 1.14,
	'IO::Socket::IP' => 0.38,
	'MIME::Base64'	 => 2.11,
	'PerlIO'	 => 1.05,
	'Scalar::Util'	 => 1.25,
	'Time::Local'	 => 1.19,
	'Test::More'	 => 0.52,
	%$platform
	);


my %optional = (
	'Net::DNS::SEC'	       => 1.01,	## For information only
	'Digest::BubbleBabble' => 0.01,
	'Net::LibIDN2'	       => 1.00,
	);


my @debris = qw(
		.resolv.conf
		t/IPv6.enabled
		t/online.enabled t/online.nonfatal
		zone[0-9].txt zone[0-9][0-9].txt
		);


delete $optional{'Net::DNS::SEC'};	## Note: MUST NOT be installed automatically


use constant USE_SOCKET_IP => defined eval 'use IO::Socket::IP 0.32; 1;';
use constant INET_FALLBACK => !USE_SOCKET_IP && eval 'require IO::Socket::INET';


# clean up existing makefile
unlink('Makefile');

WriteMakefile(				## Makefile & distribution metadata
	%metadata,
	PREREQ_PM  => {%prerequisite},
	META_MERGE => {recommends => {%optional}},
	clean	   => {FILES => "@debris"},
	);


# clean up the online testing flag file.
unlink("t/online.enabled");
unlink("t/online.disabled");

# clean up the IPv6 testing flag file.
unlink("t/IPv6.enabled");
unlink("t/IPv6.disabled");


#
# Get the command line args
#

my $help = 0;
my $IPv6_tests;
my $online_tests = 2;			##  2 = non-fatal, 1 = on, 0 = off  ##

my @options = (
	'online-tests!'		 => \$online_tests,
	'non-fatal-online-tests' => sub { $online_tests = 2; },
	'IPv6-tests!'		 => \$IPv6_tests,
	'help!'			 => \$help
	);


unless ( GetOptions(@options) ) {
	print "Error: Unrecognized option.\n";
	print "Try perl Makefile.PL --help for more information\n";
	exit 1;
}


if ($help) {
	print <<EOT;

Usage: perl Makefile.PL [OPTION...]

Prepare Makefile for building and installing Net::DNS

  --online-tests		Perform tests by communicating with the
				outside world.	Beware that their success is
				also dependent on outside influences.

  --noonline-tests		Skip online tests completely.

  --IPv6-tests			Perform IPv6 specific online tests. Default is
				the same as regular online tests.

  --noIPv6-tests		Skip IPv6 specific online test

  --non-fatal-online-tests	Perform online test, but do not let failures 
				negatively affect the outcome of running
				make test.  This is the default.

EOT
	exit 0;
}


#
# Check if we have internet connection	(code lifted from LWP)
#
if ($online_tests) {
	my $class = USE_SOCKET_IP ? 'IO::Socket::IP' : 'IO::Socket::INET';

	my $socket = $class->new(
		PeerAddr => "www.google.com:80",
		Timeout	 => 20
		);

	unless ($socket) {
		$online_tests = 0;
		print <<EOT;

You appear not to be directly connected to the Internet.
Disabling online tests altogether...

EOT
	}
}


if ($online_tests) {
	my $enable = 't/online.enabled';
	open( ENABLED, ">$enable" ) || die "Can't touch $enable $!";
	close(ENABLED) || die "Can't touch $enable $!";

	if ( $online_tests == 2 ) {
		my $nonfatal = 't/online.nonfatal';
		open( NONFATAL, ">$nonfatal" ) || die "Can't touch $nonfatal $!";
		close(NONFATAL) || die "Can't touch $nonfatal $!";
		print "\nActivating Non Fatal Online Tests...\n";
	} else {
		print "\nActivating Online Tests...\n";
	}

	$IPv6_tests = 1 unless defined $IPv6_tests;
	if ( USE_SOCKET_IP && $IPv6_tests ) {
		my $enable = 't/IPv6.enabled';
		print "\nActivating IPv6 Tests...\n";
		open( ENABLED, ">$enable" ) || die "Can't touch $enable $!";
		close(ENABLED) || die "Can't touch $enable $!";
	}

	print <<EOT;

Warning!
========
Online tests depend on conditions beyond the control of Net::DNS. The tests 
check for the expected results when both Net::DNS and the outside world are
functioning properly. In case of failure it is often undecidable if the error
lies within Net::DNS or elsewhere.

EOT
}


package MY;				## customise generated Makefile

sub test {
	return shift->SUPER::test() if $^O =~ /cygwin|MSWin/i;

	join '', shift->SUPER::test(), <<'END';
# suppress parallel test execution
FULLPERLRUN = HARNESS_OPTIONS=c $(FULLPERL)
END
}


sub dist {
	return join '', shift->SUPER::dist(), <<'END';

# $(PERM_RWX) raises security issues downstream
PREOP =	$(NOECHO) $(CHMOD) $(PERM_RW) contrib$(DFSEP)* demo$(DFSEP)*
END
}


sub install {
	my $self = shift;

	my %install_type = qw(perl INSTALLPRIVLIB site INSTALLSITELIB vendor INSTALLVENDORLIB);
	my $install_site = join '', '$(DESTDIR)$(', $install_type{$self->{INSTALLDIRS}}, ')';
	for ($install_site) {
		s/\$\(([A-Z_]+)\)/$self->{$1}/eg while /\$\(/;	# expand Makefile macros
		s|([/])[/]+|$1|g;				# remove gratuitous //s
	}

	eval 'require Net::DNS';
	my @version = grep $_, ( 'version', $Net::DNS::VERSION );

	my $nameregex = '\W+Net\WDNS.pm$';
	my @installed = grep $_ && m/$nameregex/io, values %INC;
	my %noinstall;

	foreach (@installed) {
		my $path = $1 if m/^(.+)$nameregex/i;
		my %seen;
		foreach (@INC) {
			$seen{$_}++;				# find $path in @INC
			last if $_ eq $path;
		}
		foreach ( grep !$seen{$_}, @INC ) {
			$noinstall{$_}++;			# mark hidden libraries
		}
	}

	return $self->SUPER::install(@_) unless $noinstall{$install_site};

	my $message;
	warn $message = <<"AMEN";
##
##	The install location for this version of Net::DNS differs
##	from the existing @version in your perl library at
##	@installed
##
##	The installation will be rendered ineffective because the
##	library search finds the existing version before reaching
##	$install_site
##
##	The generated Makefile supports build and test only.
##
AMEN
	my $echo = '	$(NOECHO) $(ECHO) "##"';
	$message =~ s/##/$echo/eg;

	return join '', <<'END', $message;
install :
	$(NOECHO) $(ECHO) "##	Makefile supports build and test only"
	$(NOECHO) $(ECHO) "##	(see message from Makefile.PL)"
	$(NOECHO) $(FALSE)

test :: $(TEST_TYPE)
END
}


sub postamble {
	return <<'END';
test_cover :
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test
	cover -summary
END
}


__END__

