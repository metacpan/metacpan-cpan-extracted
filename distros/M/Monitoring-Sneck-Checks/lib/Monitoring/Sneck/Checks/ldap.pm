package Monitoring::Sneck::Checks::ldap;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks::ldap - checks a LDAP server binds and searches, timing it

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Result codes that are not failures for a search. 4 is the size limit
# being hit, which still returns entries.
our %SEARCH_FINE = ( 0 => 1, 4 => 1 );

=head1 SYNOPSIS

    ldap|perl:ldap -H ldap.example.org
    ldap_tls|perl:ldap -H ldap.example.org -s -w 0.5 -c 2
    ldaps|perl:ldap -H ldap.example.org -S
    ldap_users|perl:ldap -H ldap.example.org -s -D cn=monitor,dc=example,dc=org -P /etc/sneck/ldap.pw -b ou=people,dc=example,dc=org --scope one -f '(uid=*)' -E 10:

=head1 DESCRIPTION

Connects, binds, searches, and unbinds, through L<Net::LDAP>, timing
it all. Net::LDAP is not required to install this, but this check
needs it.

The bind is anonymous unless --bind-dn is given. Without --base, it
reads the root DSE, the empty base with a base scope, which most
servers answer anonymously.

- CRITICAL :: Not connecting. StartTLS failing. The bind or search
failing. The entries found outside of --entries. The time over
--critical.

- WARNING :: The time over --warning.

- UNKNOWN :: Net::LDAP not being installed, or --password-file not
being readable.

With --starttls, StartTLS is done before binding. With --ssl, it
connects over TLS from the start, as for port 636. The certificate is
checked unless --insecure is given. See
L<Monitoring::Sneck::Checks::https_cert> with --starttls ldap for when
it expires.

A search hitting the server's size limit is not a failure, as it still
returns entries.

=head1 OPTIONS

- -H, --hostname :: The host. Required.

- -p, --port :: The port.
Default :: 389, or 636 with --ssl

- -S, --ssl :: Connect over TLS. Can not be used with --starttls.

- -s, --starttls :: Do StartTLS before binding. Can not be used with
--ssl.

- -D, --bind-dn :: The DN to bind as.

- --password :: The password to bind with. --password-file is better,
as this can show up in ps when run through sneck_check.

- -P, --password-file :: A file with the password, its first line
being it.

- -b, --base :: The base to search.
Default :: the empty base, the root DSE

- --scope :: base, one, or sub.
Default :: base

- -f, --filter :: The filter to search with.
Default :: (objectClass=*)

- -E, --entries :: Range for how many entries the search finds.
Default :: 1:

- -w, --warning :: Range of seconds for the whole of it.

- -c, --critical :: Range of seconds for the whole of it.

- --insecure :: Do not check the certificate.

- --ca-file :: The CA file to check the certificate against.

=cut

sub option_spec {
	return (
		'hostname|H=s', 'port|p=i',          'ssl|S',        'starttls|s', 'bind-dn|D=s',
		'password=s',   'password-file|P=s', 'base|b=s',     'scope=s',    'filter|f=s',
		'entries|E=s',  'warning|w=s',       'critical|c=s', 'insecure',   'ca-file=s',
	);
}

sub defaults { return { base => '', scope => 'base', filter => '(objectClass=*)', entries => '1:' } }

sub required { return ('hostname') }

sub ranges { return ( 'entries', 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--hostname "' . $options->{hostname} . '" is not a IP or hostname' )
		if defined( $options->{hostname} ) && !$self->is_host( $options->{hostname} );
	push( @problems, '--ssl and --starttls can not both be given' ) if $options->{ssl} && $options->{starttls};
	push( @problems, '--password and --password-file can not both be given' )
		if defined( $options->{password} ) && defined( $options->{'password-file'} );
	push( @problems, '--password or --password-file needs --bind-dn' )
		if ( defined( $options->{password} ) || defined( $options->{'password-file'} ) )
		&& !defined( $options->{'bind-dn'} );
	push( @problems, '--scope must be base, one, or sub' ) if $options->{scope} !~ /\A(?:base|one|sub)\z/;

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	return $self->finish( $self->UNKNOWN, 'Net::LDAP is not installed' ) if !eval { require Net::LDAP; 1 };

	my $password = $self->opt('password');
	if ( defined( $self->opt('password-file') ) ) {
		my $content = read_file( $self->opt('password-file'), err_mode => 'quiet' );
		return $self->finish( $self->UNKNOWN, 'can not read ' . $self->opt('password-file') . ', ' . $! )
			if !defined($content);
		($password) = split( /\r?\n/, $content );
		$password //= '';
	}

	my $host  = $self->opt('hostname');
	my $port  = $self->opt('port') // ( $self->opt('ssl') ? 636 : 389 );
	my $where = $host . ':' . $port;
	my %tls   = ( verify => $self->opt('insecure') ? 'none' : 'require' );
	$tls{cafile} = $self->opt('ca-file') if defined( $self->opt('ca-file') );

	my $start = Time::HiRes::time;
	my $ldap  = Net::LDAP->new(
		$host,
		port    => $port,
		scheme  => $self->opt('ssl') ? 'ldaps' : 'ldap',
		timeout => $self->timeout,
		version => 3,
		( $self->opt('ssl') ? %tls : () ),
	);
	return $self->finish( $self->CRITICAL, $where . ', ' . ( $@ || 'can not connect' ) ) if !$ldap;

	# each step returns a Net::LDAP::Message, its code 0 being success
	my $failed = sub {
		my ( $step, $message ) = @_;
		$ldap->disconnect;
		return $self->finish( $self->CRITICAL,
			$where . ' ' . $step . ' failed, ' . $message->code . ' ' . ( $message->error // '' ) );
	};
	if ( $self->opt('starttls') ) {
		my $tls_message = $ldap->start_tls(%tls);
		return $failed->( 'StartTLS', $tls_message ) if $tls_message->code;
	}

	my $bind_message
		= defined( $self->opt('bind-dn') )
		? $ldap->bind( $self->opt('bind-dn'), password => $password // '' )
		: $ldap->bind;
	return $failed->( 'bind', $bind_message ) if $bind_message->code;

	# 1.1 asks for no attributes, as only the count is wanted
	my $search = $ldap->search(
		base   => $self->opt('base'),
		scope  => $self->opt('scope'),
		filter => $self->opt('filter'),
		attrs  => ['1.1'],
	);
	return $failed->( 'search', $search ) if !$SEARCH_FINE{ $search->code };
	my $entries = $search->count;
	$ldap->unbind;
	$ldap->disconnect;
	my $seconds = sprintf( '%.3f', Time::HiRes::time - $start );

	my $entries_code = $self->in_alert( $entries, $self->opt('entries') ) ? $self->CRITICAL : $self->OK;
	my $time_code    = $self->threshold_status( $seconds, $self->opt('warning'), $self->opt('critical') );
	$self->perfdata(
		label    => 'time',
		value    => $seconds,
		uom      => 's',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0,
	);
	$self->perfdata( label => 'entries', value => $entries, critical => $self->opt('entries'), min => 0 );

	my @parts = (
		$where,
		'bound ' . ( defined( $self->opt('bind-dn') ) ? 'as ' . $self->opt('bind-dn') : 'anonymously' ),
		$entries . ' entr'
			. ( $entries == 1 ? 'y' : 'ies' )
			. ' found'
			. ( $search->code == 4 ? ', size limit hit' : '' ),
		$seconds . ' seconds',
	);
	push( @parts, 'wanted ' . $self->opt('entries') . ' entries' ) if $entries_code != $self->OK;

	return $self->finish( $self->worst( $entries_code, $time_code ), join( ', ', @parts ) );
} ## end sub check

1;
