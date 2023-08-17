#
# $Id: Makefile.PL 1926 2023-05-31 12:05:13Z willem $	-*-perl-*-
#

use 5.008009;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use constant MSWin32 => $^O eq 'MSWin32';

my $distro = 'Net::DNS::SEC';
my $module = join '/', 'lib', split /::/, "$distro.pm";
my $author = ['Dick Franks', 'Olaf Kolkman'];
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
	CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.48},
	TEST_REQUIRES	   => {
		'ExtUtils::MakeMaker' => 0,
		'File::Find'	      => 1.13,
		'File::Spec'	      => 3.29,
		'IO::File'	      => 1.14,
		'Test::More'	      => 0.80,
		} );


my %prerequisite = (
	'Carp'	       => 1.10,
	'DynaLoader'   => 1.09,
	'Exporter'     => 5.56,
	'File::Spec'   => 3.29,
	'IO::File'     => 1.14,
	'MIME::Base64' => 2.13,
	'Net::DNS'     => 1.08,
	);


my @debris = qw(*.gcov *.gcda *.gcno *.lock);


my $inc = '';
my $lib = '-lcrypto';
my $nul = MSWin32 ? 'nul' : '/dev/null';

if (`pkg-config --modversion libcrypto 2>$nul`) {
	$inc = `pkg-config --cflags libcrypto 2>$nul`;
	$lib = `pkg-config --libs   libcrypto 2>$nul`;
} elsif (MSWin32) {
	$lib = '-llibeay32' if $Config{cc} =~ /cl/;
	$lib = '-leay32'    if $Config{cc} =~ /gcc/;
}

if ( my $dir = $ENV{OPENSSL_PREFIX} ) {
	chomp $dir;
	$inc = "-I$dir/include";
	$lib = "-L$dir/lib $lib";
}

$inc = $ENV{OPENSSL_INCLUDE} if $ENV{OPENSSL_INCLUDE};
$lib = $ENV{OPENSSL_LIB}     if $ENV{OPENSSL_LIB};
chomp $_ for ( $inc, $lib );


WriteMakefile(
	%metadata,
	PREREQ_PM => {%prerequisite},
	INC	  => $inc,
	LIBS	  => [$lib],
	clean	  => {FILES => "@debris"},
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
PREOP = $(CHMOD) $(PERM_RW) $(DISTVNAME)$(DFSEP)demo$(DFSEP)*
END
}


sub install {
	my $self = shift;

	my %install_type = qw(perl INSTALLARCHLIB site INSTALLSITEARCH vendor INSTALLVENDORARCH);
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
##	The install location for this version of $distro
##	differs from the existing @version in your perl library at
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
	my $ldflags = "-fprofile-arcs -ftest-coverage";
	my $ccflags = "-O0 $ldflags";
	my $devnull = $^O eq 'MSWin32' ? 'nul' : '/dev/null';
	return <<"PlanA" if `gcov -v 2>$devnull`;
test_cover :
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) -W SEC.xs test CCFLAGS="$ccflags" OTHERLDFLAGS="$ldflags"
	cover
	\$(NOECHO) \$(TOUCH) SEC.c	# force XS rebuild before install
PlanA

	return <<'PlanB';
test_cover :
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test
	cover
PlanB
}


__END__

