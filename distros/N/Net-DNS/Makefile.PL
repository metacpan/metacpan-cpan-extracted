#
# $Id: Makefile.PL 2007 2025-02-08 16:45:23Z willem $	-*-perl-*-
#

use 5.008009;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $distro = 'Net::DNS';
my $module = join '/', 'lib', split /::/, "$distro.pm";
my $author = ['Dick Franks', 'Olaf Kolkman', 'Michael Fuhr'];
$author = join ', ', @$author if $ExtUtils::MakeMaker::VERSION < 6.58;


# See perldoc ExtUtils::MakeMaker for details of how to influence
# the contents of the Makefile that is written.

my %metadata = (
	NAME		   => $distro,
	VERSION_FROM	   => $module,
	ABSTRACT_FROM	   => $module,
	AUTHOR		   => $author,
	LICENSE		   => 'mit',
	MIN_PERL_VERSION   => 5.008009,
	CONFIGURE_REQUIRES => {
		'Config'	      => 0,
		'ExtUtils::MakeMaker' => 6.48,
		'Getopt::Long'	      => 2.43,
		'IO::File'	      => 1.14,
		'IO::Socket::IP'      => 0.38,
		},
	TEST_REQUIRES => {
		'ExtUtils::MakeMaker' => 0,
		'File::Find'	      => 1.13,
		'File::Spec'	      => 3.29,
		'IO::File'	      => 1.14,
		'Test::Builder'	      => 0.80,
		'Test::More'	      => 0.80,
		} );


my %platform = (			## platform-specific dependencies
	MSWin32 => {
		'Win32::IPHelper'    => 0.07,
		'Win32::API'	     => 0.55,
		'Win32::TieRegistry' => 0.24,
		} );

my $platform = $platform{$^O} || {};


my %prerequisite = (
	'Carp'		 => 1.10,
	'Digest::HMAC'	 => 1.03,
	'Digest::MD5'	 => 2.37,
	'Digest::SHA'	 => 5.23,
	'Encode'	 => 2.26,
	'Exporter'	 => 5.63,
	'File::Spec'	 => 3.29,
	'IO::File'	 => 1.14,
	'IO::Select'	 => 1.17,
	'IO::Socket'	 => 1.30,
	'IO::Socket::IP' => 0.38,
	'MIME::Base64'	 => 3.07,
	'PerlIO'	 => 1.05,
	'Scalar::Util'	 => 1.19,
	'Socket'	 => 1.81,
	'Time::Local'	 => 1.19,
	'base'		 => 2.13,
	'constant'	 => 1.17,
	'integer'	 => 1.00,
	'overload'	 => 1.06,
	'strict'	 => 1.03,
	'warnings'	 => 1.0501,
	%$platform
	);


my %optional = (
	'Digest::BubbleBabble' => 0.02,
	'Net::LibIDN2'	       => 1.00,
	);


## IMPORTANT:	THE USE AND/OR HANDLING OF STRONG ENCRYPTION TECHNOLOGIES IS
##		PROHIBITED OR SEVERELY RESTRICTED IN MANY TERRITORIES.
delete $prerequisite{'Net::DNS::SEC'};	## MUST NOT list Net::DNS::SEC dependency in metadata.
delete $optional{'Net::DNS::SEC'};	## Require explicit user action to install Net::DNS::SEC.


my @debris = qw(.resolv.conf *.lock);


#
# Get the command line args
#
use constant USE_GETOPT => defined eval { require Getopt::Long };

my $help	 = 0;
my $IPv6_tests	 = 1;
my $online_tests = 2;			##  2 = non-fatal, 1 = on, 0 = off  ##

my @options = (
	'online-tests!'		 => \$online_tests,
	'non-fatal-online-tests' => sub { $online_tests = 2; },
	'IPv6-tests!'		 => \$IPv6_tests,
	'help!'			 => \$help
	);


if ( USE_GETOPT && !Getopt::Long::GetOptions(@options) ) {
	print "Error: Unrecognized option.\n";
	print "Try perl Makefile.PL --help for more information\n";
	exit 1;
}


if ($help) {
	print <<'EOT';

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
# Enable tests if we have internet connection	(code lifted from LWP)
#
use constant USE_SOCKET_IP => defined eval 'use IO::Socket::IP 0.38; 1;';    ## no critic
require IO::Socket::INET unless USE_SOCKET_IP;

if ($online_tests) {
	my $class = USE_SOCKET_IP ? 'IO::Socket::IP' : 'IO::Socket::INET';

	my $socket = $class->new(
		PeerAddr => 'dns.google.',
		PeerPort => 53,		## check 53/TCP not blocked ##
		Timeout	 => 10
		);

	unless ($socket) {
		$online_tests = 0;
		print <<"EOT";

Unable to establish TCP/IP connection to the global Internet.
$@

Disabling online tests altogether...

EOT
	}
}


# set up online testing configuration files.
my $enable   = 't/online.enabled';
my $IPv6     = 't/IPv6.enabled';
my $nonfatal = 't/online.nonfatal';
push @debris, $enable, $IPv6, $nonfatal;

if ($online_tests) {
	require IO::File;
	my $fh1 = IO::File->new( $enable, '>' ) or die "Can't touch $enable $!";
	close($fh1);

	if ( $online_tests == 2 ) {
		print "\nActivating Non Fatal Online Tests...\n";
		my $fh2 = IO::File->new( $nonfatal, '>' ) or die "Can't touch $nonfatal $!";
		close($fh2);
	} else {
		print "\nActivating Online Tests...\n";
	}

	if ( USE_SOCKET_IP && $IPv6_tests ) {
		print "\nActivating IPv6 Tests...\n";
		my $fh3 = IO::File->new( $IPv6, '>' ) or die "Can't touch $IPv6 $!";
		close($fh3);
	}

	print <<'EOT';

Warning!
========
Online tests depend on conditions beyond the control of Net::DNS. The tests 
check for the expected results when both Net::DNS and the outside world are
functioning properly. In case of failure it is often undecidable if the error
lies within Net::DNS or elsewhere.

EOT
}


WriteMakefile(				## Makefile & distribution metadata
	%metadata,
	PREREQ_PM  => {%prerequisite},
	META_MERGE => {recommends => {%optional}},
	clean	   => {FILES	  => "@debris"},
	);

exit;


package MY;				## customise generated Makefile

sub constants {
	return join "\n", shift->SUPER::constants(), <<'END' if $^O =~ /MSWin/i;
#	include test directory
TEST_DIR = t
FULLPERLRUN = $(FULLPERL) "-I$(TEST_DIR)"
END
	return join "\n", shift->SUPER::constants(), <<'END';
#	suppress parallel test execution	include test directory
TEST_DIR = t
FULLPERLRUN = HARNESS_OPTIONS=j1:c $(FULLPERL) "-I$(TEST_DIR)"
END
}


sub dist {
	return join "\n", shift->SUPER::dist(), <<'END';
# $(PERM_RWX) raises security issues downstream
PREOP = $(CHMOD) $(PERM_RW) $(DISTVNAME)$(DFSEP)contrib$(DFSEP)* $(DISTVNAME)$(DFSEP)demo$(DFSEP)*
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

	eval "require $distro";		## no critic
	my @version = ( 'version', eval { $distro->VERSION } );

	my $nameregex = join '\W+', '', split /::/, "$distro.pm\$";
	my @installed = grep { $_ && m/$nameregex/io } values %INC;
	my %occluded;

	foreach (@installed) {
		my $path = m/^(.+)$nameregex/io ? $1 : '';
		my %seen;
		foreach (@INC) {
			$seen{$_}++;				# find $path in @INC
			last if $_ eq $path;
		}
		foreach ( grep { !$seen{$_} } @INC ) {
			$occluded{$_}++;			# suppress install
		}
	}

	return $self->SUPER::install(@_) unless $occluded{$install_site};

	my $message;
	warn $message = <<"AMEN";
##
##	The install location for this version of $distro differs
##	from the existing @version in your perl library at
##	@installed
##
##	The installation would be rendered ineffective because the
##	existing @version occurs in the library search path before
##	$install_site
##
##	The generated Makefile supports build and test only.
##
AMEN
	my $echo = '	$(NOECHO) $(ECHO) "##"';
	$message =~ s/##/$echo/eg;

	return join '', <<"END";
install :
	$message
	\$(NOECHO) \$(FALSE)
END
}


sub postamble {
	return <<'END';
test_cover :
	cover -delete
	cover -test
END
}


__END__

