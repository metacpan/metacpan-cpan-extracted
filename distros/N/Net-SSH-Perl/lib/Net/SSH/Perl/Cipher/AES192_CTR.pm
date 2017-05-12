package Net::SSH::Perl::Cipher::AES192_CTR;

use base qw( Net::SSH::Perl::Cipher::AES_CTR );
use strict;

sub keysize { 24 } # 192 bits

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::AES192 - Wrapper for SSH AES192 support

=head1 SYNOPSIS

    use Net::SSH::Perl::Cipher;
    my $cipher = Net::SSH::Perl::Cipher->new('AES192_CTR', $key);
    print $cipher->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::AES192_CTR> provides AES192 encryption
support for I<Net::SSH::Perl>. To do so it wraps around
I<Crypt::OpenSSL::AES>, a C/XS wrapper of the OpenSSL AES
library functions.

=head1 AUTHOR & COPYRIGHTS

Lance Kinley E<lkinley@loyaltymethods.com>

Copyright (c) 2015 Loyalty Methods, Inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
