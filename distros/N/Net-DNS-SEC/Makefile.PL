#
# $Id: Makefile.PL 1705 2018-08-23 10:24:02Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use constant MM => eval $ExtUtils::MakeMaker::VERSION;


# See perldoc ExtUtils::MakeMaker for details of how to influence
# the contents of the Makefile that is written.

my @author = ( 'Dick Franks', 'Olaf Kolkman' );

my %metadata = (
	NAME		 => 'Net::DNS::SEC',
	VERSION_FROM	 => 'lib/Net/DNS/SEC.pm',
	ABSTRACT_FROM	 => 'lib/Net/DNS/SEC.pm',
	AUTHOR		 => MM < 6.58 ? "$author[0] et al" : [@author],
	LICENSE		 => 'mit',
	MIN_PERL_VERSION => 5.006,
	);


my %prerequisite = (
	'DynaLoader'   => 1.04,
	'File::Find'   => 1.05,
	'File::Spec'   => 0.86,
	'IO::File'     => 1.08,
	'MIME::Base64' => 2.13,
	'Net::DNS'     => 1.08,
	'Test::More'   => 0.47,
	);


my %optional;


my @debris = qw(*.gcov *.gcda *.gcno);


my $def = eval 'require Digest::GOST' ? '' : '-DNO_ECCGOST';
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
	DEFINE	   => $def,
	INC	   => $inc,
	LIBS	   => [$lib],
	META_MERGE => {recommends => {%optional}},
	clean	   => {FILES => "@debris"},
	);


package MY;				## customise generated Makefile

sub special_targets {
	return join "\n\n", '.NOTPARALLEL:', shift->SUPER::special_targets();
}


sub install {
	my $self = shift;

	my %install_type = qw(perl INSTALLARCHLIB site INSTALLSITEARCH vendor INSTALLVENDORARCH);
	my $install_site = join '', '$(DESTDIR)$(', $install_type{$self->{INSTALLDIRS}}, ')';
	for ($install_site) {
		s/\$\(([A-Z_]+)\)/$self->{$1}/eg while /\$\(/;	# expand Makefile macros
		s|([/])[/]+|$1|g;				# remove gratuitous //s
	}

	eval 'require Net::DNS::SEC';
	my @version = grep $_, ( 'version', $Net::DNS::SEC::VERSION );

	my $nameregex = '\W+Net\WDNS\WSEC.pm$';
	my @installed = grep $_ && m/$nameregex/io, values %INC;
	my %hidden;

	foreach (@installed) {
		my $path = $1 if m/^(.+)$nameregex/i;
		my %seen;
		foreach (@INC) {
			$seen{$_}++;				# find $path in @INC
			last if $_ eq $path;
		}
		foreach ( grep !$seen{$_}, @INC ) {
			$hidden{$_}++;				# hidden libraries
		}
	}

	return $self->SUPER::install(@_) unless $hidden{$install_site};

	my $message;
	warn $message = <<"AMEN";
##
##	The install location for this version of Net::DNS::SEC differs
##	from the existing @version in your perl library at
##	@installed
##
##	The installation will be rendered ineffective because the
##	old version will be found on the library search path before
##	$install_site
##
##	Makefile has been generated to support build and test only.
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
	my $nul = $^O eq 'MSWin32' ? 'nul' : '/dev/null';
	return <<"PlanB" unless `gcov -v 2>$nul`;
test_cover :
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test
	cover -summary
PlanB
	my $ccflags = join ' ', qw(-O0 -fprofile-arcs -ftest-coverage);
	my $ldflags = join ' ', qw(-fprofile-arcs -ftest-coverage);
	return <<"PlanA";
test_cover :
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) -W SEC.xs test CCFLAGS="$ccflags" OTHERLDFLAGS="$ldflags"
	gcov SEC.xs
	gcov2perl SEC.xs.gcov
	cover -summary
	\$(NOECHO) touch SEC.c		# force partial rebuild before install
PlanA
}


__END__

