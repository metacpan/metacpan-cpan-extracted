package Monitoring::Sneck::Checks::kernel_modules;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);
use POSIX       ();

=head1 NAME

Monitoring::Sneck::Checks::kernel_modules - checks kernel modules are or are not loaded

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are. Set by tests.
our $MODULES = '/lib/modules';
our @MODPROBE_DIRS
	= ( '/etc/modprobe.d', '/run/modprobe.d', '/usr/local/lib/modprobe.d', '/usr/lib/modprobe.d', '/lib/modprobe.d' );
our $KLDSTAT = '/sbin/kldstat';

# The running kernel's release, if set. Set by tests.
our $RELEASE;

=head1 SYNOPSIS

    !no_cramfs|control=CIS-1.1.1.1 framework=CIS|perl:kernel_modules -n cramfs
    !no_usb_storage||perl:kernel_modules -a usb_storage -a firewire_core
    zfs_loaded|perl:kernel_modules -p zfs

=head1 DESCRIPTION

Checks modules are loaded, or are not, as given. Anything not as
given is CRITICAL. - and _ are the same in names, as the kernel takes
them.

--not-loadable goes further than --absent, as CIS wants. The module
must not be loaded, and must also have a "install name /bin/false" or
"/bin/true" line in modprobe.d, so modprobe can not load it either.

On Linux, loaded modules are read from /proc/modules. Built in ones,
from modules.builtin, count as loaded for --present and fail --absent
and --not-loadable, as they can not be kept out. On FreeBSD, kldstat -q -m is asked
about each, and --not-loadable is not supported. Other OSes are
UNKNOWN.

=head1 OPTIONS

- -p, --present :: A module that must be loaded. May be given more
than once.

- -a, --absent :: A module that must not be loaded. May be given more
than once.

- -n, --not-loadable :: A module that must not be loaded or loadable.
May be given more than once.

One or more of --present, --absent, or --not-loadable must be given.

=cut

sub option_spec { return ( 'present|p=s@', 'absent|a=s@', 'not-loadable|n=s@' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	my $any = 0;
	foreach my $name ( 'present', 'absent', 'not-loadable' ) {
		foreach my $module ( @{ $options->{$name} // [] } ) {
			$any++;
			push( @problems, '--' . $name . ' "' . $module . '" is not a module name' )
				if $module !~ /\A[A-Za-z0-9_-]+\z/;
		}
	}
	push( @problems, 'nothing to check, give --present, --absent, or --not-loadable' ) if !$any;

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my ( $loaded, $builtin, $blocked );
	if ( $self->os eq 'linux' ) {
		$loaded  = { map { _normal($_) => 1 } $self->proc_file('modules') =~ /^(\S+)/mg };
		$builtin = $self->builtin;
		$blocked = $self->blocked;
	} elsif ( $self->os eq 'freebsd' ) {
		die("--not-loadable is not supported on freebsd\n") if defined( $self->opt('not-loadable') );
		$loaded = {};
		foreach my $module ( @{ $self->opt('present') // [] }, @{ $self->opt('absent') // [] } ) {
			my ($exit) = $self->run_command( $KLDSTAT, '-q', '-m', $module );
			$loaded->{ _normal($module) } = 1 if !$exit;
		}
		( $builtin, $blocked ) = ( {}, {} );
	} else {
		die( 'not supported on ' . $self->os . "\n" );
	}

	my @problems;
	my @fine;
	foreach my $module ( @{ $self->opt('present') // [] } ) {
		my $normal = _normal($module);
		if ( $loaded->{$normal} || $builtin->{$normal} ) {
			push( @fine, $module . ' loaded' );
		} else {
			push( @problems, $module . ' is not loaded' );
		}
	}
	foreach my $kind ( 'absent', 'not-loadable' ) {
		foreach my $module ( @{ $self->opt($kind) // [] } ) {
			my $normal = _normal($module);
			my @wrong;
			push( @wrong, 'is built in' ) if $builtin->{$normal};
			push( @wrong, 'is loaded' )   if $loaded->{$normal};
			push( @wrong, 'is not kept from loading by a install line in modprobe.d' )
				if $kind eq 'not-loadable' && !$blocked->{$normal} && !$builtin->{$normal};
			if ( defined( $wrong[0] ) ) {
				push( @problems, $module . ' ' . join( ' and ', @wrong ) );
			} else {
				push( @fine, $module . ( $kind eq 'absent' ? ' not loaded' : ' not loadable' ) );
			}
		} ## end foreach my $module ( @{ $self->opt($kind) // []...})
	} ## end foreach my $kind ( 'absent', 'not-loadable' )

	return $self->finish( $self->CRITICAL, join( ', ', @problems ) ) if defined( $problems[0] );
	return $self->finish( $self->OK,       join( ', ', @fine ) );
} ## end sub check

=head2 builtin

Returns a hash ref of the modules built into the running Linux kernel,
from modules.builtin, empty if it is not there.

=cut

sub builtin {
	my ($self) = @_;

	my $release = $RELEASE // ( POSIX::uname() )[2];
	my $content = read_file( $MODULES . '/' . $release . '/modules.builtin', err_mode => 'quiet' ) // '';

	return { map { _normal($_) => 1 } $content =~ m{(?:\A|/)([^/\s]+)\.ko\s*$}mg };
}

=head2 blocked

Returns a hash ref of the modules modprobe.d has a "install name
/bin/false" or "/bin/true" line for.

=cut

sub blocked {
	my ($self) = @_;

	my %blocked;
	foreach my $dir (@MODPROBE_DIRS) {
		foreach my $file ( glob( $dir . '/*.conf' ) ) {
			my $content = read_file( $file, err_mode => 'quiet' ) // next;
			$blocked{ _normal($1) } = 1 while $content =~ m{^\s*install\s+(\S+)\s+(?:/usr)?/bin/(?:false|true)\b}mg;
		}
	}

	return \%blocked;
} ## end sub blocked

# Normalizes a module name, as the kernel takes - and _ as the same.
#
# Args...
#
#     - name :: The module name.
#
# Returns it with - turned into _.
#
# Example...
#
#     _normal('usb-storage');    # 'usb_storage'
sub _normal {
	return $_[0] =~ tr/-/_/r;
}

1;
