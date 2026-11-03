package Monitoring::Sneck::Checks::accounts;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::accounts - checks local user accounts

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are. Set by tests.
our $PASSWD        = '/etc/passwd';
our $SHADOW        = '/etc/shadow';
our $MASTER_PASSWD = '/etc/master.passwd';
our $SHELLS        = '/etc/shells';

=head1 SYNOPSIS

    !accounts|control=CIS-6.2 framework=CIS|perl:accounts -s
    !no_guest||perl:accounts -a guest -a test -p backup

=head1 DESCRIPTION

Checks the local accounts, from the files, not through NSS, so those
from LDAP and the like are not looked at. Each of these is CRITICAL.

- a UID of 0 :: For any account not given by --uid0, by default root,
and toor on FreeBSD.

- no password :: An account with a empty password field, which can log
in without one. Locked accounts, * or !, are fine. This needs reading
/etc/shadow, or /etc/master.passwd on FreeBSD, so root. Not being able
to is UNKNOWN, unless --no-passwords is given. A empty field in
/etc/passwd itself counts too, as that is what is used then, whatever
/etc/shadow has.

- duplicates :: Two accounts with the same name or UID. UID 0 is left to
the check above.

- --absent and --present :: Accounts that must not, or must, be there.

- --system-shells :: System accounts, those under --min-uid, with a
shell from /etc/shells, read as getusershell does, so one that can log
in. root, sync, shutdown, halt, and toor are left out, as are those
given by --ignore.

Other OSes than Linux and FreeBSD are UNKNOWN.

=head1 OPTIONS

- -u, --uid0 :: A account that may have a UID of 0. May be given more
than once.
Default :: root, and toor on FreeBSD

- -n, --no-passwords :: Do not check for empty passwords.

- -s, --system-shells :: Check system accounts do not have a login shell.

- -m, --min-uid :: The lowest UID of accounts for people.
Default :: 1000

- -i, --ignore :: A system account that may have a login shell. May be
given more than once.

- -a, --absent :: A account that must not be there. May be given more
than once.

- -p, --present :: A account that must be there. May be given more than
once.

=cut

sub option_spec {
	return (
		'uid0|u=s@',   'no-passwords|n', 'system-shells|s', 'min-uid|m=i',
		'ignore|i=s@', 'absent|a=s@',    'present|p=s@'
	);
}

sub defaults { return { 'min-uid' => 1000 } }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $accounts = $self->accounts;
	my %uid0     = map { $_ => 1 } @{ $self->opt('uid0') // [ 'root', ( $self->os eq 'freebsd' ? 'toor' : () ) ] };
	my %by_name  = map { $_->{name} => $_ } @{$accounts};
	my @problems;
	my @unknown;

	my @root_like = grep { $_->{uid} == 0 && !$uid0{ $_->{name} } } @{$accounts};
	push( @problems, 'UID 0 for ' . join( ', ', map { $_->{name} } @root_like ) ) if defined( $root_like[0] );

	foreach my $field ( 'name', 'uid' ) {
		my %count;
		# UID 0 is left to the check for it above, as toor shares it with root on FreeBSD
		$count{ $_->{$field} }++ foreach grep { $field ne 'uid' || $_->{uid} != 0 } @{$accounts};
		my @duplicates = sort( grep { $count{$_} > 1 } keys(%count) );
		push( @problems, 'more than one account with the ' . $field . ' ' . join( ', ', @duplicates ) )
			if defined( $duplicates[0] );
	}

	if ( !$self->opt('no-passwords') ) {
		my $passwords = $self->passwords($accounts);
		if ( !defined($passwords) ) {
			push( @unknown, 'can not read the passwords, ' . ( $self->os eq 'freebsd' ? $MASTER_PASSWD : $SHADOW ) );
		} else {
			my @empty = sort( grep { $passwords->{$_} eq '' } keys( %{$passwords} ) );
			push( @problems, 'no password for ' . join( ', ', @empty ) ) if defined( $empty[0] );
		}
	}

	if ( $self->opt('system-shells') ) {
		my %shells  = map { $_ => 1 } $self->shells;
		my %ignored = map { $_ => 1 } ( 'root', 'sync', 'shutdown', 'halt', 'toor', @{ $self->opt('ignore') // [] } );
		my @can_log_in = map { $_->{name} }
			grep { $_->{uid} < $self->opt('min-uid') && !$ignored{ $_->{name} } && $shells{ $_->{shell} } }
			@{$accounts};
		push( @problems, 'system accounts with a login shell, ' . join( ', ', @can_log_in ) )
			if defined( $can_log_in[0] );
	}

	my @there = grep { $by_name{$_} } @{ $self->opt('absent') // [] };
	push( @problems, 'there but should not be, ' . join( ', ', @there ) ) if defined( $there[0] );
	my @missing = grep { !$by_name{$_} } @{ $self->opt('present') // [] };
	push( @problems, 'missing ' . join( ', ', @missing ) ) if defined( $missing[0] );

	my @codes = ( defined( $problems[0] ) ? $self->CRITICAL : $self->OK );
	push( @codes, $self->UNKNOWN ) if defined( $unknown[0] );
	my $message = scalar( @{$accounts} ) . ' accounts';
	$message = $message . ', ' . join( ', ', @problems, @unknown ) if defined( $problems[0] ) || defined( $unknown[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

=head2 accounts

Returns a array ref of the local accounts, as hash refs of name, uid,
password, the field as it is in the file, and shell, in the order they
are in the file. Dies if it can not be read.

=cut

sub accounts {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux' && $self->os ne 'freebsd';
	my $content = read_file( $PASSWD, err_mode => 'quiet' );
	die( 'can not read ' . $PASSWD . ', ' . $! . "\n" ) if !defined($content);

	my @accounts;
	foreach my $line ( split( /\n/, $content ) ) {
		next if $line =~ /\A\s*(?:#|\z)/ || $line =~ /\A[+-]/;
		my @fields = split( /:/, $line, -1 );
		next if scalar(@fields) < 7;
		push( @accounts, { name => $fields[0], uid => $fields[2], password => $fields[1], shell => $fields[6] } );
	}

	return \@accounts;
} ## end sub accounts

=head2 passwords

Returns a hash ref of account names to the password fields that are
used for them, or undef if the shadow file can not be read.

- accounts :: From L</accounts>, for the fields in passwd itself.

The field is the one from /etc/shadow, or /etc/master.passwd on
FreeBSD, unless the one in passwd is empty, as the C library and PAM
go by passwd then, and a empty one there means no password.

    my $passwords = $check->passwords( $check->accounts );

=cut

sub passwords {
	my ( $self, $accounts ) = @_;

	my $file    = $self->os eq 'freebsd' ? $MASTER_PASSWD : $SHADOW;
	my $content = read_file( $file, err_mode => 'quiet' ) // return undef;

	my %passwords = map { $_->{name} => $_->{password} } @{ $accounts // [] };
	foreach my $line ( split( /\n/, $content ) ) {
		next if $line =~ /\A\s*(?:#|\z)/ || $line =~ /\A[+-]/;
		my ( $name, $password ) = split( /:/, $line, -1 );
		next                                if !defined($name) || $name eq '';
		$passwords{$name} = $password // '' if ( $passwords{$name} // 'x' ) ne '';
	}

	return \%passwords;
} ## end sub passwords

=head2 shells

Returns the login shells in /etc/shells, read as getusershell does.
Each line gives one, the first thing on it starting with a /, and
lines with a # before that are comments. None if it can not be read.

=cut

sub shells {
	my ($self) = @_;

	my $content = read_file( $SHELLS, err_mode => 'quiet' ) // '';

	return map { m{\A[^#/]*(/[^\s#]*)} ? $1 : () } split( /\n/, $content );
}

1;
