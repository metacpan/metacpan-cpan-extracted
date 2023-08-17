package Net::SSH::Perl::Kex::DH1;

use strict;
use warnings;

use Carp qw( croak );
use Crypt::PK::DH;
use Crypt::Digest::SHA1 qw( sha1 );

use base qw( Net::SSH::Perl::Kex::DH );

sub group { 1 }
sub hash_len { 20 }

sub hash {
    my $kex = shift;
    sha1(join('',@_));
}

sub _dh_new_group {
    my $kex = shift;
    my $dh = Crypt::PK::DH->new;
    $dh->generate_key({g => 2, p => 'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE649286651ECE65381FFFFFFFFFFFFFFFF'});
    $dh;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Kex::DH1 - Diffie-Hellman Group 1 Key Exchange
(RFC2409 "Second Oakley Group" 1024-bit)

=head1 SYNOPSIS

    use Net::SSH::Perl::Kex;
    my $kex = Net::SSH::Perl::Kex->new;
    my $dh1 = bless $kex, 'Net::SSH::Perl::Kex::DH1';

    $dh1->exchange;

=head1 DESCRIPTION

I<Net::SSH::Perl::Kex::DH1> implements Diffie-Hellman Group 1 Key
Exchange for I<Net::SSH::Perl>. It is a subclass of
I<Net::SSH::Perl::Kex>.

Group 1 Key Exchange uses the Diffie-Hellman key exchange algorithm
to produce a shared secret key between client and server, without
ever sending the shared secret over the insecure network. All that is
sent are the client and server public keys.

I<Net::SSH::Perl::Kex::DH1> uses CryptX for the Diffie-Hellman
implementation. The I<p> value is set to

      FFFFFFFF FFFFFFFF C90FDAA2 2168C234 C4C6628B 80DC1CD1
      29024E08 8A67CC74 020BBEA6 3B139B22 514A0879 8E3404DD
      EF9519B3 CD3A431B 302B0A6D F25F1437 4FE1356D 6D51C245
      E485B576 625E7EC6 F44C42E9 A637ED6B 0BFF5CB6 F406B7ED
      EE386BFB 5A899FA5 AE9F2411 7C4B1FE6 49286651 ECE65381
      FFFFFFFF FFFFFFFF

And the generator I<g> is set to I<2>.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright, and
license information.

=cut
