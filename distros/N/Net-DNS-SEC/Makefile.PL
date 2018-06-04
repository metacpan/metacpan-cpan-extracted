#
# $Id: Makefile.PL 1677 2018-05-22 11:59:10Z willem $	-*-perl-*-
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
	INC	   => "$inc",
	LIBS	   => [$lib],
	META_MERGE => {recommends => {%optional}},
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

	warn <<"AMEN";
##
##	The install location for this version of Net::DNS::SEC differs
##	from the existing @version in your perl library.
##	@installed
##
##	The installation will be rendered ineffective because the
##	old version will be found on the library search path before
##	$install_site
##
##	Makefile has been generated to support build and test only.
##
AMEN

	return <<'END';
install :
	$(NOECHO) $(ECHO) "##	Makefile supports test build only"
	$(NOECHO) $(ECHO) "##	(see message from Makefile.PL)"
	$(NOECHO) $(FALSE)
END
}


sub libscan {
	my $path = $_[1];
	return '' if $path =~ /\B\.svn\b/;
	return $path;
}


sub postamble {
	return <<'END';
test_cover : pure_all
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test
	cover -summary
END
}


__END__

