#
# $Id: Makefile.PL 1853 2021-10-11 10:40:59Z willem $	-*-perl-*-
#

use 5.008008;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
my $MM = $ExtUtils::MakeMaker::VERSION;


# See perldoc ExtUtils::MakeMaker for details of how to influence
# the contents of the Makefile that is written.

my @author = ( 'Dick Franks', 'Olaf Kolkman' );

my %metadata = (
	NAME		 => 'Net::DNS::SEC',
	VERSION_FROM	 => 'lib/Net/DNS/SEC.pm',
	ABSTRACT_FROM	 => 'lib/Net/DNS/SEC.pm',
	AUTHOR		 => $MM < 6.58 ? "$author[0] et al" : [@author],
	LICENSE		 => 'mit',
	MIN_PERL_VERSION => 5.008008,
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.66,
		},
	TEST_REQUIRES => {
		'File::Find'	=> 1.05,
		'File::Spec'	=> 0.86,
		'Test::More'	=> 0.47,
		} );


my %prerequisite = (
	'Carp'	       => 1.10,
	'DynaLoader'   => 1.04,
	'Exporter'     => 5.56,
	'File::Spec'   => 0.86,
	'MIME::Base64' => 2.13,
	'Net::DNS'     => 1.08,
	);


my %optional;


my @debris = qw(*.gcov *.gcda *.gcno *.lock);


my $inc = '';
my $lib = '-lcrypto';
my $nul = $^O eq 'MSWin32' ? 'nul' : '/dev/null';

if ( my $dir = $ENV{OPENSSL_PREFIX} ) {
	$inc = "-I$dir/include";
	$lib = "-L$dir/lib -lcrypto";

} elsif (`pkg-config --modversion libcrypto 2>$nul`) {
	$inc = `pkg-config --cflags libcrypto 2>$nul`;
	$lib = `pkg-config --libs   libcrypto 2>$nul`;

} elsif ( $^O eq 'MSWin32' ) {
	$lib = '-llibeay32' if $Config{cc} =~ /cl/;
	$lib = '-leay32'    if $Config{cc} =~ /gcc/;
}

$inc = $ENV{OPENSSL_INCLUDE} if $ENV{OPENSSL_INCLUDE};
$lib = $ENV{OPENSSL_LIB}     if $ENV{OPENSSL_LIB};

WriteMakefile(
	%metadata,
	PREREQ_PM  => {%prerequisite},
	INC	   => $inc,
	LIBS	   => [$lib],
	META_MERGE => {recommends => {%optional}},
	clean	   => {FILES => "@debris"},
	);


package MY;				## customise generated Makefile

sub test {
	return shift->SUPER::test() if $^O =~ /cygwin|MSWin/i;

	return join '', shift->SUPER::test(), <<'END';
# suppress parallel test execution
FULLPERLRUN = HARNESS_OPTIONS=c $(FULLPERL)
END
}


sub dist {
	return join '', shift->SUPER::dist(), <<'END';

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

	my @version = ( 'version', eval { require Net::DNS::SEC; $Net::DNS::SEC::VERSION; } );

	my $nameregex = '\W+Net\W+DNS\W+SEC.pm$';
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
##	The install location for this version of Net::DNS::SEC differs
##	from the existing @version in your perl library at
##	@installed
##
##	The installation would be rendered ineffective because the
##	installed version occurs in the library search path before
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
	my $devnull = $^O eq 'MSWin32' ? 'nul' : '/dev/null';
	return <<"PlanB" unless `gcov -v 2>$devnull`;
test_cover :
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test
	cover -summary
PlanB
	my $ldflags = "-fprofile-arcs -ftest-coverage";
	my $ccflags = "-O0 $ldflags";
	return <<"PlanA";
test_cover :
	cover -delete
	\$(NOECHO) \$(TOUCH) SEC.c	# recompile XS component
	HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) -W SEC.xs test CCFLAGS="$ccflags" OTHERLDFLAGS="$ldflags"
	gcov SEC.xs
	gcov2perl SEC.xs.gcov
	cover -summary
	\$(NOECHO) \$(TOUCH) SEC.c	# force XS rebuild before install
PlanA
}


__END__

