#
#

use 5.008009;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
my $MM = $ExtUtils::MakeMaker::VERSION;


# See perldoc ExtUtils::MakeMaker for details of how to influence
# the contents of the Makefile that is written.

my %metadata = (
	NAME		 => 'Net::DNS::Resolver::Unbound',
	VERSION_FROM	 => 'lib/Net/DNS/Resolver/Unbound.pm',
	ABSTRACT_FROM	 => 'lib/Net/DNS/Resolver/Unbound.pm',
	AUTHOR		 => 'Dick Franks',
	LICENSE		 => 'mit',
	MIN_PERL_VERSION => 5.008009,
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.66,
		},
	TEST_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.66,
		'File::Find'	      => 1.05,
		'File::Spec'	      => 0.86,
		'IO::File'	      => 1.08,
		'Net::DNS'	      => 1.18,
		'Test::More'	      => 0.47,
		} );


my %prerequisite = (
	'Carp'	     => 1.10,
	'DynaLoader' => 1.04,
	);


my @debris = qw(tmp.* *.gcov *.gcda *.gcno *.lock);


my $inc = '';
my $lib = '-lunbound';
my $nul = $^O eq 'MSWin32' ? 'nul' : '/dev/null';

if ( my $dir = $ENV{UNBOUND_PREFIX} ) {
	$inc = "-I$dir/include";
	$lib = "-L$dir/lib -lcrypto";

} elsif (`pkg-config --modversion libunbound 2>$nul`) {
	$inc = `pkg-config --cflags libunbound 2>$nul`;
	$lib = `pkg-config --libs   libunbound 2>$nul`;

} elsif ( $^O eq 'MSWin32' ) {
	$lib = '-llibunbound' if $Config{cc} =~ /cl/;
	$lib = '-lunbound'    if $Config{cc} =~ /gcc/;
}

$inc = $ENV{UNBOUND_INCLUDE} if $ENV{UNBOUND_INCLUDE};
$lib = $ENV{UNBOUND_LIB}     if $ENV{UNBOUND_LIB};


die "$Config{cc} sanity check failed" if system(<<"EOF");
$Config{echo} "#include <unbound.h>\nint main() { return 0; }" >tmp.c
$Config{cc} -c tmp.c $inc
EOF


WriteMakefile(
	%metadata,
	PREREQ_PM  => {%prerequisite},
	INC	   => $inc,
	LIBS	   => [$lib],
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


sub install {
	my $self = shift;

	my %install_type = qw(perl INSTALLARCHLIB site INSTALLSITEARCH vendor INSTALLVENDORARCH);
	my $install_site = join '', '$(DESTDIR)$(', $install_type{$self->{INSTALLDIRS}}, ')';
	for ($install_site) {
		s/\$\(([A-Z_]+)\)/$self->{$1}/eg while /\$\(/;	# expand Makefile macros
		s|([/])[/]+|$1|g;				# remove gratuitous //s
	}

	my @version = ( 'version', eval { require Net::DNS::Resolver::Unbound; $Net::DNS::Resolver::Unbound::VERSION; } );

	my $nameregex = '\W+Net\W+DNS\W+Resolver\W+Unbound.pm$';
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
##	The install location for this version of Net::DNS::Resolver::Unbound
##	differs from the existing @version in your perl library at
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
	\$(NOECHO) \$(TOUCH) Unbound.c	# recompile XS component
	HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) -W Unbound.xs test CCFLAGS="$ccflags" OTHERLDFLAGS="$ldflags"
	gcov Unbound.xs
	gcov2perl Unbound.xs.gcov
	cover -summary
	\$(NOECHO) \$(TOUCH) Unbound.c	# force XS rebuild before install
PlanA
}


__END__

