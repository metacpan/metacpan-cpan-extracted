package Monitoring::Sneck::Checks::selinux;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::selinux - checks SELinux is in the mode it should be

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where selinuxfs is mounted and the config is. Set by tests.
our $SELINUXFS = '/sys/fs/selinux';
our $CONFIG    = '/etc/selinux/config';

=head1 SYNOPSIS

    selinux|perl:selinux
    selinux_permissive|perl:selinux -m permissive

=head1 DESCRIPTION

Checks the mode SELinux is running in, from enforce under
/sys/fs/selinux, it being disabled if that is not there, and the mode
/etc/selinux/config sets for the next boot.

- CRITICAL :: Running in a mode other than --mode.

- WARNING :: /etc/selinux/config setting a mode other than the running
one, which takes effect at the next boot.

- UNKNOWN :: Not being Linux.

The policy type, such as targeted, is from SELINUXTYPE in the config.

=head1 OPTIONS

- -m, --mode :: The mode it should be running in, enforcing,
permissive, or disabled.
Default :: enforcing

=cut

sub option_spec { return ('mode|m=s') }

sub defaults { return { mode => 'enforcing' } }

sub validate {
	my ( $self, $options ) = @_;

	return ('--mode must be enforcing, permissive, or disabled')
		if $options->{mode} !~ /\A(?:enforcing|permissive|disabled)\z/;

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux';

	my $enforce = read_file( $SELINUXFS . '/enforce', err_mode => 'quiet' );
	my $running = 'disabled';
	$running = ( $enforce =~ /\A\s*1/ ? 'enforcing' : 'permissive' ) if defined($enforce);

	my $config        = read_file( $CONFIG, err_mode => 'quiet' ) // '';
	my ($config_mode) = $config =~ /^\s*SELINUX\s*=\s*"?(\w+)/m;
	my ($type)        = $config =~ /^\s*SELINUXTYPE\s*=\s*"?(\w+)/m;

	my @codes = ( $self->OK );
	my @parts = ($running);
	push( @parts, $type . ' policy' ) if defined($type) && $running ne 'disabled';
	if ( $running ne $self->opt('mode') ) {
		push( @codes, $self->CRITICAL );
		push( @parts, 'wanted ' . $self->opt('mode') );
	}
	if ( defined($config_mode) && lc($config_mode) ne $running ) {
		push( @codes, $self->WARNING );
		push( @parts, $CONFIG . ' says ' . lc($config_mode) . ' from the next boot' );
	}

	return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub check

1;
