package Monitoring::Sneck::Checks::cert_file;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Fcntl qw(S_IROTH);

=head1 NAME

Monitoring::Sneck::Checks::cert_file - checks certificate files

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    www_cert_file|perl:cert_file -f /usr/local/etc/ssl/www.pem -k /usr/local/etc/ssl/www.key -n www.example.org
    ca_files|perl:cert_file -f /usr/local/etc/ssl/ca.pem -f /usr/local/etc/ssl/intermediate.pem -w 90 -c 30

=head1 DESCRIPTION

Checks every certificate in each PEM file, so a chain file has its
intermediates checked too. A file that can not be read or has no
certificates is CRITICAL, as is a expired one or one not good yet. Then
it is WARNING or CRITICAL by the days left.

--key and --name are checked against the first certificate that
parses, in the order the files are given. A key that does not match is CRITICAL, as is one that is
encrypted, as there is no passphrase to give it. A key readable by
everyone is WARNING.

=head1 OPTIONS

- -f, --file :: A PEM file. May be given more than once. Required.

- -k, --key :: The PEM private key for the first certificate.

- -n, --name :: A name the first certificate must cover. May be given
more than once.

- -w, --warning :: Days left at or under which it is WARNING.
Default :: 30

- -c, --critical :: Days left at or under which it is CRITICAL.
Default :: 14

=cut

sub option_spec { return ( 'file|f=s@', 'key|k=s', 'name|n=s@', 'warning|w=i', 'critical|c=i' ) }

sub defaults { return { warning => 30, critical => 14 } }

sub required { return ('file') }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require IO::Socket::SSL;
	require IO::Socket::SSL::Utils;
	my @codes;
	my @problems;
	my @lines;
	my $first;
	my $first_message;
	my $fewest_days;

	foreach my $file ( @{ $self->opt('file') } ) {
		my $certs = eval { $self->pem_certs($file) };
		if ( !defined($certs) ) {
			my $why = $@;
			$why =~ s/\s+\z//;
			push( @codes,    $self->CRITICAL );
			push( @problems, $why );
			next;
		}
		if ( !scalar( @{$certs} ) ) {
			push( @codes,    $self->CRITICAL );
			push( @problems, 'no certificates in ' . $file );
			next;
		}

		my $number = 0;
		foreach my $cert ( @{$certs} ) {
			$number++;
			my $where = $file . ( scalar( @{$certs} ) > 1 ? ' #' . $number : '' );
			if ( !$cert ) {
				push( @codes,    $self->CRITICAL );
				push( @problems, $where . ' can not be parsed' );
				next;
			}
			my $details = $self->cert_details($cert);
			my ( $code, $message ) = $self->cert_status( $details, $self->opt('warning'), $self->opt('critical') );
			push( @codes, $code );
			push( @lines, $where . ' ' . $message );
			$fewest_days = $details->{days_left} if !defined($fewest_days) || $details->{days_left} < $fewest_days;
			if ( !defined($first) ) {
				$first         = $cert;
				$first_message = $where . ' ' . $message;
				next;
			}
			push( @problems, $where . ' ' . $message ) if $code != $self->OK;
			IO::Socket::SSL::Utils::CERT_free($cert);
		} ## end foreach my $cert ( @{$certs} )
	} ## end foreach my $file ( @{ $self->opt('file') } )

	if ( defined($first) ) {
		foreach my $name ( @{ $self->opt('name') // [] } ) {
			next if IO::Socket::SSL::verify_hostname_of_cert( $name, $first, 'http' );
			push( @codes,    $self->CRITICAL );
			push( @problems, 'does not cover ' . $name );
		}
		if ( defined( $self->opt('key') ) ) {
			my ( $code, $problem ) = $self->key_status( $first, $self->opt('key') );
			push( @codes,    $code );
			push( @problems, $problem ) if defined($problem);
		}
		IO::Socket::SSL::Utils::CERT_free($first);
	} ## end if ( defined($first) )

	if ( defined($fewest_days) ) {
		$self->perfdata(
			label    => 'days',
			value    => $fewest_days,
			warning  => $self->opt('warning'),
			critical => $self->opt('critical')
		);
	}
	my $message = join( ', ', grep { defined($_) } ( $first_message, @problems ) );
	@lines = () if scalar(@lines) < 2;

	return $self->finish( $self->worst(@codes), $message, @lines );
} ## end sub check

=head2 key_status

Checks a private key against a certificate.

- cert :: The Net::SSLeay X509.

- key :: The key file.

Returns the code and what is wrong, undef if nothing.

    my ( $code, $problem ) = $check->key_status( $cert, '/usr/local/etc/ssl/www.key' );

=cut

sub key_status {
	my ( $self, $cert, $key ) = @_;

	require Net::SSLeay;
	my @stat = stat($key);
	if ( !defined( $stat[0] ) || !-r $key ) {
		return ( $self->CRITICAL, 'can not read ' . $key . ', ' . ( $! || 'permission denied' ) );
	}

	# the key first, as loading a certificate that does not match a key already there drops the key
	my $context = Net::SSLeay::CTX_new();
	Net::SSLeay::CTX_set_default_passwd_cb( $context, sub { return '' } );
	my $loaded = Net::SSLeay::CTX_use_PrivateKey_file( $context, $key, Net::SSLeay::FILETYPE_PEM() );
	my $matches;
	if ($loaded) {
		Net::SSLeay::CTX_use_certificate( $context, $cert );
		$matches = Net::SSLeay::CTX_check_private_key($context);
	}
	Net::SSLeay::CTX_free($context);
	while ( Net::SSLeay::ERR_get_error() ) { }

	return ( $self->CRITICAL, $key . ' is not a key, or is encrypted' ) if !$loaded;
	return ( $self->CRITICAL, $key . ' does not match' )                if !$matches;
	return ( $self->WARNING,  $key . ' is readable by everyone' )       if $stat[2] & S_IROTH();

	return ( $self->OK, undef );
} ## end sub key_status

1;
