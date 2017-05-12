package Mojolicious::Plugin::Crypto;
{
    $Mojolicious::Plugin::Crypto::VERSION = '0.14';
}
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util;
use Mojo::Loader qw(load_class find_modules);
use Crypt::CBC;
use Crypt::PRNG;
use Crypt::Cipher;

no if $] >= 5.018, warnings => "experimental::smartmatch";

our %symmetric_algo = (
    'aes'        => 'Crypt::Cipher::AES',
    'blowfish'   => 'Crypt::Cipher::Blowfish',
    'des'        => 'Crypt::Cipher::DES',
    '3des'       => 'Crypt::Cipher::DES_EDE',
    'triple_des' => 'Crypt::Cipher::DES_EDE',
    'des_ede'    => 'Crypt::Cipher::DES_EDE',
    'twofish'    => 'Crypt::Cipher::Twofish',
    'xtea'       => 'Crypt::Cipher::XTEA',
    'anubis'     => 'Crypt::Cipher::Anubis',
    'camellia'   => 'Crypt::Cipher::Camellia',
    'kasumi'     => 'Crypt::Cipher::KASUMI',
    'khazad'     => 'Crypt::Cipher::Khazad',
    'multi2'     => 'Crypt::Cipher::MULTI2',
    'noekeon'    => 'Crypt::Cipher::Noekeon',
    'rc2'        => 'Crypt::Cipher::RC2',
    'rc5'        => 'Crypt::Cipher::RC5',
    'rc6'        => 'Crypt::Cipher::RC6',
);

sub register {
    my ( $self, $app, $args ) = @_;
    $args ||= {};

    if ( $args->{symmetric_cipher} || !%{$args} ) {
        for my $module ( find_modules 'Crypt::Cipher' ) {
            my $e = load_class $module;
            warn qq{Loading "$module" failed: $e} and next if ref $e;
        }

        foreach my $method (
            qw( _crypt_x _decrypt_x crypt_aes decrypt_aes crypt_blowfish decrypt_blowfish crypt_des decrypt_des
            crypt_3des decrypt_3des crypt_twofish decrypt_twofish crypt_xtea decrypt_xtea crypt_anubis 
            decrypt_anubis crypt_camellia decrypt_camellia crypt_kasumi decrypt_kasumi crypt_khazad
            decrypt_khazad crypt_noekeon decrypt_noekeon crypt_multi2 decrypt_multi2 crypt_rc2 decrypt_rc2 crypt_rc5
            decrypt_rc5 crypt_rc6 decrypt_rc6 gen_key gen_iv)
          )
        {
            $app->helper( $method => \&{$method} );
        }
    }

    if ( $args->{digest} || !%{$args} ) {
        for my $module ( find_modules 'Crypt::Digest' ) {
            my $e = load_class $module;

            if ( ref $e ) {
                warn qq{Loading "$module" failed: $e} and next;
            }

            map { $app->helper( $_ => \&{$_} ) } map {
                    $_ ~~ /^sha|md5|md4|md2|ripemd|tiger|whirlpool.*/
                  ? $_
                  : ()
            } _lm($module);

        }
    }

    if ( $args->{mac} || !%{$args} ) {
        for my $module ( find_modules 'Crypt::Mac' ) {
            my $e = load_class $module;

            if ( ref $e ) {
                warn qq{Loading "$module" failed: $e} and next;
            }

            map { $app->helper( $_ => \&{$_} ) }
              map { $_ ~~ /^hmac.*/ ? $_ : () } _lm($module);

        }
    }

}

sub _crypt_x {
    my ( $self, $algo, $content, $key ) = @_;
    $key = $self->gen_key("sha256") unless ($key);
    my $keypack = pack( "H16", $key );
    my $en = new Crypt::CBC(
        -key    => $keypack,
        -salt   => 1,
        -cipher => $symmetric_algo{$algo}
    )->encrypt($content);
    my $enh = unpack( 'H*', $en );
    return ( $enh, $key );
}

sub _decrypt_x {
    my ( $self, $algo, $cipher_content, $key ) = @_;
    return "" unless ($key);
    my $keypack = pack( "H16", $key );
    my $de      = pack( 'H*',  $cipher_content );
    my $clear   = new Crypt::CBC(
        -key    => $keypack,
        -salt   => 1,
        -cipher => $symmetric_algo{$algo}
    )->decrypt($de);
    return ( $clear, $key );
}

sub gen_key {
    my ( $self, $mode ) = @_;
    ( $mode eq "sha256" ) ? sha256_hex( _prng( 100, "alphanum" ) ) : "NONE";
}

sub gen_iv {
    my ( $self, $byte, $mode ) = @_;
    ( $mode eq "prng" ) ? _prng( $byte, "" ) : "";
}

sub _prng {
    my ( $byte, $mode ) = @_;

    Crypt::PRNG->bytes_b64($byte) unless ( $mode ne "base64" );
    Crypt::PRNG->bytes_hex($byte) unless ( $mode ne "hex" );
    Crypt::PRNG->string($byte)    unless ( $mode ne "alphanum" );
    Crypt::PRNG->bytes($byte);
}

sub _lm {
    my $module = shift;
    no strict 'refs';
    return grep { defined &{"$module\::$_"} } keys %{"$module\::"};
}

sub _d {
    my ( $called, $data ) = @_;
    $called =~ /^([A-Za-z0-9]+)\_.*/;
    no strict 'refs';
    return &{ 'Crypt::Digest::' . uc($1) . '::' . $called }($data);
}

sub _h {
    my ( $hash_name, $key, $called, @other ) = @_;
    no strict 'refs';
    return &{ 'Crypt::Mac::HMAC::' . $called }( $hash_name, $key, @other );
}

use vars qw($AUTOLOAD);

sub AUTOLOAD {
    my ( $self, $c, $k, @other ) = @_;
    my $called = $AUTOLOAD =~ s/.*:://r;
    return _d( $called, $c )
      unless ( $called !~ /^sha|md5|md4|md2|ripemd|tiger|whirlpool.*/ );
    return _h( $c, $k, $called, @other ) unless ( $called !~ /^hmac.*/ );
    $called =~ m/(.*)_(.*)/;
    my $func = "_" . lc($1) . "_x";
    return $self->$func( lc($2), $c, $k );
}
sub DESTROY { }

#################### main pod documentation begin ###################

=head1 NAME

Mojolicious::Plugin::Crypto - Provide interface to some cryptographic stuff.

=head1 SYNOPSIS

  use Mojolicious::Plugin::Crypto;
  
  my $fix_key = 'secretpassphrase';
  my $plain = "NemuxMojoCrypt";

  #### Symmetric Functions
  # You can leave key value empty and it will generate a new key for you

  my ($crypted, $key)  = $t->app->crypt_aes($plain, $fix_key);
  
  #... [ store this crypted data where do you want ... ]
  
  # and decrypt it
  my $clean =  $t->app->decrypt_aes($crypted, $key);
   
  ### Hash

  ### From string/buffer
  my $digest_hex = $t->app->sha256_hex("Take this content");
  ### From filehandle
  my $digest_raw = $t->app->sha256_file(*FILEHANDLE);
  ### From File
  $digest_hex    = $t->app->sha256_file_hex('filename.txt');

  ### base64
  my $digest_b64  = $t->app->sha256_b64('data string');
  my $digest_b64u = $t->app->sha256_b64u('data string');

=head1 DESCRIPTION

=over

=item * 

Symmetric cipher algorithms using cipher-block chaining. AES, Blowfish, DES, 3DES and more, see below.

=item *

Hash/Digest Functions - SHA*, MD*, Whirlpool, CHAES, RIPEMD*, Tiger192.

=item *

HMAC message authentication code (MAC) algorithm.

=back

=head2 Symmetric algorithms supported 

You can use this plugin in order to encrypt and decrypt using one of these algorithms: 

=over

=item * 

B<AES (aka Rijndael)>

=item * 

B<Blowfish>

=item * 

B<DES>

=item * 

B<DES_EDE (aka Triple-DES, 3DES)>

=item * 

B<TWOFISH>

=item * 

B<XTEA>

=item * 

B<ANUBIS>

=item * 

B<CAMELLIA>

=item * 

B<KASUMI>

=item * 

B<KHAZAD>

=item * 

B<NOEKEON>

=item * 

B<MULTI2>

=item * 

B<RC2>

=item * 

B<RC5>

=item * 

B<RC6>

=back


=head1 Symmetric Algorithms USAGE

=head2 crypt_[ALGO_NAME]() 
  
  call function crypt_ followed by the lowercase algorithms name. For example crypt_aes("My Plain Test", "ThisIsMySecretKey")
  an array will be the return value with ('securedata', 'keyused'). 

=head2 decrypt_[ALGO_NAME]()
  
  The same thing for decryption decrypt_ followed by the algorithms name in lowercase
  Ex.: decrypt_aes("MyCryptedValue","ThisIsMySecretKey") it will return an array with two values: 
  the first one is the clear text decrypted and the last one the key used. That's all.

=head2 methods list 

crypt_aes()
crypt_blowfish()
crypt_des()
crypt_3des() [|| crypt_des_ede() || crypt_triple_des()]
crypt_twofish()
crypt_xtea();
crypt_anubis();
crypt_camellia();
crypt_kasumi();
crypt_khazad();
crypt_noekeon();
crypt_multi2();
crypt_rc2();
crypt_rc5();
crypt_rc6();

and the same for decrypt functions (please make the effort to put "de" in front of "crypt_[name]")

=head2 3DES: Multiple names, same result 

=over 4

=item 1 

B<crypt_des_ede()>

=item 2 

B<crypt_3des()>

=item 3 

B<crypt_tripple_des()>

=back

=head2 nested calls

=over 4

=item * 

B<Crypt>

=back 

($crypted, $key) = app->crypt_xtea(app->crypt_twofish(app->crypt_3des(app->crypt_blowfish(app->crypt_aes($super_plain,$super_secret)))));

=over 4

=item * 

B<Decrypt>

=back

($plain, $key) = app->decrypt_aes(app->decrypt_blowfish(app->decrypt_3des(app->decrypt_twofish(app->decrypt_xtea($crypted,$super_secret)))));

=head1 Hash/Digest Functions

Use this plugin in order to calculate digest through this algorithms:

=over

=item * 

B<SHA1>

=item * 

B<SHA224>

=item * 

B<SHA256>

=item * 

B<SHA384>

=item * 

B<SHA512>

=item * 

B<MD2>

=item * 

B<MD4>

=item * 

B<MD5>

=item * 

B<Whirlpool>

=item * 

B<CHAES>

=item * 

B<RIPEMD128>

=item * 

B<RIPEMD160>

=item * 

B<RIPEMD256>

=item * 
  
B<RIPEMD320>

=item * 
  
B<Tiger192>

=back

=head1 Hash/Digest Functions USAGE

=head2 [ALGO_NAME]() 

Example: app->sha256();

=head2 [ALGO_NAME]_hex() 

Example: app->sha256_hex();

=head2 [ALGO_NAME]_b64() 

Example: app->sha256_b64();

=head2 [ALGO_NAME]_b64u()

Example: app->sha256_b64u();

=head2 [ALGO_NAME]_file([FILENAME|FILEHANDLE])

Example: app->sha256_file();

=head2 [ALGO_NAME]_file_hex([FILENAME|FILEHANDLE]) 

Example: app->sha256_file_hex();

=head2 [ALGO_NAME]_file_b64([FILENAME|FILEHANDLE]) 

Example: app->sha256_file_b64();

=head2 [ALGO_NAME]_file_b64u([FILENAME|FILEHANDLE])

Example: app->sha256_file_b64u();

=head1 HMAC - Message authentication code HMAC

Use this plugin in order to calculate HMAC:

=head2 hmac([HASHNAME], [KEY], 'data buffer');

Example: app->hmac('SHA256', $key, 'data buffer');

=head2 hmac_hex([HASHNAME], [KEY], 'data buffer');

Example: app->hmac_hex('SHA256', $key, 'data buffer');

=head2 hmac_b64([HASHNAME], [KEY], 'data buffer');

Example: app->hmac_b64('SHA256', $key, 'data buffer');

=head2 hmac_b64u([HASHNAME], [KEY], 'data buffer');

Example: app->hmac_b64u('SHA256', $key, 'data buffer');

=head1 Dummy example using Mojolicious::Lite

  You can test in this way
  
  perl mymojoapp.pl /aes/enc?data=nemux
  perl mymojoapp.pl /aes/dec?data=53616c7465645f5f6355829a809369eee5dfb9489eaee7e190b67d15d2e35ce8

  perl mymojoapp.pl /blowfish/enc?data=nemux
  perl mymojoapp.pl /blowfish/dec?data=53616c7465645f5f16d8c8aa479121d039b04703083a9391

  #!/usr/bin/env perl

    use Mojolicious::Lite;
    
    plugin 'Crypto', { 
      symmetric_cipher => 1, # 0|1 -> enable or disable features avoiding to load unuseful modules
      digest           => 1, # With no arguments it will load all features automatically 
      mac              => 1
    };

    my $bigsecret = "MyNameisMarcoRomano";

    get '/digest/sha256' => sub {
      my $self = shift;
      my $data = $self->param('data');
      my $hex_digest = $self->sha256_hex($data);
      $self->render(text => $hex_digest);
    };

    get '/digest/md5' => sub {
      my $self = shift;
      my $data = $self->param('data');
      my ($hex_digest) = $self->md5_hex($data);
      $self->render(text => $hex_digest);
    };

    get '/aes/enc' => sub {
      my $self = shift;
      my $data = $self->param('data');
      my ($securedata) = $self->crypt_aes($data, $bigsecret);
      $self->render(text => $securedata);
    };

    get '/aes/dec' => sub {
      my $self = shift;
      my $data = $self->param('data');
      my ($plaintext) = $self->decrypt_aes($data, $bigsecret);
      $self->render(text => $plaintext);
    };

    get '/blowfish/enc' => sub {
      my $self = shift;
      my $data = $self->param('data');
      my ($securedata) = $self->crypt_blowfish($data, $bigsecret);
      $self->render(text => $securedata);
    };

    get '/blowfish/dec' => sub {
      my $self = shift;
      my $data = $self->param('data');
      my ($plaintext) = $self->decrypt_blowfish($data, $bigsecret);
      $self->render(text => $plaintext);
    };

    app->start;

=head1 BUGS

=head1 TODO

=over

=item * 

Random numbers generator

=item * 

Asymmetric algorithms

=back

=head1 SUPPORT

Write me if you need some help and feel free to improve it. 
Github: http://git.io/lQl5cA

@nemux_ 

=head1 AUTHOR

    Marco Romano
    CPAN ID: NEMUX
    Mojolicious CryptO Plugin
    
    nemux@cpan.org - @nemux_ 

    http://search.cpan.org/~nemux/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1). L<CryptX>

=cut

#################### main pod documentation end ###################

1;
