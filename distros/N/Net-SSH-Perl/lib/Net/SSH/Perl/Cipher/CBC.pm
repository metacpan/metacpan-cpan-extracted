# $Id: CBC.pm,v 1.6 2008/09/24 19:21:21 turnstep Exp $

# This code is based in part on the Systemics Crypt::CBC.
# Parts copyright (C) 1995, 1996 Systemics Ltd (http://www.systemics.com/)
# All rights reserved.

package Net::SSH::Perl::Cipher::CBC;
use strict;

sub new {
    my($class, $ciph, $iv) = @_;
    bless {
        cipher => $ciph,
        iv     => $iv || ("\0" x $ciph->blocksize),
    }, $class;
}

sub encrypt {
    my $cbc = shift;
    my $data = shift;

    my $retval = "";
    my $iv = $cbc->{iv};
    my $size = $cbc->{cipher}->blocksize;

    while (length $data) {
        my $in = substr($data, 0, $size, '') ^ $iv;
        $iv = $cbc->{cipher}->encrypt($in);
        $retval .= $iv;
    }

    $cbc->{iv} = $iv;
    $retval;
}

sub decrypt {
    my $cbc = shift;
    my $data = shift;

    my $retval = "";
    my $iv = $cbc->{iv};
    my $size = $cbc->{cipher}->blocksize;

    while (length $data) {
        my $in = substr($data, 0, $size, '');
        $retval .= $cbc->{cipher}->decrypt($in) ^ $iv;
        $iv = $in;
    }

    $cbc->{iv} = $iv;
    $retval;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::CBC - CBC Implementation

=head1 SYNOPSIS

    use Net::SSH::Cipher::CBC;
    my $cbc = Net::SSH::Cipher::CBC->new($cipher_obj);
    print $cbc->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::CBC> provides a CBC (cipher
block chaining) implementation for SSH encryption ciphers.

=head1 AUTHOR & COPYRIGHTS

This code is based in part on the I<Crypt::CBC> code
originally developed by Systemics Ltd.

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
