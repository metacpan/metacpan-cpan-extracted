package Monitoring::Sneck::Checks::reboot_needed;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);
use POSIX       ();

=head1 NAME

Monitoring::Sneck::Checks::reboot_needed - checks if a reboot or restarts are needed after updates

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are looked for. Set by tests.
our $BOOT            = '/boot';
our $MODULES         = '/lib/modules';
our $DPKG_STATUS     = '/var/lib/dpkg/status';
our $REBOOT_REQUIRED = '/var/run/reboot-required';
our $FREEBSD_VERSION = '/bin/freebsd-version';

# The running kernel's release, as uname -r says, if set. Set by tests.
our $RELEASE;

=head1 SYNOPSIS

    reboot|perl:reboot_needed
    restarts|perl:reboot_needed -l

=head1 DESCRIPTION

WARNING, or CRITICAL with --critical, if updates are waiting on a
reboot.

On Linux, that is any of...

- /var/run/reboot-required :: Is there, as Debian and Ubuntu packages
leave it. What it says and the packages in reboot-required.pkgs are
added.

- a newer kernel :: Is installed than the one running, going by the
/boot/vmlinuz-* and /lib/modules/*/vmlinuz there are.

- the kernel package :: For Debian, the version of the installed
linux-image package for the running kernel is not the one running, as
for a update that kept the same ABI, and so the same release.

On FreeBSD, it is freebsd-version -k, the installed kernel, not being
freebsd-version -r, the one running. Other OSes are UNKNOWN.

With --libraries, on Linux, processes using libraries that were since
replaced are listed as well, as they need restarting to use the new
ones, the same as needrestart finds. This reads /proc/*/maps, so needs
root to see every process. On FreeBSD it does nothing.

=head1 OPTIONS

- -l, --libraries :: Also list processes using replaced libraries. Linux
only.

- -n, --lines :: How many processes using replaced libraries to list.
Default :: 20

- -c, --critical :: Make it CRITICAL in place of WARNING.

=cut

sub option_spec { return ( 'libraries|l', 'lines|n=i', 'critical|c' ) }

sub defaults { return { lines => 20 } }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @reasons;
	my @details;
	if ( $self->os eq 'linux' ) {
		push( @reasons, $self->linux_reasons( \@details ) );
		push( @reasons, $self->replaced_libraries( \@details ) ) if $self->opt('libraries');
	} elsif ( $self->os eq 'freebsd' ) {
		push( @reasons, $self->freebsd_reasons );
	} else {
		die( 'not supported on ' . $self->os . "\n" );
	}

	if ( !defined( $reasons[0] ) ) {
		return $self->finish( $self->OK, 'running ' . $self->release . ', nothing is waiting on a reboot' );
	}

	return $self->finish( $self->opt('critical') ? $self->CRITICAL : $self->WARNING, join( ', ', @reasons ), @details );
} ## end sub check

=head2 release

Returns the release of the running kernel, as uname -r says.

=cut

sub release {
	return $RELEASE // ( POSIX::uname() )[2];
}

=head2 linux_reasons

Returns the reasons Linux needs a reboot, as said under
L</DESCRIPTION>, adding a line listing the packages in
reboot-required.pkgs to the array ref given.

=cut

sub linux_reasons {
	my ( $self, $details ) = @_;

	my @reasons;
	my $release = $self->release;
	if ( -e $REBOOT_REQUIRED ) {
		my $says = read_file( $REBOOT_REQUIRED, err_mode => 'quiet' ) // '';
		$says =~ s/\A\s*\**\s*|\s*\**\s*\z//g;
		push( @reasons, $REBOOT_REQUIRED . ' is there' . ( $says ne '' ? ', "' . $says . '"' : '' ) );
		my $packages = read_file( $REBOOT_REQUIRED . '.pkgs', err_mode => 'quiet' );
		push( @{$details}, 'for ' . join( ', ', sort( _unique( split( /\s+/, $packages ) ) ) ) )
			if defined($packages) && $packages =~ /\S/;
	}

	my %installed;
	foreach my $vmlinuz ( glob( $BOOT . '/vmlinuz-*' ), glob( $MODULES . '/*/vmlinuz' ) ) {
		my ($version) = $vmlinuz =~ m{/vmlinuz-([^/]+)\z};
		($version) = $vmlinuz =~ m{/([^/]+)/vmlinuz\z} if !defined($version);
		$installed{$version} = 1 if defined($version);
	}
	my ($newest) = sort { _version_cmp( $b, $a ) } keys(%installed);
	if ( defined($newest) && _version_cmp( $newest, $release ) > 0 ) {
		push( @reasons, 'kernel ' . $newest . ' is installed, but ' . $release . ' is running' );
	}

	# Debian puts the package version last in /proc/version, such as "Debian 6.12.48-1 (2025-09-20)",
	# after the compiler's, which may say Debian too
	my $proc_version = eval { $self->proc_file('version') } // '';
	my $running      = ( $proc_version =~ /\bDebian ([0-9][^\s()]*)/g )[-1];
	my $package      = 'linux-image-' . $release;
	my $packaged     = defined($running) ? $self->dpkg_version($package) : undef;
	if ( defined($packaged) && $packaged ne $running ) {
		push( @reasons, $package . ' ' . $packaged . ' is installed, but ' . $running . ' is running' );
	}

	return @reasons;
} ## end sub linux_reasons

=head2 dpkg_version

Returns the version of a installed package from dpkg's status file,
or undef if it is not installed.

    my $version = $check->dpkg_version('linux-image-6.12.48+deb13-amd64');

=cut

sub dpkg_version {
	my ( $self, $package ) = @_;

	my $status = read_file( $DPKG_STATUS, err_mode => 'quiet' ) // '';
	foreach my $stanza ( split( /\n\n+/, $status ) ) {
		next      if $stanza !~ /^Package: \Q$package\E$/m;
		next      if $stanza !~ /^Status: \S+ \S+ installed$/m;
		return $1 if $stanza =~ /^Version: (\S+)$/m;
	}

	return undef;
} ## end sub dpkg_version

=head2 replaced_libraries

Returns a reason if processes use libraries that were replaced, adding
a line for each process to the array ref given, with the libraries it
uses, up to --lines of them.

=cut

sub replaced_libraries {
	my ( $self, $details ) = @_;

	my %uses;
	opendir( my $proc, $Monitoring::Sneck::Checks::base::PROC ) or return ();
	foreach my $pid ( grep { /\A[0-9]+\z/ } readdir($proc) ) {
		next if $pid == $$;
		my $maps      = eval { $self->proc_file( $pid . '/maps' ) } // next;
		my %libraries = map { ( split( m{/}, $_ ) )[-1] => 1 } $maps =~ m{\s(/\S+\.so(?:\.[0-9.]+)?) \(deleted\)$}mg;
		next if !%libraries;
		my $name = eval { $self->proc_file( $pid . '/comm' ) } // $pid;
		$name =~ s/\s+\z//;
		$uses{ $name . '[' . $pid . ']' } = [ sort( keys(%libraries) ) ];
	}
	my @processes = sort( keys(%uses) );
	return () if !defined( $processes[0] );

	my @lines = map { $_ . ' uses ' . join( ', ', @{ $uses{$_} } ) } @processes;
	my @shown = splice( @lines, 0, $self->opt('lines') );
	push( @shown,      'and ' . scalar(@lines) . ' more' ) if defined( $lines[0] );
	push( @{$details}, @shown );

	return ( scalar(@processes) . ' process' . ( scalar(@processes) == 1 ? '' : 'es' ) . ' using replaced libraries' );
} ## end sub replaced_libraries

=head2 freebsd_reasons

Returns the reasons FreeBSD needs a reboot, as said under
L</DESCRIPTION>.

=cut

sub freebsd_reasons {
	my ($self) = @_;

	my ( $exit, $output ) = $self->run_command( $FREEBSD_VERSION, '-k', '-r' );
	die( $FREEBSD_VERSION . ' exited ' . $exit . "\n" ) if $exit;
	my ( $installed, $running ) = split( /\n/, $output );
	die( $FREEBSD_VERSION . ' did not say both versions' . "\n" ) if !defined($running);
	return ()                                                     if $installed eq $running;

	return ( 'kernel ' . $installed . ' is installed, but ' . $running . ' is running' );
} ## end sub freebsd_reasons

# Compares two versions, such as kernel releases, number by number and
# the rest as text, so 6.12.48 comes after 6.1.0 and 6.12.9.
#
# Args...
#
#     - a, b :: The versions, such as '6.12.48+deb13-amd64'.
#
# Returns -1, 0, or 1, as cmp.
#
# Example...
#
#     _version_cmp( '6.12.48+deb13-amd64', '6.1.0-28-amd64' );    # 1
sub _version_cmp {
	my ( $first, $second ) = @_;

	my @first  = $first  =~ /([0-9]+|[^0-9]+)/g;
	my @second = $second =~ /([0-9]+|[^0-9]+)/g;
	while ( @first || @second ) {
		my $one   = shift(@first)  // '';
		my $other = shift(@second) // '';
		my $order
			= ( $one =~ /\A[0-9]+\z/ && $other =~ /\A[0-9]+\z/ )
			? $one <=> $other
			: $one cmp $other;
		return $order if $order;
	}

	return 0;
} ## end sub _version_cmp

# Returns the list given, each only once, in order, leaving out empty strings.
#
# Args...
#
#     - list :: The items.
#
# Example...
#
#     _unique( 'a', 'b', 'a' );    # ( 'a', 'b' )
sub _unique {
	my %seen;

	return grep { $_ ne '' && !$seen{$_}++ } @_;
}

1;
