package Monitoring::Sneck::Checks::mtime;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::mtime - checks file mtimes against a time

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    old_nginx|perl:mtime -e le -m 2023-06-22T00:00 -f /usr/local/sbin/nginx
    old_app|perl:mtime -m 2024-01-01 -f /usr/local/bin/app -f /usr/local/lib/libapp.so

=head1 DESCRIPTION

A file whose mtime compares true against --mtime is CRITICAL, so with
le, the default, a file from --mtime or before is, for finding
binaries older than a known good build. A file that is not there is
UNKNOWN.

=head1 OPTIONS

- -m, --mtime :: The time, in any format L<Time::Piece::Guess> knows,
UTC if it has no zone. Required.

- -e, --equality :: lt, le, ge, or gt.
Default :: le

- -f, --file :: A file. May be given more than once. Required.

=cut

# How each equality reads in messages, and how it compares a file's mtime to the wanted time, both epochs.
my %EQUALITIES = (
	lt => { words => 'before',       compare => sub { $_[0] < $_[1] } },
	le => { words => 'at or before', compare => sub { $_[0] <= $_[1] } },
	ge => { words => 'at or after',  compare => sub { $_[0] >= $_[1] } },
	gt => { words => 'after',        compare => sub { $_[0] > $_[1] } },
);

# The Getopt::Long specs of the options, see OPTIONS.
#
# Returns the list of specs.
#
# Example...
#
#     my @specs = $check->option_spec;
#     # ( 'mtime|m=s', 'equality|e=s', 'file|f=s@' )
sub option_spec { return ( 'mtime|m=s', 'equality|e=s', 'file|f=s@' ) }

# The option defaults, see OPTIONS.
#
# Returns a hash ref of option names to defaults.
#
# Example...
#
#     my $defaults = $check->defaults;
#     # { equality => 'le' }
sub defaults { return { equality => 'le' } }

# The options that must be given.
#
# Returns the list of option names.
#
# Example...
#
#     my @required = $check->required;
#     # ( 'mtime', 'file' )
sub required { return ( 'mtime', 'file' ) }

# Checks what Getopt::Long can not, the equality being known and the time parsing.
#
# Args...
#
#     - options :: Hash ref of option names to values, defaults included.
#
# Returns a list of what is wrong, each a string, empty if nothing is.
#
# Example...
#
#     my @problems = $check->validate( { mtime => 'nope', equality => 'eq', file => ['/usr/local/sbin/nginx'] } );
#     # ( '--equality must be lt, le, ge, or gt', '--mtime "nope" is not a time Time::Piece::Guess knows' )
sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--equality must be lt, le, ge, or gt' ) if !$EQUALITIES{ $options->{equality} };
	if ( defined( $options->{mtime} ) && !defined( _epoch( $options->{mtime} ) ) ) {
		push( @problems, '--mtime "' . $options->{mtime} . '" is not a time Time::Piece::Guess knows' );
	}

	return @problems;
} ## end sub validate

# Turns a time into a epoch through Time::Piece::Guess, a time without a zone being UTC.
#
# Args...
#
#     - time :: The time, in any format Time::Piece::Guess knows.
#
# Returns the epoch as a integer, or undef if Time::Piece::Guess does not know the format.
#
# Example...
#
#     my $epoch = _epoch('2023-06-22T00:00');
#     # 1687392000
sub _epoch {
	my ($time) = @_;

	require Time::Piece::Guess;
	my $parsed = Time::Piece::Guess->guess_to_object($time);

	return defined($parsed) ? $parsed->epoch : undef;
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $wanted_epoch = _epoch( $self->opt('mtime') );
	my $equality     = $self->opt('equality');
	my @missing;
	my @matched;
	foreach my $file ( @{ $self->opt('file') } ) {
		my $mtime = ( stat($file) )[9];
		if ( !defined($mtime) ) {
			push( @missing, $file );
			next;
		}
		push( @matched, $file ) if $EQUALITIES{$equality}{compare}->( $mtime, $wanted_epoch );
	}

	return $self->finish( $self->UNKNOWN, 'not there: ' . join( ', ', @missing ) ) if @missing;
	my $wanted_text = 'mtime ' . $EQUALITIES{$equality}{words} . ' ' . $self->opt('mtime');
	return $self->finish( $self->CRITICAL, $wanted_text . ': ' . join( ', ', @matched ) ) if @matched;

	return $self->finish( $self->OK, 'none with a ' . $wanted_text );
} ## end sub check

1;
