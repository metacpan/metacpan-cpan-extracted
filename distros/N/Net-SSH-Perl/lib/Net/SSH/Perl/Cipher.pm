package Net::SSH::Perl::Cipher;

use strict;
use warnings;
use Carp qw( croak );
use Crypt::Digest::SHA512 qw( sha512 );

use vars qw( %CIPHERS %CIPHERS_SSH2 %CIPH_REVERSE %SUPPORTED );
BEGIN {
    %CIPHERS = (
        None => 0,
        IDEA => 1,
        DES  => 2,
        DES3 => 3,
        RC4 => 5,
        Blowfish => 6,
        AES128_CTR => 7,
        AES192_CTR => 8,
        AES256_CTR => 9,
        AES128_CBC => 10,
        AES192_CBC => 11,
        AES256_CBC => 12,
        ChachaPoly => 13,
    );
    %CIPHERS_SSH2 = (
        '3des-cbc' => 'DES3',
        'blowfish-cbc' => 'Blowfish',
        'arcfour' => 'RC4',
        'aes128-ctr' => 'AES128_CTR',
        'aes192-ctr' => 'AES192_CTR',
        'aes256-ctr' => 'AES256_CTR',
        'aes128-cbc' => 'AES128_CBC',
        'aes192-cbc' => 'AES192_CBC',
        'aes256-cbc' => 'AES256_CBC',
        'chacha20-poly1305@openssh.com' => 'ChachaPoly',
    );
    %CIPH_REVERSE = reverse %CIPHERS;
}

sub _determine_supported {
    for my $ciph (keys %CIPHERS) {
        my $pack = sprintf "%s::%s", __PACKAGE__, $ciph;
        eval "use $pack";
        $SUPPORTED{$CIPHERS{$ciph}}++ unless $@;
    }
}

sub new {
    my $class = shift;
    my $type = shift;
    my($ciph);
    unless ($type eq "None") {
        $type = $CIPHERS_SSH2{$type} || $type;
        my $ciph_class = join '::', __PACKAGE__, $type;
        (my $lib = $ciph_class . ".pm") =~ s!::!/!g;
        require $lib;
        $ciph = $ciph_class->new(@_);
    }
    else {
        $ciph = bless { }, __PACKAGE__;
    }
    $ciph;
}

sub new_from_key_str {
    my $class = shift;
    defined $_[1] ?
        $class->new($_[0], sha512($_[1])) :
        $class->new(@_);
}

sub enabled { $_[0]->{enabled} }
sub enable { $_[0]->{enabled} = 1 }
sub authlen { 0 }
sub ivlen { shift->blocksize }

sub id {
    my $this = shift;
    my $type;
    if (my $class = ref $this) {
        my $pack = __PACKAGE__;
        ($type = $class) =~ s/^${pack}:://;
    }
    else {
        $type = $this;
    }
    $CIPHERS{$type};
}

sub name {
    my $this = shift;
    my $name;
    if (my $class = ref $this) {
        my $pack = __PACKAGE__;
        ($name = $class) =~ s/^${pack}:://;
    }
    else {
        $name = $CIPH_REVERSE{$this};
    }
    $name;
}

sub mask {
    my $mask = 0;
    $mask |= (1<<$_) for keys %SUPPORTED;
    $mask;
}

sub supported {
    unless (keys %SUPPORTED) {
        _determine_supported();
    }
    my $protocol = 1;
    shift, $protocol = shift
        if not ref $_[0] and $_[0] and $_[0] eq 'protocol';
    unless(@_) {
        return [ keys %SUPPORTED ] unless 2 == $protocol;
        return [ grep $SUPPORTED{$_}, map $CIPHERS{$_}, values %CIPHERS_SSH2 ];
    }

    my $id = ref $_[0] ? shift->id : shift;
    return $id == 0 || exists $SUPPORTED{$id} unless @_;
    my $ssupp = shift;
    mask() & $ssupp & (1 << $id);
}

sub encrypt { $_[1] }

sub decrypt { $_[1] }

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher - Base cipher class, plus utility methods

=head1 SYNOPSIS

    use Net::SSH::Perl::Cipher;

    # Get list of supported cipher IDs.
    my $supported = Net::SSH::Perl::Cipher::supported();

    # Translate a cipher name into an ID.
    my $id = Net::SSH::Perl::Cipher::id($name);

    # Translate a cipher ID into a name.
    my $name = Net::SSH::Perl::Cipher::name($id);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher> provides a base class for each of
the encryption cipher classes. In addition, it defines
a set of utility methods that can be called either as
functions or object methods.

=head1 UTILITY METHODS

=head2 supported( [ protocol => $protocol, ] [ $ciph_id [, $server_supports ] ])

Without arguments returns a reference to an array of
ciphers supported by I<Net::SSH::Perl>. These are ciphers
that have working Net::SSH::Perl::Cipher:: implementations,
essentially.  Pass 'protocol => 2' to get a list of
SSH2 ciphers.

With one argument I<$ciph_id>, returns a true value if
that cipher is supported by I<Net::SSH::Perl>, and false
otherwise.

With two arguments, I<$ciph_id> and I<$server_supports>,
returns true if the cipher represented by I<$ciph_id>
is supported both by I<Net::SSH::Perl> and by the sshd
server. The list of ciphers supported by the server
should be in I<$server_supports>, a bit mask sent
from the server during the session identification
phase.

Can be called either as a non-exported function, i.e.

    my $i_support = Net::SSH::Perl::Cipher::supported();

or as an object method of a I<Net::SSH::Perl::Cipher>
object, or an object of a subclass:

    if ($ciph->supported($server_supports)) {
        print "Server supports cipher $ciph";
    }

=head2 id( [ $cipher_name ] )

Translates a cipher name into a cipher ID.

If given I<$cipher_name> translates that name into
the corresponding ID. If called as an object method,
translates the object's cipher class name into the
ID.

=head2 name( [ $cipher_id ] )

Translates a cipher ID into a cipher name.

If given I<$cipher_id> translates that ID into the
corresponding name. If called as an object method,
returns the (stripped) object's cipher class name;
for example, if the object were of type
I<Net::SSH::Perl::Cipher::IDEA>, I<name> would return
I<IDEA>.

=head1 CIPHER USAGE

=head2 Net::SSH::Perl::Cipher->new($cipher_name, $key)

Instantiates a new cipher object of the type
I<$cipher_name> with the key I<$key>; returns
the cipher object, which will be blessed into the
actual cipher subclass.

If I<$cipher_name> is the special type I<'None'>
(no encryption cipher), the object will actually
be blessed directly into the base class, and
text to be encrypted and decrypted will be passed
through without change.

=head2 $cipher->encrypt($text)

Encrypts I<$text> and returns the encrypted string.

=head2 $cipher->decrypt($text)

Decrypts I<$text> and returns the decrypted string.

=head1 CIPHER DEVELOPMENT

Classes implementing an encryption cipher must
implement the following three methods:

=over 4

=item * $class->new($key)

Given a key I<$key>, should construct a new cipher
object and bless it into I<$class>, presumably.

=item * $cipher->encrypt($text)

Given plain text I<$text>, should encrypt the text
and return the encrypted string.

=item * $cipher->decrypt($text)

Given encrypted text I<$text>, should decrypt the
text and return the decrypted string.

=back

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
