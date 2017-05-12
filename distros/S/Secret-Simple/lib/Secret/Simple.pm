package Secret::Simple;

use strict;
use warnings;
use vars qw( @ISA @EXPORT );

use Carp;
use Crypt::CBC;
use Exporter;
use MIME::Base64;

our $VERSION = '0.11';

@ISA    = qw( Exporter );
@EXPORT = qw( ssdecrypt ssdecryptraw ssencrypt ssencryptraw );

my $DEFAULT_CIPHER  = 'Rijndael_PP';
my $DEFAULT_KEYFILE = '~/.ssh/id_dsa';
my $DEFAULT_GARBAGE = 'eLH6eDl7H+Ng07Zj';

sub new {
    my ($class, @args) = @_;
    my $self = {};

    my (%args, %option);
    @args = ( 'key', '{sskeyfile}' ) unless @args;
    if (ref($args[0]) eq 'HASH') {
        %option = %{$args[0]};
    } else {
        @args = ( 'key', $args[0] ) if @args == 1;
        croak "Invalid arguments passed" if scalar(@args) & 1;
        %args = @args;
    }
    my %tmp = map { $_ => 1 } qw( key keyfilesize );
    for my $opt (keys %args) {
        my $opt2 = $opt;
        $opt2 =~ s/^-//;
        croak "Unrecognized -$opt2 option passed" unless $tmp{$opt2};
        $option{$opt2} = $args{$opt};
    }
    $option{key} = '{sskeyfile}' unless $option{key};
    key($self, $option{key});
    $self->{keyfilesize} = 0;
    keyfilesize($self, $option{keyfilesize}) if $option{keyfilesize};
    $self->{keydata} = keydata($self);

    bless($self, $class);
    return $self;
}

sub decrypt {
    my ($self, $b64ciphertext) = @_;
    return unless $b64ciphertext;
    my $ciphertext = decode_base64($b64ciphertext);
    my $plaintext = decryptraw($self, $ciphertext);
    return $plaintext;
}

sub decryptraw {
    my ($self, $ciphertext) = @_;
    return unless $ciphertext;
    my $cipher = Crypt::CBC->new(
      -key    => $self->{keydata},
      -cipher => $DEFAULT_CIPHER,
      -header => 'none',
      -iv     => $DEFAULT_GARBAGE
    );
    my $plaintext = $cipher->decrypt($ciphertext);
    return $plaintext;
}

sub encrypt {
    my ($self, $plaintext) = @_;
    my $ciphertext = encryptraw($self, $plaintext);
    return unless $ciphertext;
    return encode_base64( $ciphertext );
}

sub encryptraw {
    my ($self, $plaintext) = @_;
    return unless $plaintext;
    my $cipher = Crypt::CBC->new(
      -key    => $self->{keydata},
      -cipher => $DEFAULT_CIPHER,
      -header => 'none',
      -iv     => $DEFAULT_GARBAGE
    );
    my $ciphertext = $cipher->encrypt($plaintext);
    return $ciphertext;
}

sub key {
    my ($self, $key) = @_;
    if (defined $key) {
        croak "Bad key specification"
          if ref($key) && ref($key) ne 'ARRAY';
        $self->{key} = $key;
    }
    return $self->{key};
}

sub keydata {
    my ($self) = @_;

    unless (defined $self->{keydata}) {
        # calculate aggregate key data
        my @keys = ref($self->{key}) eq 'ARRAY' ?
          @{$self->{key}} : ( $self->{key} );
        my $data = "";
        for my $frag (@keys) {
            my $piece = $frag;
            if ($frag =~ /^\{sskeyfile\}/) {
                my $fn = $frag;
                $fn =~ s/^\{sskeyfile\}//;
                $fn = $DEFAULT_KEYFILE unless $fn;
                my ($fn1) = glob($fn);
                croak "No access to specified key file '$fn'"
                  unless -r $fn1;
                $piece = _read_rawfile($fn1, $self->{keyfilesize});
            }
            $data .= $piece;
        }
        $self->{keydata} = $data;
    }

    return $self->{keydata};
}

sub keyfilesize {
    my ($self, $num) = @_;
    croak "Bad limit passed" if defined $num && $num !~ /^\d+$/;
    $self->{keyfilesize} = $num if defined $num;
    return $self->{keyfilesize};
}

#  The procedural style function section begins here.

sub ssdecrypt {
    my ($b64ciphertext, @keyspec) = @_;
    return unless $b64ciphertext;
    my $ciphertext = decode_base64($b64ciphertext);
    my $plaintext = ssdecryptraw($ciphertext, @keyspec);
    return $plaintext;
}

sub ssdecryptraw {
    my ($ciphertext, @keyspec) = @_;
    return unless $ciphertext;
    my $ss = @keyspec ?
      Secret::Simple->new( key => [ @keyspec ] ) :
      Secret::Simple->new();
    my $plaintext = $ss->decryptraw($ciphertext);
    return $plaintext;
}

sub ssencrypt {
    my ($plaintext, @keyspec) = @_;
    return unless $plaintext;
    my $ciphertext = ssencryptraw($plaintext, @keyspec);
    return unless $ciphertext;
    return encode_base64( $ciphertext );
}

sub ssencryptraw {
    my ($plaintext, @keyspec) = @_;
    return unless $plaintext;
    my $ss = @keyspec ?
      Secret::Simple->new( key => [ @keyspec ] ) :
      Secret::Simple->new();
    my $ciphertext = $ss->encryptraw($plaintext);
    return $ciphertext;
}

#  The private module function section begins here.

#  The _read_rawfile private function accepts a filename and an optional
#  limit argument. The entire contents of a specified file will be read
#  and returned as a string if the limit is undefined or zero, but a
#  maximum of $limit bytes will be read in and returned otherwise.

sub _read_rawfile {
    my ($fn, $limit) = @_;
    croak "No filename argument passed" unless $fn;
    croak "Bad limit passed" if $limit && $limit !~ /^\d+$/;
    my ($chunk, $num, $data, $buf) = ( 8192, 0, "" );
    croak "Unable to read from file" unless
      open my ($F), $fn;
    binmode($F);
    until ( eof($F) ) {
        $chunk = $limit - $num if $limit && $num + $chunk > $limit;
        $num += read($F, $buf, $chunk);
        $data .= $buf;
        last if $limit && $num >= $limit;
    }
    close $F;
    return $data;
}

1;
__END__

=head1 NAME

Secret::Simple - Secure secrets in configurations and code

=head1 VERSION

This document describes Secret::Simple version 0.11

=head1 SYNOPSIS

    # OOP style
    my $ss = Secret::Simple->new();
    my $ciphertext = $ss->encrypt($plaintext);
    my $plaintext  = $ss->decrypt($ciphertext);

    # procedural style
    my $ciphertext = ssencrypt($plaintext);
    my $plaintext  = ssdecrypt($ciphertext);

=head1 DESCRIPTION

This module implements a straightforward interface for encrypting and
decrypting secret information such as user IDs and passwords (e.g.
database connection or remote account credentials). C<Secret::Simple>
can also be used on a limited basis to protect arbitrary data. By
default the ciphertext returned is Base 64 encoded so as to be easily
embedded within configurations or scripts. A command-line utility called
C<sstool> is included to facilitate easy manipulation of cipher and
plaintext snippets.

The encryption mechanism utilizes the strong AES algorithm, so any
weaknesses in C<Secret::Simple> predominantly lie in how keys are
protected. A balance must be struck between key accessibility, key
protection, and overall complexity. The calling code can supply a key,
series of keys, key files, or a combination. If no key information is
explicitly passed, the module will attempt to use the OS user's private
SSH DSA key file by default if it exists.

The major goal of this module is to be as secure as possible while
being simple and convenient enough to encourage its use. Psychology does
factor in: I<simple> is a very important consideration. If the security
methods are too onerous or complicated to use, many sysadmins or
developers may simply use plaintext (no protection other that OS file
permissions) or simple ciphers like rot13. The security of the
C<Secret::Simple> method is not perfect, but it does represent a
significant improvement over commonly-used nonsecure methods of
embedding credentials and other secrets in Perl configurations and
scripts. If used appropriately, C<Secret::Simple> can greatly improve
application and configuration security. Even so, care must always be
taken to protect files and file permissions.

=head1 METHODS

=head2 C<new()>

    my $ss = Secret::Simple->new(); # default to user's private SSH DSA key

    my $ss = Secret::Simple->new('my secret key');

    my $ss = Secret::Simple->new( %options );

    my $ss = Secret::Simple->new( \%options );

The constructor returns a B<Secret::Simple> object. Valid options are:

=over

=item B<-key>

The value of this parameter can be a scalar or array reference. Multiple
elements will simply be concatenated together. This option accepts raw
key data by default, but can also accept file-based key data according
to the following parameter value syntax:

    'secret key phrase'        - string is the literal key (default)

    '{sskeyfile}/path/key.raw' - read raw key from file

    '{sskeyfile}'              - read raw key from default file

Specifying C<{sskeyfile}> by itself will designate the same behavior as
the default of passing no key information: the constructor will attempt
to use the literal contents of the current user's C<~/.ssh/id_dsa> file
as a key.

=item B<-keyfilesize>

Specifies the maximum number of bytes to read from a single key file.
The default value of 0 is unlimited, but performance problems may
quickly arise if large files (e.g. MP3) are utilized as keys.

=back

=head2 C<decrypt()>

=over

Returns the literal plaintext of the supplied encrypted and Base 64
encoded value.

Example:

    my $DBCRED = 'zzpjnDlUqz3+KCke5Rr4dA=='; # plaintext is jblow^secret

    my $ss = Secret::Simple->new();
    my ($user, $pass) = split /\^/, $ss->decrypt($DBCRED);

=back

=head2 C<decryptraw()>

=over

Performs identically to the C<decrypt()> method except that the
value passed is assumed to be raw ciphertext (no Base 64 encoding).

=back

=head2 C<encrypt()>

=over

Returns the Base 64 encoded ciphertext of the supplied literal
plaintext.

Example:

    my $ss = Secret::Simple->new();
    my $ciphertext = $ss->encrypt('jblow^secret');
    # ciphertext will resemble: zzpjnDlUqz3+KCke5Rr4dA==

=back

=head2 C<encryptraw()>

=over

Performs identically to the C<encrypt()> method except the resulting
ciphertext is returned without the Base 64 encoding.

=back

=head2 C<key()>

=over

This method can be invoked without an argument to obtain the current
key specification value(s). Note that this is not necessarily the same
as the information returned by the C<keydata()> method. Invoking with an
argument will establish new settings.  See the description of the
C<new()> method's C<-key> option for more details.

=back

=head2 C<keydata()>

=over

Returns the combined raw key data. The returned data represents the
aggregate raw key if multiple keys and key files were specified.

=back

=head2 C<keyfilesize()>

=over

The maximum number of bytes to read from a single key file. This method
can be invoked without an argument to obtain the current limit setting
(default 0 is unlimited). Invoking with an argument will establish the
new setting.

=back

=head1 EXPORTED FUNCTIONS

C<Secret::Simple> exports some functions you may use to avoid the OOP
interface if you wish.

=head2 C<ssdecrypt($b64ciphertext, [key1], [key2], ...)>

=over

This function requires a minimum of one argument: the Base 64 encoded
ciphertext to be decrypted. Any number of optional additional arguments
may be specified as key values that follow the same rules as the
C<new()> constructor's C<-key> option.

Examples:

    my $DBCRED = 'zzpjnDlUqz3+KCke5Rr4dA=='; # plaintext is jblow^secret

    # 1. simple
    my ($user, $pass) = split /\^/, ssdecrypt($DBCRED);

    # 2. id_rsa instead of id_dsa
    my ($user, $pass) = split /\^/, ssdecrypt($DBCRED,
      '{sskeyfile}~/.ssh/id_rsa');

    # 3. more complex example
    my ($user, $pass) = split /\^/, ssdecrypt($DBCRED,
      '{sskeyfile}', '{sskeyfile}/path/otherkey');

=back

=head2 C<ssdecryptraw($ciphertext, [key1], [key2], ...)>

=over

Performs identically to the C<ssdecrypt()> function except that the
value passed must be raw ciphertext without Base 64 encoding.

=back

=head2 C<ssencrypt($plaintext, [key1], [key2]...)>

=over

This function requires a minimum of one argument: the plaintext to be
encrypted. Any number of optional additional arguments may be specified
as key values that follow the same rules as the C<new()> constructor's
C<-key> option.

Examples:

    # use default ~/.ssh/id_dsa key
    my $ciphertext = ssencrypt('jblow^secret');

    # use explicit passphrase
    my $ciphertext = ssencrypt('jblow^secret', 'secret key');

    # use combination of two key files
    my $ciphertext = ssencrypt('jblow^secret',
      '{sskeyfile}/path1/key1', '{sskeyfile}/path2/key2');

=back

=head2 C<ssencryptraw($plaintext, [key1], [key2], ...)>

=over

Performs identically to the C<ssencrypt()> function except the resulting
ciphertext is returned without the Base 64 encoding.

=back

=head1 DEPENDENCIES

This module requires the following other modules:

=over

=item *

Carp

=item *

Crypt::CBC

=item *

Crypt::Rijndael_PP

=item *

Exporter

=item *

MIME::Base64

=back

=head1 AUTHOR

Adam G. Foust, <nospam-agf@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006, Adam G. Foust. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
