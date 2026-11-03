package Monitoring::Sneck::Checks::pkg_audit;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::pkg_audit - checks FreeBSD packages for known vulnerabilities

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where pkg is. Set by tests.
our $PKG = '/usr/sbin/pkg';

=head1 SYNOPSIS

    !pkg_audit|interval=3600|perl:pkg_audit
    !pkg_audit_www|interval=3600|perl:pkg_audit -j www
    !pkg_audit_fetch|interval=86400 timeout=300|perl:pkg_audit -F -w 0 -c 5

=head1 DESCRIPTION

Runs pkg audit and counts the installed packages it says are
vulnerable. By default any is CRITICAL.

pkg audit goes by the vulnerability database it has, which the daily
periodic security run fetches. A database older than --max-age days is
WARNING, as it may be missing what was found since, the same as
periodic warns. With --fetch, pkg fetches it first, which needs the
network and should not be done every few minutes, so use a compliance
check with a interval, as in the synopsis.

pkg failing, or not being there, is UNKNOWN.

=head1 OPTIONS

- -j, --jail :: Audit the packages in this jail, through pkg -j. The
age of the database is not checked unless --db is given.

- -F, --fetch :: Fetch the vulnerability database first.

- -d, --db :: The vulnerability database.
Default :: /var/db/pkg/vuln.xml

- -a, --max-age :: Days old the database may be. 0 to not check it.
Default :: 2

- -w, --warning :: Range for the number of vulnerable packages.

- -c, --critical :: Range for the number of vulnerable packages.
Default :: 0

=cut

sub option_spec { return ( 'jail|j=s', 'fetch|F', 'db|d=s', 'max-age|a=i', 'warning|w=s', 'critical|c=s' ) }

sub defaults { return { 'max-age' => 2, critical => '0' } }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	return ( '--jail "' . $options->{jail} . '" is not a jail name or ID' )
		if defined( $options->{jail} ) && $options->{jail} !~ /\A[A-Za-z0-9_.-]+\z/;

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @command = ($PKG);
	push( @command, '-j', $self->opt('jail') ) if defined( $self->opt('jail') );
	push( @command, 'audit' );
	push( @command, '-F' ) if $self->opt('fetch');
	my ( $exit, $output ) = $self->run_command(@command);

	# 0 is nothing vulnerable and 1 is something is
	if ( $exit > 1 ) {
		my $first = ( grep { /\S/ } split( /\n/, $output ) )[0] // '';
		return $self->finish( $self->UNKNOWN, 'pkg audit exited ' . $exit . ', "' . $first . '"' );
	}

	# "name-1.2 is vulnerable:", then the problem, CVEs, and a link, each indented
	my @vulnerable;
	my %problems;
	my $current;
	foreach my $line ( split( /\n/, $output ) ) {
		if ( $line =~ /\A(\S+) is vulnerable:\s*\z/ ) {
			$current = $1;
			push( @vulnerable, $current );
			$problems{$current} = [];
			next;
		}
		next if !defined($current) || $line !~ /\A\s+(\S.*?)\s*\z/;
		my $text = $1;
		next if $text =~ /\A(?:CVE|WWW):/;
		push( @{ $problems{$current} }, $text );
	} ## end foreach my $line ( split( /\n/, $output ) )
	# such as the database not being there
	if ( $exit == 1 && !defined( $vulnerable[0] ) ) {
		my $first = ( grep { /\S/ } split( /\n/, $output ) )[0] // '';
		return $self->finish( $self->UNKNOWN,
			'pkg audit exited 1 without saying what is vulnerable, "' . $first . '"' );
	}

	my $count = scalar(@vulnerable);
	my @codes = ( $self->threshold_status( $count, $self->opt('warning'), $self->opt('critical') ) );
	my @notes;
	my $age = $self->db_age;
	if ( defined($age) && $self->opt('max-age') && $age > $self->opt('max-age') ) {
		push( @codes, $self->WARNING );
		push( @notes, 'the vulnerability database is ' . sprintf( '%.0f', $age ) . ' days old' );
	}
	$self->perfdata(
		label    => 'vulnerable',
		value    => $count,
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);

	my $message = $count . ' vulnerable package' . ( $count == 1 ? '' : 's' );
	$message = $message . ' in jail ' . $self->opt('jail') if defined( $self->opt('jail') );
	$message = $message . ', ' . join( ', ', @vulnerable ) if defined( $vulnerable[0] );
	$message = $message . ', ' . join( ', ', @notes )      if defined( $notes[0] );
	my @details = map { $_ . ': ' . join( '; ', @{ $problems{$_} } ) } grep { defined( $problems{$_}[0] ) } @vulnerable;

	return $self->finish( $self->worst(@codes), $message, @details );
} ## end sub check

=head2 db_age

Returns the days since the vulnerability database was changed, or
undef if it is not checked, as for a jail without --db, or not there.

=cut

sub db_age {
	my ($self) = @_;

	return undef if defined( $self->opt('jail') ) && !defined( $self->opt('db') );
	my @stat = stat( $self->opt('db') // '/var/db/pkg/vuln.xml' );
	return undef if !defined( $stat[0] );

	return ( time - $stat[9] ) / 86400;
}

1;
