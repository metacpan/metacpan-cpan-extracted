package Net::SSH::Perl::Cipher::CTR;
use strict;

sub new {
    my($class, $ciph, $iv) = @_;
    bless {
        cipher => $ciph,
        iv => substr($iv,0,$ciph->blocksize) || "\0" x $ciph->blocksize,
    }, $class;
}

sub encrypt {
    my $ctr = shift;
    my $data = shift;

    my $retval = '';
    my $iv = $ctr->{iv};
    my $size = $ctr->{cipher}->blocksize;

    while (length $data) {
        my $in = substr($data, 0, $size, '');
        $in ^= $ctr->{cipher}->encrypt($iv);
        for my $i (1..$size) {
            my $num = (unpack('C', substr($iv,-$i,1)) + 1) & 0xff;
            substr($iv,-$i,1,pack('C',$num));
            last if $num;
        }
        $retval .= $in;
    }
    $ctr->{iv} = $iv;
    $retval;
}

sub decrypt { shift->encrypt(@_) }

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::CTR - Counter Mode Implementation

=head1 SYNOPSIS

    use Net::SSH::Cipher::CTR;
    my $ctr = Net::SSH::Cipher::CTR->new($cipher_obj);
    print $ctr->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::CTR> provides a CTR (counter
mode) implementation for SSH encryption ciphers.

=head1 AUTHOR & COPYRIGHTS

Lance Kinley E<lkinley@loyaltymethods.com>

Copyright (c) 2015 Loyalty Methods, Inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
