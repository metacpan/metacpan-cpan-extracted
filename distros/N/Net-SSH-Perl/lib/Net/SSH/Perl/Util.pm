package Net::SSH::Perl::Util;
use strict;
use warnings;

use vars qw( %FUNC_TO_MOD %EXPORT_TAGS );

%FUNC_TO_MOD = (
    _crc32                    => 'SSH1Misc',
    _compute_session_id       => 'SSH1MP',
    _mp_linearize             => 'SSH1MP',
    _check_host_in_hostfile   => 'Hosts',
    _all_keys_for_host        => 'Hosts',
    _add_host_to_hostfile     => 'Hosts',
    _remove_host_from_hostfile=> 'Hosts',
    _load_private_key         => 'Authfile',
    _load_public_key          => 'Authfile',
    _save_private_key         => 'Authfile',
    _respond_to_rsa_challenge => 'RSA',
    _rsa_public_encrypt       => 'RSA',
    _rsa_private_decrypt      => 'RSA',
    _prompt                   => 'Term',
    _read_passphrase          => 'Term',
    _read_yes_or_no           => 'Term',
    _current_user_win32       => 'Win32',
    _socketpair               => 'Win32',
);

%EXPORT_TAGS = (
    hosts    => [ qw( _check_host_in_hostfile _all_keys_for_host
                      _add_host_to_hostfile _remove_host_from_hostfile ) ],
    rsa      => [ qw( _rsa_public_encrypt _rsa_private_decrypt
                      _respond_to_rsa_challenge ) ],
    ssh1mp   => [ qw( _compute_session_id _mp_linearize ) ],
    authfile => [ qw( _load_public_key _load_private_key _save_private_key ) ],
    win32    => [ qw( _current_user_win32 _socketpair ) ],
    all      => [ keys %FUNC_TO_MOD ],
);

sub import {
    my $class = shift;
    my $callpack = caller;

    my @to_export;
    my @args = @_;
    for my $item (@args) {
        push @to_export,
            $item =~ s/^:// ? @{ $EXPORT_TAGS{$item} || [] } : $item;
    }

    my %loaded;
    no strict 'refs'; ## no critic
    for my $func (@to_export) {
        my $mod = join '::', __PACKAGE__, $FUNC_TO_MOD{$func};
        unless ($loaded{$mod}) {
            (my $lib = $mod . ".pm") =~ s!::!/!g;
            require $lib;
        }
        *{"${callpack}::$func"} = \&{"${mod}::$func"};
    }
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Util - Shared utility functions

=head1 SYNOPSIS

    use Net::SSH::Perl::Util qw( ... );

=head1 DESCRIPTION

I<Net::SSH::Perl::Util> contains a variety of exportable utility
functions used by the various I<Net::SSH::Perl> modules. These
range from hostfile routines, to RSA encryption routines, etc.

None of the routines are actually stored in the I<Util> module
itself; they are contained within sub-modules that are loaded
on demand by the parent I<Util> module, which contains a
table mapping function names to sub-module names. The "on
demand" is done by including either a function name, or a tag
name (see below), in your I<use> line. I<Net::SSH::Perl::Util>
will take care of loading the sub-module and importing the
requested function(s) into your namespace.

The routines are exportable by themselves, ie.

    use Net::SSH::Perl::Util qw( routine_name );

In addition, some of the routines are grouped into bundles that
you can pull in by export tag, ie.

    use Net::SSH::Perl::Util qw( :bundle );

The groups are:

=over 4

=item * hosts

Routines associated with hostfile-checking, addition, etc.
Contains C<_check_host_in_hostfile> and C<_add_host_to_hosfile>.

=item * rsa

Routines associated with RSA encryption, decryption, and
authentication. Contains C<_rsa_public_encrypt>,
C<_rsa_private_decrypt>, and C<_respond_to_rsa_challenge>.

=item * ssh1mp

Routines associated with multiple-precision integers and the
generation and manipulation of same. Contains C<_mp_linearize>
and C<_compute_session_id>.

Because the SSH1 implementation uses I<Math::GMP> for its
big integers, the functions in I<ssh1mp> all deal with
I<Math::GMP> objects.

=item * authfile

Routines associated with loading of RSA SSH1 keys (both public
and private) from keyfiles. Contains C<_load_public_key>,
C<_load_private_key>, and C<_save_private_key>.

Note that this interface is deprecated in favor of the
I<Net::SSH::Perl::Key> interface to loading keys.

=item * all

All routines. Contains all of the routines listed below.

=back

=head1 FUNCTIONS

=head2 _crc32($data)

Returns a CRC32 checksum of I<$data>. This uses I<String::CRC32>
internally to do its magic, with the caveat that the "init state"
of the checksum is C<0xFFFFFFFF>, and the result is xor-ed with
C<0xFFFFFFFF>.

This is used in SSH1.

=head2 _compute_session_id($check_bytes, $host_key, $public_key)

Given the check bytes (I<$check_bytes>) and the server host and
public keys (I<$host_key> and I<$public_key>, respectively),
computes the session ID that is then used to uniquely identify
the session between the server and client.

I<$host_key> and I<$public_key> should be I<Net::SSH::Perl::Key::RSA1>
objects; I<$check_bytes> is an 8-byte string.

Returns the session ID.

=head2 _mp_linearize($int)

Converts a multiple-precision integer I<$int> into a byte string.
I<$int> should be a I<Math::GMP> object.

Returns the byte string.

=head2 _check_host_in_hostfile($host, $host_file, $host_key)

Looks up I<$host> in I<$host_file> and checks the stored host
key against I<$host_key> to determine the status of the host.

I<$host_key> should be an object of some subclass of
I<Net::SSH::Perl::Key>; in particular, it must support the
I<extract_public> class method and the I<equal> object
method.

If the host is not found, returns HOST_NEW.

If the host is found, and the keys match, returns HOST_OK.

If the host is found, and the keys don't match, returns
HOST_CHANGED, which generally indicates a security problem
(ie. man-in-the-middle attack).

=head2 _add_host_to_hostfile($host, $host_file, $host_key)

Opens up the known hosts file I<$host_file> and adds an
entry for I<$host> with host key I<$host_key>. Dies if
I<$host_file> can't be opened for writing.

I<$host_key> should be an object of some subclass of
I<Net::SSH::Perl::Key>; in particular, it must support the
I<dump_public> object method.

=head2 _load_public_key($key_file)

Given the location of a public key file I<$key_file>, reads
the RSA public key from that file.

If called in list context, returns the key and the comment
associated with the key. If called in scalar context,
returns only the key.

Dies if: the key file I<$key_file> can't be opened for
reading; or the key file is "bad" (the ID string in the
file doesn't match the PRIVATE_KEY_ID_STRING constant).

Returns the RSA key (a I<Net::SSH::Perl::Key::RSA1> object).

=head2 _load_private_key($key_file [, $passphrase ])

Given the location of a private key file I<$key_file>,
and an optional passphrase to decrypt the key, reads the
private key from that file. If I<$passphrase> is not
supplied, an empty passphrase (the empty string) is tried
instead.

If called in list context, returns the key and the comment
associated with the key. If called in scalar context,
returns only the key.

Dies if: the key file I<$key_file> can't be opened for
reading; the key file is "bad" (the ID string in the file
doesn't match the PRIVATE_KEY_ID_STRING constant); the
file is encrypted using an unsupported encryption cipher;
or the passphrase I<$passphrase> is incorrect.

Returns the RSA key (a I<Net::SSH::Perl::Key::RSA1> object).

=head2 _save_private_key($key_file, $key, [ $passphrase [, $comment ]])

Given a private key I<$key>, and the location of the private
key file I<$key_file>, writes out an SSH1 RSA key file to
I<$key_file>.

If I<$passphrase> is supplied, the private key portion of
the file is encrypted with I<3DES> encryption, using the
passphrase I<$passphrase>. If the passphrase is not supplied,
an empty passphrase will be used instead. This is useful
when using RSA authentication in a non-interactive process,
for example.

I<$comment> is an optional string that, if supplied, is
inserted into the key file and can be used by clients when
prompting for the passphrase upon loading the private key,
etc. It should be somewhat descriptive of this key file.

I<$key> should be a I<Net::SSH::Perl::Key::RSA1> object.

=head2 _prompt($prompt [, $default [, $echo ]])

Emits an interactive prompt I<$prompt> with an optional
default I<$default>. If I<$echo> is true, reads normally
from I<STDIN>; if I<$echo> is false, calls
I<_read_passphrase> internally to read sensitive
information with echo off.

Returns the user's answer to the prompt, I<$default> if
no answer was provided.

=head2 _read_passphrase($prompt)

Uses I<Term::ReadKey> with echo off to read a passphrase,
after issuing the prompt I<$prompt>. Echo is restored
once the passphrase has been read.

=head2 _read_yes_or_no($prompt)

Issues the prompt I<$prompt>, which should be a yes/no
question; then reads the response, and returns true if the
response is yes (or rather, anything starting with 'y',
case insensitive).

=head2 _respond_to_rsa_challenge($ssh, $challenge, $key)

Decrypts the RSA challenge I<$challenge> using I<$key>,
then the response (MD5 of decrypted challenge and session
ID) to the server, using the I<$ssh> object, in an
RSA response packet.

=head2 _rsa_public_encrypt($data, $key)

Encrypts the multiple-precision integer I<$data> (a
I<Math::GMP> object) using I<$key>.

Returns the encrypted data, also a I<Math::GMP> object.

=head2 _rsa_private_decrypt($data, $key)

Decrypts the multiple-precision integer I<$data> (a
I<Math::GMP> object) using I<$key>.

Returns the decrypted data, also a I<Math::GMP> object.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
