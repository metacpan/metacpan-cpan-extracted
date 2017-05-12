package Net::SSH::Perl::Cipher::AES128_CBC;

use base qw( Net::SSH::Perl::Cipher::AES_CBC );
use strict;

sub keysize { 16 } # 128 bits

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::AES128 - Wrapper for SSH AES128 CBC support

=head1 SYNOPSIS

    use Net::SSH::Perl::Cipher;
    my $cipher = Net::SSH::Perl::Cipher->new('AES128_CBC', $key);
    print $cipher->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::AES128_CBC> provides AES128 encryption
support for I<Net::SSH::Perl>. To do so it wraps around
I<Crypt::OpenSSL::AES>, a C/XS wrapper of the OpenSSL AES
library functions.

=head1 AUTHOR & COPYRIGHTS

Lance Kinley E<lkinley@loyaltymethods.com>

Copyright (c) 2015 Loyalty Methods, Inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
