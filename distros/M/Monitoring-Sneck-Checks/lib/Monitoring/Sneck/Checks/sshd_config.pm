package Monitoring::Sneck::Checks::sshd_config;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Basename qw(dirname);
use File::Glob     qw(bsd_glob);
use File::Slurp    qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::sshd_config - checks settings in sshd_config

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# How deep Include may go, the same as sshd.
our $MAX_DEPTH = 16;

=head1 SYNOPSIS

    !ssh_no_root|control=CIS-5.2.10 framework=CIS|perl:sshd_config -e PermitRootLogin=no
    !ssh_auth||perl:sshd_config -e PasswordAuthentication=no -d PasswordAuthentication=yes -e 'MaxAuthTries=3|4'
    !ssh_no_x11||perl:sshd_config -f /usr/local/etc/ssh/sshd_config -e X11Forwarding=no -d X11Forwarding=no

=head1 DESCRIPTION

Reads sshd_config, along with any files it includes, and checks the
value of each setting given. A value that is not one of those allowed
is CRITICAL. So is a setting that is not set and has no --default, or
the file not being readable.

The settings are read the way sshd does. Names are not case sensitive,
and the first value wins. Only the global settings are looked at, so
everything from the first Match on is left out. Values are compared
without case and with runs of spaces squashed, so extra spaces in the
file do not matter.

sshd's own defaults vary by version and OS, so they are not known. Give
--default for any that may be unset, such as -d PermitRootLogin=prohibit-password.

=head1 OPTIONS

- -f, --file :: The file.
Default :: /etc/ssh/sshd_config

- -e, --expect :: "Name=value", a setting and the value it must have.
Several values may be allowed, split by |, such as "MaxAuthTries=3|4".
May be given more than once. Required.

- -d, --default :: "Name=value", what sshd uses if it is not set. May
be given more than once.

- -I, --include-dir :: The directory relative Include paths are under.
sshd takes them from its own config directory, wherever the file it
was given is, so give this when checking a copy kept elsewhere.
Default :: the directory of --file

=cut

sub option_spec { return ( 'file|f=s', 'expect|e=s@', 'default|d=s@', 'include-dir|I=s' ) }

sub defaults { return { file => '/etc/ssh/sshd_config' } }

sub required { return ('expect') }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $name ( 'expect', 'default' ) {
		foreach my $setting ( @{ $options->{$name} // [] } ) {
			push( @problems, '--' . $name . ' "' . $setting . '" is not Name=value' )
				if $setting !~ /\A[A-Za-z0-9]+=\S/;
		}
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my %settings;
	my $problem = $self->read_config( $self->opt('file'), \%settings, 0 );
	return $self->finish( $self->CRITICAL, $problem ) if defined($problem);

	my %defaults;
	foreach my $default ( @{ $self->opt('default') // [] } ) {
		my ( $name, $value ) = split( /=/, $default, 2 );
		$defaults{ lc($name) } = _normal($value);
	}

	my @codes;
	my @problems;
	my @seen;
	foreach my $expect ( @{ $self->opt('expect') } ) {
		my ( $name, $allowed ) = split( /=/, $expect, 2 );
		my $value  = $settings{ lc($name) };
		my $source = '';
		if ( !defined($value) ) {
			$value  = $defaults{ lc($name) };
			$source = ' by default';
		}
		if ( !defined($value) ) {
			push( @codes,    $self->CRITICAL );
			push( @problems, $name . ' is not set' );
			next;
		}
		my %allowed = map { _normal($_) => 1 } split( /\|/, $allowed );
		push( @seen, $name . ' ' . $value . $source );
		next if $allowed{$value};
		push( @codes,    $self->CRITICAL );
		push( @problems, $name . ' is ' . $value . $source . ', not ' . join( ' or ', split( /\|/, $allowed ) ) );
	} ## end foreach my $expect ( @{ $self->opt('expect') } )

	return $self->finish( $self->worst(@codes), join( ', ', @problems ) ) if defined( $problems[0] );
	return $self->finish( $self->OK,            join( ', ', @seen ) );
} ## end sub check

=head2 read_config

Reads a sshd_config file into a hash of settings, following Include.

- file :: The file.

- settings :: Hash ref of lower cased names to normalized values,
added to. The first value of each wins.

- depth :: How many Includes deep this is.

Returns undef, or what went wrong. Once a Match is found, the settings
hash gets the key " match", so nothing after is read.

=cut

sub read_config {
	my ( $self, $file, $settings, $depth ) = @_;

	return 'Include goes over ' . $MAX_DEPTH . ' deep at ' . $file if $depth > $MAX_DEPTH;
	my $content = read_file( $file, err_mode => 'quiet' );
	return 'can not read ' . $file . ', ' . $! if !defined($content);

	foreach my $line ( split( /\r?\n/, $content ) ) {
		return undef if $settings->{' match'};
		$line =~ s/\A\s+|\s+\z//g;
		next if $line eq '' || $line =~ /\A#/;

		my ( $name, $value ) = split( /(?:\s*=\s*|\s+)/, $line, 2 );
		$value //= '';
		if ( lc($name) eq 'match' ) {
			$settings->{' match'} = 1;
			return undef;
		}
		if ( lc($name) eq 'include' ) {
			foreach my $pattern ( split( /\s+/, $value ) ) {
				$pattern = $self->include_dir . '/' . $pattern if $pattern !~ m{\A/};
				foreach my $included ( sort( bsd_glob($pattern) ) ) {
					my $problem = $self->read_config( $included, $settings, $depth + 1 );
					return $problem if defined($problem);
				}
			}
			next;
		} ## end if ( lc($name) eq 'include' )
		$settings->{ lc($name) } //= _normal($value);
	} ## end foreach my $line ( split( /\r?\n/, $content ) )

	return undef;
} ## end sub read_config

=head2 include_dir

Returns the directory relative Include paths are under, --include-dir,
or the directory of --file.

=cut

sub include_dir {
	my ($self) = @_;

	return $self->opt('include-dir') // dirname( $self->opt('file') );
}

# Normalizes a value for comparing, lower casing it, dropping quotes
# around it, and squashing runs of space.
#
# Args...
#
#     - value :: The value.
#
# Returns the normalized value.
#
# Example...
#
#     _normal('"Prohibit-Password"');
#     # 'prohibit-password'
sub _normal {
	my ($value) = @_;

	$value = lc($value);
	$value =~ s/\A"(.*)"\z/$1/;
	$value =~ s/\s+/ /g;

	return $value;
}

1;
