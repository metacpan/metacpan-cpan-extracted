package Net::SSH::Perl::Kex::DHGEXSHA256;
use strict;

use Net::SSH::Perl::Kex;
use base qw( Net::SSH::Perl::Kex::DHGEX );
use Crypt::Digest::SHA256 qw( sha256 );

sub derive_key {
    my($kex, $id, $need, $hash, $shared_secret, $session_id) = @_;
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $b->put_mp_int($shared_secret);
    my $digest = sha256($b->bytes, $hash, chr($id), $session_id);
    for (my $have = 32; $need > $have; $have += 32) {
        $digest .= sha256($b->bytes, $hash, $digest);
    }
    $digest;
}

sub hash {
    my $kex = shift;
    sha256(shift);
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Kex::DHGEXSHA256 - Diffie-Hellman Group Exchange
using SHA256 hashing.

=head1 SYNOPSIS

    use Net::SSH::Perl::Kex;
    my $kex = Net::SSH::Perl::Kex->new;
    my $dh = bless $kex, 'Net::SSH::Perl::Kex::DHGEX256';

    $dh->exchange;

=head1 DESCRIPTION

I<Net::SSH::Perl::Kex::DHGEXSHA256> implements Diffie-Hellman Group
Exchange with SHA256 hashing for I<Net::SSH::Perl>. It is a subclass
of I<Net::SSH::Perl::Kex>.

=head1 AUTHOR & COPYRIGHTS

Lance Kinley E<lkinley@loyaltymethods.com>

Copyright (c) 2015 Loyalty Methods, Inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
