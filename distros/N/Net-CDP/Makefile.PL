use 5.00503;
use ExtUtils::MakeMaker;

package MY;

sub postamble {
	return <<'EOF';
$(MYEXTLIB) :: libcdp/Makefile
$(MYEXTLIB) ::
	cd libcdp && $(MAKE)

libcdp/Makefile: libcdp/Makefile.in
	cd libcdp && ./configure

EOF
}

sub clean_subdirs {
	return <<'EOF';
clean_subdirs: 
	cd libcdp && test -f Makefile && $(MAKE) clean

EOF
}

sub realclean_subdirs {
	return <<'EOF';
realclean_subdirs: 
	cd libcdp && test -f Makefile && $(MAKE) distclean

EOF
}

package main;

# Extract the configure arguments before MakeMaker sees it
my @configure_args;
my @argv;
BEGIN {
	while (my $line = shift @ARGV) {
		if ($line =~ /^configure_args=(.*)/i) {
			push @configure_args, $1;
		} else {
			push @argv, $line;
		}
	}
	@ARGV = @argv;
}

chdir 'libcdp' or die "Could not change to libcdp directory\n";
system("./configure @configure_args") and die "libcdp configure failed\n";
chdir '..' or die "Could not change back to original directory\n";

use vars qw(%config);
do 'libcdp/config.pl';

WriteMakefile(
	NAME         => 'Net::CDP',
	VERSION_FROM => 'libcdp/config.pl',
	PREREQ_PM    => { 'Carp::Clan' => 0, 'Test::More' => 0, },
	($] >= 5.005 ? (
		ABSTRACT_FROM  => 'lib/Net/CDP.pm',
		AUTHOR         => 'Michael Chapman <cpan@very.puzzling.org>'
	) : ()),
	INC          => "@config{qw(LIBPCAP_CPPFLAGS LIBNET_CPPFLAGS)}",
	LIBS         => [ "@config{qw(LIBPCAP_LDFLAGS LIBPCAP_LIBS LIBNET_LDFLAGS LIBNET_LIBS)}" ],
	MYEXTLIB     => 'libcdp/src/.libs/libcdp.a libcdp/lib/.libs/libmisc.a',
);

if (eval { require ExtUtils::Constant; 1 }) {
	my @names = qw(
		CDP_PROMISCUOUS CDP_DISABLE_RECV CDP_DISABLE_SEND
		CDP_RECV_NONBLOCK CDP_RECV_DECODE_ERRORS
		CDP_ADDR_PROTO_CLNP CDP_ADDR_PROTO_IPV4 CDP_ADDR_PROTO_IPV6
		CDP_ADDR_PROTO_DECNET CDP_ADDR_PROTO_APPLETALK CDP_ADDR_PROTO_IPX
		CDP_ADDR_PROTO_VINES CDP_ADDR_PROTO_XNS CDP_ADDR_PROTO_APOLLO
		CDP_CAP_ROUTER CDP_CAP_TRANSPARENT_BRIDGE CDP_CAP_SOURCE_BRIDGE
		CDP_CAP_SWITCH CDP_CAP_HOST CDP_CAP_IGMP CDP_CAP_REPEATER
	);
	ExtUtils::Constant::WriteConstants(
		NAME         => 'Net::CDP::Constants',
		NAMES        => \@names,
		DEFAULT_TYPE => 'UV',
		C_FILE       => 'const-c.inc',
		XS_FILE      => 'const-xs.inc',
	);
} else {
	use File::Copy;
	use File::Spec;
	foreach my $file ('const-c.inc', 'const-xs.inc') {
		my $fallback = File::Spec->catfile('fallback', $file);
		copy($fallback, $file) or die "Can't copy $fallback to $file: $!";
	}
}
