package OpenSocialX::Shindig::Crypter;
our $VERSION = '0.03';

# ABSTRACT: OpenSocial Shindig Crypter

use URI::Escape qw/uri_escape uri_unescape/;
use MIME::Base64 qw/decode_base64 encode_base64/;
use Crypt::CBC;
use Digest::SHA;

# Key used for time stamp (in seconds) of data
my $TIMESTAMP_KEY = 't';

# allow three minutes for clock skew
my $CLOCK_SKEW_ALLOWANCE = 180;

sub new {
    my $class = shift;

    my $cfg = defined $_[0] && ref( $_[0] ) eq 'HASH' ? shift : {@_};

    # validate
    $cfg->{cipher} or die 'cipher key is required';
    $cfg->{hmac}   or die 'hmac key is required';
    $cfg->{iv}     or die 'iv key is required';

    ( length( $cfg->{cipher} ) == 16 ) or die 'cipher key must be 16 chars';
    ( length( $cfg->{iv} ) == 16 )     or die 'iv key must be 16 chars';

    return bless $cfg, $class;
}

sub wrap {
    my ( $self, $in ) = @_;

    my $encoded = _serializeAndTimestamp($in);
    my $cipher  = Crypt::CBC->new(
        {
            'key'         => $self->{cipher},
            'cipher'      => 'Rijndael',
            'iv'          => $self->{iv},
            'literal_key' => 1,
            'padding'     => 'null',
            'header'      => 'none',
            keysize       => 128 / 8,
        }
    );
    my $cipherText = $cipher->encrypt($encoded);
    my $hmac       = Digest::SHA::hmac_sha1( $cipherText, $self->{hmac} );
    my $b64        = encode_base64( $cipherText . $hmac );
    return $b64;
}

sub _serializeAndTimestamp {
    my ($in) = @_;

    my $encoded;
    foreach my $key ( keys %$in ) {
        $encoded .= uri_escape($key) . "=" . uri_escape( $in->{$key} ) . "&";
    }
    $encoded .= $TIMESTAMP_KEY . "=" . time();
    return $encoded;
}

sub unwrap {
    my ( $self, $in, $max_age ) = @_;

    my $bin        = decode_base64($in);
    my $cipherText = substr( $bin, 0, -20 );
    my $hmac       = substr( $bin, length($cipherText) );

    # verify
    my $v_hmac = Digest::SHA::hmac_sha1( $cipherText, $self->{hmac} );
    if ( $v_hmac ne $hmac ) {
        die 'HMAC verification failure';
    }
    my $cipher = Crypt::CBC->new(
        {
            'key'         => $self->{cipher},
            'cipher'      => 'Rijndael',
            'iv'          => $self->{iv},
            'literal_key' => 1,
            'padding'     => 'null',
            'header'      => 'none',
            keysize       => 128 / 8,
        }
    );
    my $plain = $cipher->decrypt($cipherText);
    my $out   = $self->deserialize($plain);

    $self->checkTimestamp( $out, $max_age );

    return $out;
}

sub deserialize {
    my ( $self, $plain ) = @_;

    my $h;
    my @items = split( /[\&\=]/, $plain );
    my $i;
    for ( $i = 0 ; $i < scalar(@items) ; ) {
        my $key   = uri_unescape( $items[ $i++ ] );
        my $value = uri_unescape( $items[ $i++ ] );
        $h->{$key} = $value;
    }
    return $h;
}

sub checkTimestamp {
    my ( $self, $out, $max_age ) = @_;

    my $minTime = $out->{$TIMESTAMP_KEY} - $CLOCK_SKEW_ALLOWANCE;
    my $maxTime = $out->{$TIMESTAMP_KEY} + $max_age + $CLOCK_SKEW_ALLOWANCE;
    my $now     = time();
    if ( !( $minTime < $now && $now < $maxTime ) ) {
        die "Security token expired";
    }
}

my $OWNER_KEY  = "o";
my $APP_KEY    = "a";
my $VIEWER_KEY = "v";
my $DOMAIN_KEY = "d";
my $APPURL_KEY = "u";
my $MODULE_KEY = "m";

sub create_token {
    my $self = shift;

    my $data = defined $_[0] && ref( $_[0] ) eq 'HASH' ? shift : {@_};
    my $token_data = {
        $OWNER_KEY  => $data->{owner},
        $APP_KEY    => $data->{app},
        $VIEWER_KEY => $data->{viewer},
        $DOMAIN_KEY => $data->{domain},
        $APPURL_KEY => $data->{app_url},
        $MODULE_KEY => $data->{module_id},
    };
    my $token = $self->wrap($token_data);
    return uri_escape($token);
}

1;
__END__

=head1 NAME

OpenSocialX::Shindig::Crypter - OpenSocial Shindig Crypter

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use OpenSocialX::Shindig::Crypter;

    my $crypter = OpenSocialX::Shindig::Crypter->new( {
        cipher => 'length16length16',
        hmac   => 'forhmac_sha1',
        iv     => 'anotherlength16k'
    } );
    my $token = $crypter->create_token( {
        owner    => $owner_id,
        viewer   => $viewer_id,
        app      => $app_id,
        app_url  => $app_url,
        domain   => $domain,
        module_id => $module_id
    } );

=head1 DESCRIPTION

Apache Shindig L<http://incubator.apache.org/shindig/> is an OpenSocial container and helps you to start hosting OpenSocial apps quickly by providing the code to render gadgets, proxy requests, and handle REST and RPC requests.

From the article L<http://www.chabotc.com/generic/using-shindig-in-a-non-php-or-java-envirionment/>, we know that we can do 'Application' things in Perl. basically the stuff will be

=over 4

=item *

use Perl L<OpenSocialX::Shindig::Crypter> (this module) to create B<st=> encrypted token through C<create_token>

=item *

the php C<BasicBlobCrypter.php> will unwrap the token and validate it. The file is in the C<php> dir of this .tar.gz or you can download it from L<http://github.com/fayland/opensocialx-shindig-crypter/raw/master/php/BasicBlobCrypter.php>

you can copy it to the dir of C<extension_class_paths> defined in shindig/config/container.php, it will override the default C<BasicBlobCrypter.php> provided by shindig.

and the last thing is to defined the same keys in shindig/config/container.php like:

  'token_cipher_key' => 'length16length16',
  'token_hmac_key' => 'forhmac_sha1',
  'token_iv_key'   => 'anotherlength16k',

remember that C<token_iv_key> is new

=back

=head2 METHODS

=over 4

=item * new

    my $crypter = OpenSocialX::Shindig::Crypter->new( {
        cipher => 'length16length16',
        hmac   => 'forhmac_sha1',
        iv     => 'anotherlength16k'
    } );

C<cipher> and C<iv> must be 16 chars.

=item * create_token

    my $token = $crypter->create_token( {
        owner    => $owner_id,
        viewer   => $viewer_id,
        app      => $app_id,
        app_url  => $app_url,
        domain   => $domain,
        module_id => $module_id
    } );

if you don't know what C<module_id> is, you can leave it alone.

=item * wrap

    my $encrypted  = $crypter->wrap({
        a => 1,
        c => 3,
        o => 5
    } );

encrypt the hash by L<Crypt::Rijndael> and L<Digest::SHA> and encode_base64 it

=item * unwrap

    my $hash = $crypter->unwrap($encrypted);

decrypt the above data

=item * deserialize

=item * checkTimestamp

=item * _serializeAndTimestamp

=back

=head2 EXAMPLE

    use URI::Escape;
    use MIME::Base64;
    use OpenSocialX::Shindig::Crypter;

    my $crypter = OpenSocialX::Shindig::Crypter->new( {
        cipher => $config->{opensocial}->{cipherKey},
        hmac   => $config->{opensocial}->{hmacKey},
        iv     => $config->{opensocial}->{ivKey},
    } );
    my $security_token = uri_escape( encode_base64( $crypter->create_token( {
        owner   => $owner_id,
        viewer  => $viwer_id,
        app     => $gadget->{id},
        domain  => $config->{opensocial}->{container},
        app_url => $gadget->{url},
    } ) ) );

    # later in tt2 or others
    # st=$security_token

=head1 AUTHOR

  Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=pod 
