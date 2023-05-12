#
# $Id: Makefile.PL 1911 2023-04-17 12:30:59Z willem $	-*-perl-*-
#

use 5.008009;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $distro = 'Net::DNS::Multicast';
my $module = join '/', 'lib', split /::/, "$distro.pm";
my $author = ['Dick Franks'];
$author = join ', ', @$author if $ExtUtils::MakeMaker::VERSION < 6.58;


# See perldoc ExtUtils::MakeMaker for details of how to influence
# the contents of the Makefile that is written.

my %metadata = (
	NAME		   => $distro,
	VERSION_FROM	   => $module,
	ABSTRACT_FROM	   => $module,
	AUTHOR		   => $author,
	LICENSE		   => 'mit',
	MIN_PERL_VERSION   => '5.008009',
	CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.48,},
	TEST_REQUIRES	   => {
		'ExtUtils::MakeMaker' => 0,
		'File::Find'	      => 1.13,
		'File::Spec'	      => 3.29,
		'IO::File'	      => 1.14,
		'Test::Builder'	      => 0.80,
		'Test::More'	      => 0.80,
		} );


my %prerequisite = (
	'Net::DNS' => 1.38,
	'Exporter' => 5.56,
	);


my %optional = ();


my @debris = qw(.resolv.conf *.lock);


WriteMakefile(				## Makefile & distribution metadata
	%metadata,
	PREREQ_PM  => {%prerequisite},
	META_MERGE => {recommends => {%optional}},
	clean	   => {FILES	  => "@debris"},
	);

exit;


package MY;				## customise generated Makefile

sub test {
	return join '', shift->SUPER::test(), <<'END' if $^O =~ /MSWin/i;
TEST_DIR = t
FULLPERLRUN = $(FULLPERL) "-I$(TEST_DIR)"
END

	return join '', shift->SUPER::test(), <<'END';
# suppress parallel test execution	include test directory
TEST_DIR = t
FULLPERLRUN = HARNESS_OPTIONS=j1:c $(FULLPERL) "-I$(TEST_DIR)"
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
	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test
	cover
END
}


__END__

