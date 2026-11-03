package Monitoring::Sneck::Checks::file_mode;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::file_mode - checks the mode, owner, and group of files

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    !shadow_mode|control=CIS-6.1.3 framework=CIS|perl:file_mode -f /etc/shadow -M 0640 -o root
    !ssh_keys||perl:file_mode -f /etc/ssh/ssh_host_ed25519_key -f /etc/ssh/ssh_host_rsa_key -m 0600 -o root -g 0
    !tmp_sticky||perl:file_mode -f /tmp -m 1777

=head1 DESCRIPTION

Checks each file is as given. Any that is not, or is not there, is
CRITICAL, unless --ignore-missing is given. Symlinks are followed.

--mode needs the mode to be exactly that, while --max-mode allows less,
so 0640 allows 0600 and 0400 but not 0644.

=head1 OPTIONS

- -f, --file :: A file. May be given more than once. Required.

- -m, --mode :: The mode it must have, in octal, such as 0600.

- -M, --max-mode :: The most it may have, in octal, such as 0640.

- -o, --owner :: The user that must own it, by name or UID.

- -g, --group :: The group that must own it, by name or GID.

- -i, --ignore-missing :: Files not there are OK.

One or more of --mode, --max-mode, --owner, or --group must be given.

=cut

sub option_spec { return ( 'file|f=s@', 'mode|m=s', 'max-mode|M=s', 'owner|o=s', 'group|g=s', 'ignore-missing|i' ) }

sub required { return ('file') }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $name ( 'mode', 'max-mode' ) {
		push( @problems, '--' . $name . ' must be octal, such as 0640' )
			if defined( $options->{$name} ) && $options->{$name} !~ /\A[0-7]{3,4}\z/;
	}
	push( @problems, '--owner "' . $options->{owner} . '" is not a user' )
		if defined( $options->{owner} ) && !defined( _id( $options->{owner}, 'user' ) );
	push( @problems, '--group "' . $options->{group} . '" is not a group' )
		if defined( $options->{group} ) && !defined( _id( $options->{group}, 'group' ) );
	push( @problems, 'nothing to check, give --mode, --max-mode, --owner, or --group' )
		if !grep { defined( $options->{$_} ) } ( 'mode', 'max-mode', 'owner', 'group' );

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @codes;
	my @problems;
	my @seen;
	foreach my $file ( @{ $self->opt('file') } ) {
		my @stat = stat($file);
		if ( !defined( $stat[0] ) ) {
			next if $self->opt('ignore-missing') && !-e $file;
			push( @codes,    $self->CRITICAL );
			push( @problems, $file . ', ' . $! );
			next;
		}

		my $mode  = $stat[2] & 07777;
		my $owner = getpwuid( $stat[4] ) // $stat[4];
		my $group = getgrgid( $stat[5] ) // $stat[5];
		my @wrong;
		if ( defined( $self->opt('mode') ) && $mode != oct( $self->opt('mode') ) ) {
			push( @wrong, 'mode is not ' . $self->opt('mode') );
		}
		if ( defined( $self->opt('max-mode') ) && ( $mode & ~oct( $self->opt('max-mode') ) ) ) {
			push( @wrong, 'mode is more than ' . $self->opt('max-mode') );
		}
		if ( defined( $self->opt('owner') ) && $stat[4] != _id( $self->opt('owner'), 'user' ) ) {
			push( @wrong, 'owner is not ' . $self->opt('owner') );
		}
		if ( defined( $self->opt('group') ) && $stat[5] != _id( $self->opt('group'), 'group' ) ) {
			push( @wrong, 'group is not ' . $self->opt('group') );
		}

		my $is = $file . ' ' . sprintf( '%04o', $mode ) . ' ' . $owner . ':' . $group;
		push( @seen, $is );
		if ( defined( $wrong[0] ) ) {
			push( @codes,    $self->CRITICAL );
			push( @problems, $is . ', ' . join( ', ', @wrong ) );
		}
	} ## end foreach my $file ( @{ $self->opt('file') } )

	return $self->finish( $self->worst(@codes), join( ', ', @problems ) ) if defined( $problems[0] );
	return $self->finish( $self->OK, defined( $seen[0] ) ? join( ', ', @seen ) : 'none of the files are there' );
} ## end sub check

# Turns a user or group name into its ID. A number is taken as a ID.
#
# Args...
#
#     - name :: The name or ID.
#
#     - kind :: 'user' or 'group'.
#
# Returns the ID, or undef if there is no such user or group.
#
# Example...
#
#     _id( 'root', 'user' );    # 0
#     _id( '1234', 'group' );   # 1234
sub _id {
	my ( $name, $kind ) = @_;

	return $name + 0 if $name =~ /\A[0-9]+\z/;
	my @entry = $kind eq 'user' ? getpwnam($name) : getgrnam($name);

	return $entry[2];
}

1;
