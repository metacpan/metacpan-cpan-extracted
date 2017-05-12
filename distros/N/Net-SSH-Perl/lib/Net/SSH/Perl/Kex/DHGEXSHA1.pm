package Net::SSH::Perl::Kex::DHGEXSHA1;
use strict;

use base qw( Net::SSH::Perl::Kex::DHGEX );
use Crypt::Digest::SHA1 qw( sha1 );

sub derive_key {
    my($kex, $id, $need, $hash, $shared_secret, $session_id) = @_;
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $b->put_mp_int($shared_secret);
    my $digest = sha1($b->bytes, $hash, chr($id), $session_id);
    for (my $have = 20; $need > $have; $have += 20) {
        $digest .= sha1($b->bytes, $hash, $digest);
    }
    $digest;
}

sub hash {
    my $kex = shift;
    sha1(shift);
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Kex::DHGEXSHA1 - Diffie-Hellman Group Exchange
using SHA1 hashing.

=head1 SYNOPSIS

    use Net::SSH::Perl::Kex;
    my $kex = Net::SSH::Perl::Kex->new;
    my $dh = bless $kex, 'Net::SSH::Perl::Kex::DHGEX1';

    $dh->exchange;

=head1 DESCRIPTION

I<Net::SSH::Perl::Kex::DHGEXSHA1> implements Diffie-Hellman Group
Exchange with SHA1 hashing for I<Net::SSH::Perl>. It is a subclass of
I<Net::SSH::Perl::Kex>.

=head1 AUTHOR & COPYRIGHTS

Lance Kinley E<lkinley@loyaltymethods.com>

Copyright (c) 2015 Loyalty Methods, Inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
