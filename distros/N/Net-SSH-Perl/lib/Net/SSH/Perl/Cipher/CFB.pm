# $Id: CFB.pm,v 1.5 2001/04/03 19:44:47 btrott Exp $

# This code based in part on the Systemics Crypt::CFB.
# Parts Copyright (C) 1995, 1996 Systemics Ltd (http://www.systemics.com/)
# All rights reserved.

package Net::SSH::Perl::Cipher::CFB;
use strict;
use warnings;

sub new {
    my($class, $ciph, $iv) = @_;
    bless {
        cipher    => $ciph,
        iv        => $iv || ("\0" x $ciph->blocksize),
    }, $class;
}

sub encrypt {
    my $cfb = shift;
    my $data = shift;

    my $retval = "";
    my $iv = $cfb->{iv};
    my $size = $cfb->{cipher}->blocksize;

    while (length $data) {
        my $out = $cfb->{cipher}->encrypt($iv);
        $iv = substr($data, 0, $size, '') ^ substr($out, 0, $size, '');
        $retval .= $iv;
    }

    $cfb->{iv} = $iv;
    $retval;
}

sub decrypt {
    my $cfb = shift;
    my $data = shift;

    my $retval = "";
    my $iv = $cfb->{iv};
    my $size = $cfb->{cipher}->blocksize;

    while (length $data) {
        my $out = $cfb->{cipher}->encrypt($iv);
        $iv = substr($data, 0, $size, '');
        $retval .= $iv ^ substr($out, 0, $size);
    }

    $cfb->{iv} = $iv;
    $retval;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::CFB - CFB Implementation

=head1 SYNOPSIS

    use Net::SSH::Cipher::CFB;
    my $cbc = Net::SSH::Cipher::CFB->new($cipher_obj);
    print $cbc->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::CFB> provides a CFB (cipher
feedback) implementation for SSH encryption ciphers.

=head1 AUTHOR & COPYRIGHTS

This code is based in part on the I<Crypt::CFB> code
originally developed by Systemics Ltd.

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
