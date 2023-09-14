package OPCUA::Open62541::Test::CA;

use autodie;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use IO::Socket::SSL::Utils;
use IPC::Open3;
use Socket qw(AF_INET);
use Socket6 qw(AF_INET6 inet_pton);
use Test::More;

sub new {
    my ($class, %args) = @_;

    my $dir = delete($args{dir})
	|| tempdir('p5-opcua-open62541-ca-XXXXXXXX', CLEANUP => 1, TMPDIR => 1);
    $dir = abs_path($dir)
	or die 'no directory';

    my $config = delete($args{config})
	|| _default_openssl_config($dir);

    my $self = bless {
	config => $config,
	dir => $dir,
    }, $class;

    return $self;
}

sub setup {
    my ($self) = @_;
    my $dir = $self->{dir};

    for (
	["$dir/crlnumber",   "01\n"],
	["$dir/index.txt",   ''],
	["$dir/openssl.cnf", $self->{config}],
	["$dir/serial",      "01\n"],
    ) {
	open(my $fh, '>', $_->[0]);
	print $fh $_->[1];
    }
}

sub create_cert_ca {
    my ($self, %args) = @_;

    $self->create_cert(
	name => 'root',
	ca => 1,
	create_args => {
	    CA => 1,
	    purpose => 'sslCA,cRLSign',
	},
	%args,
    );
}

sub create_cert_client {
    my ($self, %args) = @_;
    my $appuri = delete($args{application_uri})
	// 'URI:urn:client.p5-opcua-open65241';

    $self->create_cert(
	name => 'client',
	create_args => {
	    ext => [{
		sn => 'subjectAltName',
		data => $appuri,
	    }],
	    purpose => 'digitalSignature,keyEncipherment,dataEncipherment,'
		. 'nonRepudiation,client'
		. ($args{issuer} ? '' : ',keyCertSign'),
	},
	%args,
    );
}

sub create_cert_server {
    my ($self, %args) = @_;
    my $host   = delete($args{host});
    my $appuri = delete($args{application_uri})
	// 'URI:urn:server.p5-opcua-open65241';
    my $subalt = '';

    if ($host) {
	if (inet_pton(AF_INET, $host) or inet_pton(AF_INET6, $host)) {
	    $subalt = "IP:$host,";
	} else {
	    $subalt = "DNS:$host,";
	}
    }

    $self->create_cert(
	name => 'server',
	create_args => {
	    ext => [{
		sn => 'subjectAltName',
		data => $subalt . $appuri,
	    }],
	    purpose => 'digitalSignature,keyEncipherment,dataEncipherment,'
		. 'nonRepudiation,server'
		. ($args{issuer} ? '' : ',keyCertSign'),
	},
	%args,
    );
}

sub create_cert {
    my ($self, %args) = @_;
    my $issuer      = delete($args{issuer});
    my $name        = delete($args{name}) || die 'no name for cert';
    my $subject     = delete($args{subject}) // {
	commonName => "OPCUA::Open62541 $name"
    };
    my $create_args = delete($args{create_args}) // {};
    my $is_ca       = delete($args{ca});
    my $dir         = $self->{dir};

    if ($issuer and not ref $issuer) {
	$issuer = [@{$self->{certs}{$issuer}}{qw(cert key)}];
    } elsif ($issuer and ref($issuer) eq 'HASH') {
	$issuer = [@$issuer{qw(cert key)}];
    }

    my ($cert, $key) = CERT_create(
	not_after => time() + 365*24*60*60,
	subject => $subject,
	$issuer ? (issuer => $issuer) : (),
	%$create_args,
    );

    my $path_cert = "$dir/$name.cert";
    my $path_crl = "$dir/$name.crl";
    my $path_key = "$dir/$name.key";

    PEM_cert2file($cert, $path_cert);
    PEM_key2file($key, $path_key);

    my $crl;
    if ($is_ca) {
	my $pid = open3(
	    undef, my $crlh, undef,
	    'openssl', 'ca', '-config', "$dir/openssl.cnf",
	    '-cert', $path_cert,
	    '-keyfile', $path_key,
	    '-gencrl'
	);
	$crl .= $_ while <$crlh>;
	waitpid($pid, 0);
	is($? >> 8, 0, 'openssl gencrl ok');

	open(my $fh, '>', $path_crl);
	print $fh $crl;
	close $fh;
    }

    $self->{certs}{$name} = {
	cert     => $cert,
	cert_pem => PEM_cert2string($cert),
	key      => $key,
	key_pem  => PEM_key2string($key),
	$is_ca ? (crl_pem => $crl) : (),
    };
}

sub revoke {
    my ($self, %args) = @_;
    my $name   = delete($args{name})   || die 'no name for revoke';
    my $issuer = delete($args{issuer}) || die 'no issuer for revoke';
    my $reason = delete($args{reason}) // 'unspecified';

    my $dir               = $self->{dir};
    my $path_issuer_cert  = "$dir/$issuer.cert";
    my $path_issuer_crl   = "$dir/$issuer.crl";
    my $path_issuer_key   = "$dir/$issuer.key";
    my $path_revoked_cert = "$dir/$name.cert";

    my $pid = open3(
	undef, undef, undef,
	'openssl', 'ca', '-config', "$dir/openssl.cnf",
	'-cert', $path_issuer_cert,
	'-keyfile', $path_issuer_key,
	'-revoke', $path_revoked_cert, '-crl_reason', $reason
    );
    waitpid($pid, 0);
    is($? >> 8, 0, 'openssl revoke ok');

    $pid = open3(
	undef, my $crlh, undef,
	'openssl', 'ca', '-config', "$dir/openssl.cnf",
	'-cert', $path_issuer_cert,
	'-keyfile', $path_issuer_key,
	'-gencrl'
    );
    my $crl;
    $crl .= $_ while <$crlh>;
    waitpid($pid, 0);
    is($? >> 8, 0, 'openssl gencrl ok');

    open(my $fh, '>', $path_issuer_crl);
    print $fh $crl;
    close $fh;

    $self->{certs}{$issuer}{crl_pem} = $crl;
}

sub _default_openssl_config {
    my $dir = shift;
    my $config = << 'CONF';
[ ca ]
default_ca  = CA_default

[ CA_default ]
dir         = %DIR%
database    = $dir/index.txt
serial      = $dir/serial
crlnumber   = $dir/crlnumber

default_days     = 365
default_crl_days = 30
default_md  = sha256
CONF

    $config =~ s/%DIR%/$dir/g;

    return $config;
}

1;

__END__

=pod

=head1 NAME

OPCUA::Open62541::Test::CA - generate x509 certificates testing

=head1 SYNOPSIS

  use OPCUA::Open62541::Test::CA;

  my $ca = OPCUA::Open62541::Test::CA->new(%args);

=head1 DESCRIPTION

For module testing create keys and certificates needed for OPC UA
encryption.

=head2 METHODS

=over 4

=item $ca = OPCUA::Open62541::Test::CA->new(%args);

Create a new test CA instance.

=item $ca->setup()

Write OpenSSL config files.

=item $ca->create_cert_ca(%args)

Create CA certificate.

=item $ca->create_cert_client(%args)

Create client certificate.
The parameter I<application_uri> can be used to change the URI entry in
SubjectAltName.

=item $ca->create_cert_server(%args)

Create server certificate.
The parameter I<application_uri> can be used to change the URI entry in
SubjectAltName.
The parameter I<host> can be used to automatically create an entry in
SubjectAltName.
It will be an IP or a DNS entry depending on the given value.

=item $ca->create_cert(%args)

Use IO::Socket::SSL::Utils and run openssl command line tool to
create all kind of private keys, certificates and CRLs.

=item $ca->revoke(%args)

Fill certificate revocation list and regenerate CRL.

=back

=head1 SEE ALSO

OPCUA::Open62541, OPCUA::Open62541::Test::Client,
OPCUA::Open62541::Test::Server

=head1 AUTHORS

Anton Borowka

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Anton Borowka

This is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system
itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
