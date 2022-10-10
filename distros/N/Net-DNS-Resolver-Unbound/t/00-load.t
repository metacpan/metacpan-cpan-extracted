#!/usr/bin/perl
#

use strict;
use warnings;
use IO::File;
use Test::More tests => 2;

my @module = qw(
		Net::DNS
		Net::DNS::Resolver::Unbound
		Net::DNS::Resolver::libunbound
		);

my %metadata;
my $handle = IO::File->new('MYMETA.json') || IO::File->new('META.json');
if ($handle) {
	my $json = join '', (<$handle>);
	for ($json) {
		s/\s:\s/ => /g;					# Perl? en voilà!
		my $hashref = eval $_;
		%metadata = %$hashref;
	}
	close $handle;
}

my %prerequisite;
foreach ( values %{$metadata{prereqs}} ) {			# build, runtime, etc.
	foreach ( values %$_ ) {				# requires
		$prerequisite{$_}++ for keys %$_;
	}
	delete @prerequisite{@module};
	delete $prerequisite{perl};
}

my @diag;
foreach my $module ( @module, sort keys %prerequisite ) {
	eval "require $module";		## no critic
	for ( eval { $module->VERSION || () } ) {
		s/^(\d+\.\d)$/${1}0/;
		push @diag, sprintf "%-30s  %s", $module, $_;
	}
}
diag join "\n\t", "\nThese tests were run using:", @diag;


unless ( ok( eval { Net::DNS::Resolver::libunbound->VERSION }, 'XS component Unbound.xs loaded' ) ) {
	diag( "\n", <<'RIP', "\n" );
Unresolved library references can be identified by running ldd:
[Example]

$ ldd blib/arch/auto/Net/DNS/Resolver/Unbound/Unbound.so
	linux-vdso.so.1 (0x00007ffc26ba4000)
	libunbound.so.8 => /lib64/libunbound.so.8 (0x00007f171ead5000)
	libperl.so.5.34 => /lib64/libperl.so.5.34 (0x00007f171e740000)
	libc.so.6 => /lib64/libc.so.6 (0x00007f171e536000)
	libssl.so.1.1 => /lib64/libssl.so.1.1 (0x00007f171e488000)
	libprotobuf-c.so.1 => /lib64/libprotobuf-c.so.1 (0x00007f171e47d000)
	libevent-2.1.so.7 => /lib64/libevent-2.1.so.7 (0x00007f171e424000)
	libpython3.10.so.1.0 => /lib64/libpython3.10.so.1.0 (0x00007f171e0dd000)
	libcrypto.so.1.1 => /lib64/libcrypto.so.1.1 (0x00007f171ddef000)
	libnghttp2.so.14 => /lib64/libnghttp2.so.14 (0x00007f171ddc7000)
	libm.so.6 => /lib64/libm.so.6 (0x00007f171dceb000)
	libcrypt.so.2 => /lib64/libcrypt.so.2 (0x00007f171dcb1000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f171ec31000)
	libz.so.1 => /lib64/libz.so.1 (0x00007f171dc97000)
RIP
	BAIL_OUT("Unable to access libunbound\n");
}

use_ok('Net::DNS::Resolver::Unbound');

exit;


END {
	eval { Net::DNS::SEC::libcrypto::croak_memory_wrap() }	# paper over crack in Devel::Cover
}


__END__

