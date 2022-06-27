package Net::SSL::ExpireDate;

use strict;
use warnings;
use Carp;

our $VERSION = '1.24';

use base qw(Class::Accessor);
use Crypt::OpenSSL::X509 qw(FORMAT_ASN1);
use Date::Parse;
use DateTime;
use DateTime::Duration;
use Time::Duration::Parse;
use UNIVERSAL::require;

my $Socket = 'IO::Socket::INET6';
unless ($Socket->require) {
    $Socket = 'IO::Socket::INET';
    $Socket->require or die $@;
}

__PACKAGE__->mk_accessors(qw(type target));

my $SSL3_RT_CHANGE_CIPHER_SPEC = 20;
my $SSL3_RT_ALERT              = 21;
my $SSL3_RT_HANDSHAKE          = 22;
my $SSL3_RT_APPLICATION_DATA   = 23;

my $SSL3_MT_HELLO_REQUEST       =  0;
my $SSL3_MT_CLIENT_HELLO        =  1;
my $SSL3_MT_SERVER_HELLO        =  2;
my $SSL3_MT_CERTIFICATE         = 11;
my $SSL3_MT_SERVER_KEY_EXCHANGE = 12;
my $SSL3_MT_CERTIFICATE_REQUEST = 13;
my $SSL3_MT_SERVER_DONE         = 14;
my $SSL3_MT_CERTIFICATE_VERIFY  = 15;
my $SSL3_MT_CLIENT_KEY_EXCHANGE = 16;
my $SSL3_MT_FINISHED            = 20;

my $SSL3_AL_WARNING = 0x01;
my $SSL3_AL_FATAL   = 0x02;

my $SSL3_AD_CLOSE_NOTIFY            =  0;
my $SSL3_AD_UNEXPECTED_MESSAGE      = 10; # fatal
my $SSL3_AD_BAD_RECORD_MAC          = 20; # fatal
my $SSL3_AD_DECOMPRESSION_FAILURE   = 30; # fatal
my $SSL3_AD_HANDSHAKE_FAILURE       = 40; # fatal
my $SSL3_AD_NO_CERTIFICATE          = 41;
my $SSL3_AD_BAD_CERTIFICATE         = 42;
my $SSL3_AD_UNSUPPORTED_CERTIFICATE = 43;
my $SSL3_AD_CERTIFICATE_REVOKED     = 44;
my $SSL3_AD_CERTIFICATE_EXPIRED     = 45;
my $SSL3_AD_CERTIFICATE_UNKNOWN     = 46;
my $SSL3_AD_ILLEGAL_PARAMETER       = 47; # fatal

sub new {
    my ($class, %opt) = @_;

    my $self = bless {
        type        => undef,
        target      => undef,
        expire_date => undef,
        timeout     => undef,
       }, $class;

    if ( $opt{https} or $opt{ssl} ) {
        $self->{type}   = 'ssl';
        $self->{target} = $opt{https} || $opt{ssl};
    } elsif ($opt{file}) {
        $self->{type}   = 'file';
        $self->{target} = $opt{file};
        if (! -r $self->{target}) {
            croak "$self->{target}: $!";
        }
    } else {
        croak "missing option: neither ssl nor file";
    }
    if ($opt{timeout}) {
        $self->{timeout} = $opt{timeout};
    }
    if ($opt{sni}) {
        $self->{sni} = $opt{sni};
    }

    return $self;
}

sub expire_date {
    my $self = shift;

    if (! $self->{expire_date}) {
        if ($self->{type} eq 'ssl') {
            my ($host, $port) = split /:/, $self->{target}, 2;
            $port ||= 443;
            ### $host
            ### $port
            my $cert = eval { _peer_certificate($host, $port, $self->{timeout}, $self->{sni}); };
            warn $@ if $@;
            return unless $cert;
            my $x509 = Crypt::OpenSSL::X509->new_from_string($cert, FORMAT_ASN1);
            my $begin_date_str  = $x509->notBefore;
            my $expire_date_str = $x509->notAfter;

            $self->{expire_date} = DateTime->from_epoch(epoch => str2time($expire_date_str));
            $self->{begin_date}  = DateTime->from_epoch(epoch => str2time($begin_date_str));

        } elsif ($self->{type} eq 'file') {
            my $x509 = Crypt::OpenSSL::X509->new_from_file($self->{target});
            $self->{expire_date} = DateTime->from_epoch(epoch => str2time($x509->notAfter));
            $self->{begin_date}  = DateTime->from_epoch(epoch => str2time($x509->notBefore));
        } else {
            croak "unknown type: $self->{type}";
        }
    }

    return $self->{expire_date};
}

sub begin_date {
    my $self = shift;

    if (! $self->{begin_date}) {
        $self->expire_date;
    }

    return $self->{begin_date};
}

*not_after  = \&expire_date;
*not_before = \&begin_date;

sub is_expired {
    my ($self, $duration) = @_;
    $duration ||= DateTime::Duration->new();

    if (! $self->{begin_date}) {
        $self->expire_date;
    }

    if (! ref($duration)) { # if scalar
        $duration = DateTime::Duration->new(seconds => parse_duration($duration));
    }

    my $dx = DateTime->now()->add_duration( $duration );
    ### dx: $dx->iso8601

    return DateTime->compare($dx, $self->{expire_date}) >= 0 ? 1 : ();
}

sub _peer_certificate {
    my($host, $port, $timeout, $sni) = @_;

    my $cert;

    no warnings 'once';
    no strict 'refs'; ## no critic
    *{$Socket.'::write_atomically'} = sub {
        my($self, $data) = @_;

        my $length    = length $data;
        my $offset    = 0;
        my $read_byte = 0;

        while ($length > 0) {
            my $r = $self->syswrite($data, $length, $offset) || last;
            $offset    += $r;
            $length    -= $r;
            $read_byte += $r;
        }

        return $read_byte;
    };

    my $sock = {
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => $timeout,
    };

    $sock = $Socket->new( %$sock ) or croak "cannot create socket: $!";

    my $servername;
    if ($sni) {
      $servername = $sni;
    } elsif ($host !~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/) {
        $servername = $host;
    }
    _send_client_hello($sock, $servername);

    my $do_loop = 1;
    while ($do_loop) {
        my $record = _get_record($sock);
        if ($record->{type} != $SSL3_RT_HANDSHAKE) {
            if ($record->{type} == $SSL3_RT_ALERT) {
                my $d1 = unpack 'C', substr $record->{data}, 0, 1;
                my $d2 = unpack 'C', substr $record->{data}, 1, 1;
                if ($d1 eq $SSL3_AL_WARNING) {
                    ; # go ahead
                } else {
                    croak "record type is SSL3_AL_FATAL. [desctioption: $d2]";
                }
            } else {
                croak "record type is not HANDSHAKE";
            }
        }

        while (my $handshake = _get_handshake($record)) {
            croak "too many loop" if $do_loop++ >= 10;
            if ($handshake->{type} == $SSL3_MT_HELLO_REQUEST) {
                ;
            } elsif ($handshake->{type} == $SSL3_MT_CERTIFICATE_REQUEST) {
                ;
            } elsif ($handshake->{type} == $SSL3_MT_SERVER_HELLO) {
                ;
            } elsif ($handshake->{type} == $SSL3_MT_CERTIFICATE) {
                my $data = $handshake->{data};
                my $len1 = $handshake->{length};
                my $len2 = (vec($data, 0, 8)<<16)+(vec($data, 1, 8)<<8)+vec($data, 2, 8);
                my $len3 = (vec($data, 3, 8)<<16)+(vec($data, 4, 8)<<8)+vec($data, 5, 8);
                croak "X509: length error" if $len1 != $len2 + 3;
                $cert = substr $data, 6; # DER format
            } elsif ($handshake->{type} == $SSL3_MT_SERVER_KEY_EXCHANGE) {
                ;
            } elsif ($handshake->{type} == $SSL3_MT_SERVER_DONE) {
                $do_loop = 0;
            } else {
                ;
            }
        }

    }

    _sendalert($sock, $SSL3_AL_FATAL, $SSL3_AD_HANDSHAKE_FAILURE) or croak $!;
    $sock->close;

    return $cert;
}

sub _send_client_hello {
    my($sock, $servername) = @_;

    my(@buf, $len);
    # Record Layer
    # Content Type: Handshake
    push @buf, $SSL3_RT_HANDSHAKE;
    # Version: TLS 1.0 (SSL 3.1)
    push @buf, 3, 1;
    # Length: set later
    push @buf, undef, undef;
    my $pos_record_len = $#buf-1;

    ## Handshake Protocol: Client Hello
    push @buf, $SSL3_MT_CLIENT_HELLO;
    ## Length: set later
    push @buf, undef, undef, undef;
    my $pos_handshake_len = $#buf-2;
    ## Version: TLS 1.2
    push @buf, 3, 3; # TLS 1.2
    ## Random
    my $time = time;
    push @buf, (($time>>24) & 0xFF);
    push @buf, (($time>>16) & 0xFF);
    push @buf, (($time>> 8) & 0xFF);
    push @buf, (($time    ) & 0xFF);
    for (1..28) {
        push @buf, int(rand(0xFF));
    }
    ## Session ID Length: 0
    push @buf, 0;

    # https://wiki.mozilla.org/Security/Server_Side_TLS#Intermediate_compatibility_.28recommended.29
    my @cipher_suites = (
        0xc02c, # TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
        0xc030, # TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        0x009f, # TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
        0xcca9, # TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
        0xcca8, # TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
        0xccaa, # TLS_DHE_RSA_WITH_CHACHA20_POLY1305_SHA256
        0xc02b, # TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
        0xc02f, # TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        0x009e, # TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
        0xc024, # TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
        0xc028, # TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
        0x006b, # TLS_DHE_RSA_WITH_AES_256_CBC_SHA256
        0xc023, # TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
        0xc027, # TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
        0x0067, # TLS_DHE_RSA_WITH_AES_128_CBC_SHA256
        0xc00a, # TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
        0xc014, # TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
        0x0039, # TLS_DHE_RSA_WITH_AES_256_CBC_SHA
        0xc009, # TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
        0xc013, # TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
        0x0033, # TLS_DHE_RSA_WITH_AES_128_CBC_SHA
        0x009d, # TLS_RSA_WITH_AES_256_GCM_SHA384
        0x009c, # TLS_RSA_WITH_AES_128_GCM_SHA256
        0x003d, # TLS_RSA_WITH_AES_256_CBC_SHA256
        0x003c, # TLS_RSA_WITH_AES_128_CBC_SHA256
        0x0035, # TLS_RSA_WITH_AES_256_CBC_SHA
        0x002f, # TLS_RSA_WITH_AES_128_CBC_SHA
        0x00ff, # TLS_EMPTY_RENEGOTIATION_INFO_SCSV
    );
    $len = scalar(@cipher_suites) * 2;
    ## Cipher Suites Length
    push @buf, (($len >> 8) & 0xFF);
    push @buf, (($len     ) & 0xFF);
    ## Cipher Suites
    for my $i (@cipher_suites) {
        push @buf, (($i >> 8) & 0xFF);
        push @buf, (($i     ) & 0xFF);
    }

    ## Compression Methods Length
    push @buf, 1;
    ## Compression Methods: null
    push @buf, 0;

    ## Extensions Length: set later
    my @ext = (undef, undef);

    ## Extension: server_name
    if ($servername) {
        # SNI (Server Name Indication)
        my $sn_len = length $servername;
        ### Type: Server Name
        push @ext, 0, 0;
        ### Length
        # 5 is this part(2) + Server Name Indication Length(3)
        push @ext, ((($sn_len+5) >> 8) & 0xFF);
        push @ext, ((($sn_len+5)     ) & 0xFF);
        ### Server Name Indication extension
        #### Server Name list length
        # 3 is this part(2) + Server Name Type(1)
        push @ext, ((($sn_len+3) >> 8) & 0xFF);
        push @ext, ((($sn_len+3)     ) & 0xFF);
        #### Server Name Type: host_name
        push @ext, 0;
        #### Server Name length
        push @ext, (($sn_len >> 8) & 0xFF);
        push @ext, (($sn_len     ) & 0xFF);
        #### Server Name
        for my $c (split //, $servername) {
            push @ext, ord($c);
        }
    }

    ## Extension: supported_groups
    ### Type: supported_groups
    push @ext, 0x00, 0x0a;

    my @supported_groups = (
        0x0017, # secp256r1
        0x0018, # secp384r1
        0x0019, # secp521r1
        0x001d, # x25519
        0x001e, # x448
    );

    ### Length
    # Supported Group List Length(2) + Supported Groups
    $len = 2 + scalar(@supported_groups) * 2;
    push @ext, (($len >> 8) & 0xFF);
    push @ext, (($len     ) & 0xFF);

    ### Supported Group List Length
    $len = scalar(@supported_groups) * 2;
    push @ext, (($len >> 8) & 0xFF);
    push @ext, (($len     ) & 0xFF);

    ### Supported Groups
    for my $i (@supported_groups) {
        push @ext, (($i >> 8) & 0xFF);
        push @ext, (($i     ) & 0xFF);
    }

    ## Extension: signature_algorithms (>= TLSv1.2)
    ### Type: signature_algorithms
    push @ext, 0x00, 0x0D;

    # https://datatracker.ietf.org/doc/html/rfc5246#section-7.4.1.4.1
    # enum {
    #     none(0), md5(1), sha1(2), sha224(3), sha256(4), sha384(5),
    #     sha512(6), (255)
    # } HashAlgorithm;
    # enum { anonymous(0), rsa(1), dsa(2), ecdsa(3), (255)
    # } SignatureAlgorithm;
    my @signature_algorithms = (
        0x0403, # ecdsa_secp256r1_sha256
        0x0503, # ecdsa_secp384r1_sha384
        0x0603, # ecdsa_secp521r1_sha512
        0x0807, # ed25519
        0x0808, # ed448
        0x0809, # rsa_pss_pss_sha256
        0x080a, # rsa_pss_pss_sha384
        0x080b, # rsa_pss_pss_sha512
        0x0804, # rsa_pss_rsae_sha256
        0x0805, # rsa_pss_rsae_sha384
        0x0806, # rsa_pss_rsae_sha512
        0x0401, # rsa_pkcs1_sha256
        0x0501, # rsa_pkcs1_sha384
        0x0601, # rsa_pkcs1_sha512
        0x0303, # SHA224 ECDSA
        0x0203, # ecdsa_sha1
        0x0301, # SHA224 RSA
        0x0201, # rsa_pkcs1_sha1
        0x0302, # SHA224 DSA
        0x0202, # SHA1 DSA
        0x0402, # SHA256 DSA
        0x0502, # SHA384 DSA
        0x0602, # SHA512 DSA
    );

    ### Length
    # Signature Hash Algorithms Length(2) + Signature hash Algorithms
    $len = 2 + scalar(@signature_algorithms) * 2;
    push @ext, (($len >> 8) & 0xFF);
    push @ext, (($len     ) & 0xFF);

    ### Signature Hash Algorithms Length
    $len = scalar(@signature_algorithms) * 2;
    push @ext, (($len >> 8) & 0xFF);
    push @ext, (($len     ) & 0xFF);

    ### Signature Hash Algorithms
    for my $i (@signature_algorithms) {
        push @ext, (($i >> 8) & 0xFF);
        push @ext, (($i     ) & 0xFF);
    }

    ## Extension: ec_point_formats
    ### Type: ec_point_formats
    push @ext, 0x00, 0x0b;
    ### Length: 4
    push @ext, 0x00, 0x04;
    ### EC point formats Length: 3
    push @ext, 0x03;
    ### Elliptic curves point formats
    push @ext, 0x00; # uncompressed
    push @ext, 0x01; # ansiX962_compressed_prime
    push @ext, 0x02; # ansiX962_compressed_char2 (2)

    ## Extension: Heartbeat
    push @ext,
        0x00, 0x0F, # Type: heartbeat
        0x00, 0x01, # Lengh
        0x01,       # Peer allowed to send requests
        ;

    ## Extensions Length
    my $ext_len = scalar(@ext) - 2;
    if ($ext_len > 0) {
        $ext[0] = (($ext_len) >> 8) & 0xFF;
        $ext[1] = (($ext_len)     ) & 0xFF;
        push @buf, @ext;
    }

    # Record Length
    $len = scalar(@buf) - $pos_record_len - 2;
    $buf[ $pos_record_len   ] = (($len >>  8) & 0xFF);
    $buf[ $pos_record_len+1 ] = (($len      ) & 0xFF);

    ## Handshake Length
    $len = scalar(@buf) - $pos_handshake_len - 3;
    $buf[ $pos_handshake_len   ] = (($len >> 16) & 0xFF);
    $buf[ $pos_handshake_len+1 ] = (($len >>  8) & 0xFF);
    $buf[ $pos_handshake_len+2 ] = (($len      ) & 0xFF);

    my $data = '';
    for my $c (@buf) {
        $data .= pack('C', $c);
    }

    return $sock->write_atomically($data);
}

sub _get_record {
    my($sock) = @_;

    my $record = {
        type    => -1,
        version => -1,
        length  => -1,
        read    =>  0,
        data    => "",
    };

    $sock->read($record->{type}   , 1) or croak "cannot read type";
    $record->{type} = unpack 'C', $record->{type};

    $sock->read($record->{version}, 2) or croak "cannot read version";
    $record->{version} = unpack 'n', $record->{version};

    $sock->read($record->{length},  2) or croak "cannot read length";
    $record->{length}  = unpack 'n', $record->{length};

    $sock->read($record->{data},    $record->{length}) or croak "cannot read data";

    return $record;
}

sub _get_handshake {
    my($record) = @_;

    my $handshake = {
        type   => -1,
        length => -1,
        data   => "",
       };

    return if $record->{read} >= $record->{length};

    $handshake->{type}   = vec($record->{data}, $record->{read}++, 8);
    return if $record->{read} + 3 > $record->{length};

    $handshake->{length} =
         (vec($record->{data}, $record->{read}++, 8)<<16)
        +(vec($record->{data}, $record->{read}++, 8)<< 8)
        +(vec($record->{data}, $record->{read}++, 8)    );

    if ($handshake->{length} > 0) {
        $handshake->{data} = substr($record->{data}, $record->{read}, $handshake->{length});
        $record->{read} += $handshake->{length};
        return if $record->{read} > $record->{length};
    } else {
        $handshake->{data}= undef;
    }

    return $handshake;
}

sub _sendalert {
    my($sock, $level, $desc) = @_;

    my(@buf, $len);
    # Record Layer
    # Content Type: Alert
    push @buf, $SSL3_RT_ALERT;
    # Version: TLS 1.0 (SSL 3.1)
    push @buf, 3, 1;
    # Length:
    push @buf, 0x00, 0x02;
    # Alert Message
    ## Level: Fatal (2)
    push @buf, $level;
    ## Description: Handshake Failure (40)
    push @buf, $desc;

    my $data = '';
    for my $c (@buf) {
        $data .= pack('C', $c);
    }

    return $sock->write_atomically($data);
}

1; # Magic true value required at end of module

__END__

=head1 NAME

Net::SSL::ExpireDate - obtain expiration date of certificate

=head1 SYNOPSIS

    use Net::SSL::ExpireDate;

    $ed = Net::SSL::ExpireDate->new( https => 'example.com' );
    $ed = Net::SSL::ExpireDate->new( https => 'example.com:10443' );
    $ed = Net::SSL::ExpireDate->new( ssl   => 'example.com:465' ); # smtps
    $ed = Net::SSL::ExpireDate->new( ssl   => 'example.com:995' ); # pop3s
    $ed = Net::SSL::ExpireDate->new( file  => '/etc/ssl/cert.pem' );

    if (defined $ed->expire_date) {
      # do something
      $expire_date = $ed->expire_date;         # return DateTime instance

      $expired = $ed->is_expired;              # examine already expired

      $expired = $ed->is_expired('2 months');  # will expire after 2 months
      $expired = $ed->is_expired(DateTime::Duration->new(months=>2));  # ditto
    }

=head1 DESCRIPTION

Net::SSL::ExpireDate get certificate from network (SSL) or local
file and obtain its expiration date.

=head1 METHODS

=head2 new

  $ed = Net::SSL::ExpireDate->new( %option )

This method constructs a new "Net::SSL::ExpireDate" instance and
returns it. %option is to specify certificate.

  KEY    VALUE
  ----------------------------
  ssl     "hostname[:port]"
  https   (same as above ssl)
  file    "path/to/certificate"
  timeout "Timeout in seconds"
  sni     "Server Name Indicator"

=head2 expire_date

  $expire_date = $ed->expire_date;

Return expiration date by "DateTime" instance.

=head2 begin_date

  $begin_date  = $ed->begin_date;

Return beginning date by "DateTime" instance.

=head2 not_after

Synonym for expire_date.

=head2 not_before

Synonym for begin_date.

=head2 is_expired

  $expired = $ed->is_expired;

Obtain already expired or not.

You can specify interval to obtain will expire on the future time.
Acceptable intervals are human readable string (parsed by
"Time::Duration::Parse") and "DateTime::Duration" instance.

  # will expire after 2 months
  $expired = $ed->is_expired('2 months');
  $expired = $ed->is_expired(DateTime::Duration->new(months=>2));

=head2 type

return type of examinee certificate. "ssl" or "file".

=head2 target

return hostname or path of examinee certificate.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-ssl-expiredate@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 REPOSITORY

L<http://github.com/hirose31/net-ssl-expiredate>

  git clone git://github.com/hirose31/net-ssl-expiredate.git

patches and collaborators are welcome.

=head1 SEE ALSO

=head1 COPYRIGHT & LICENSE

Copyright HIROSE Masaaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

