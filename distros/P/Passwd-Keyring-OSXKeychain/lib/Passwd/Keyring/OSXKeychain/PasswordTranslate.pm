package Passwd::Keyring::OSXKeychain::PasswordTranslate;

use warnings;
use strict;
use base 'Exporter';
our @EXPORT_OK = qw(read_security_encoded_passwd);

use Encode;

=head1 NAME

Passwd::Keyring::OSXKeychain::PasswordTranslate

=head1 DESCRIPTION

Helper routines, responsible for encoding and decoding passwords from
MacOS/X security escaped forms. Used internally inside Passwd::Keyring::OSXKeychain.

=head2 read_security_encoded_passwd

Tries to decode password given by security -w, handling known escaping schemes.

=cut

sub read_security_encoded_passwd {
    my ($encoded_password) = @_;

    # See discussion from #1 (especially comments by Maroš Kollár).
    # We must detect whether password is plaintext or hex-encoded,
    # and possibly truncate it.

    unless($encoded_password =~ /^(?:[0-9a-f][0-9a-f])+$/ix) {
        # surely plaintext as non-hex is there
        return $encoded_password;
    }

    # Heuristics suggested by Maroš, and slightly extended by me to handle
    # additinal cases.
    if($encoded_password =~ /00$/
       || $encoded_password =~ /ffffff.*ffffff/
       # || length($encoded_password) > 30
      ) {
        # Hex
        my $binary = pack('H*', $encoded_password);
        $binary =~ s{\xFF{3}}{}g;
        $binary =~ s/\x00.*$//;  # Cutting post binary zero part
        my $text = decode_utf8($binary);
        $text =~ s{\n.*}{};      # Cuttint newline broken part
        return $text;
    }

    # By default we assume plain text
    return $encoded_password;
}




1;
