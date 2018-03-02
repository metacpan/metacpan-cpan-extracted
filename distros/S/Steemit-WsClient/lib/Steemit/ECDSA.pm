package Steemit::ECDSA;
use Modern::Perl;
use Math::EllipticCurve::Prime;
use Digest::SHA;
use Carp;

my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');


sub ecdsa_sign {
  my( $message, $key ) = @_;
  my $n = $curve->n; my $nlen = length($n->as_bin);
  require Bytes::Random::Secure;
  my $random = Bytes::Random::Secure->new( Bits => 128 );
  my $sha256 = Digest::SHA::sha256( $message );
  my $z = Math::BigInt->new(substr(Math::BigInt->from_bytes($sha256)->as_bin,0,$nlen));
  my $N_OVER_TWO = $n->copy->brsft(1);

  my $is_canonical;
  my ($k, $r, $s, $i ) = map {Math::BigInt->new($_) }(0,0,0);
  while( not $is_canonical ){
     until ($s and length( $s->to_bytes ) == 32 ) {
       until ($r and length( $r->to_bytes) == 32 ) {
         $k = Math::BigInt->from_bin($random->string_from('01',$nlen-2)) until $k > 1 and $k < $n;
         my $point = $curve->g->multiply($k);
         $r = $point->x->bmod($n);
       }
       $s = (($z + $key * $r) * $k->bmodinv($n))->bmod($n);
     }

     if( $s > $N_OVER_TWO ){
        $s = $n - $s;
     }


     $i = calcPubKeyRecoveryParam($message, $r, $s, get_public_key_point( $key ) );
     $is_canonical = is_signature_canonical_canonical(
        join(
           '',
           map {$_->to_bytes}
           ( $i + 27 + 4),$r,$s
        )
     );
     unless( $is_canonical ){
        ($k, $r, $s, $i ) = map {Math::BigInt->new($_) }(0,0,0);
     }

  }

  return ( $r, $s, $i );
}

sub is_signature_canonical_canonical{
   my( $c ) = @_;
   #https://github.com/steemit/steem/blob/2945196ca5ead5049e78679d69affea98d97e27b/libraries/fc/src/crypto/elliptic_common.cpp#L171
   return !(unpack("xC",$c) & 0x80)
   && !( unpack("xC",$c) == 0 && !( unpack("x[2]C",$c) & 0x80))
   && !( unpack("x[33]C",$c) & 0x80)
   && !( unpack("x[33]C",$c) == 0 && !( unpack("x[34]C",$c) & 0x80));
   return 1
}

sub bytes_32_sha256 {
  my ( $message ) = @_;
  my $sha256 = Digest::SHA::sha256( $message );
  my $n = $curve->n; my $nlen = length($n->as_bin);
  my $z = Math::BigInt->new(substr(Math::BigInt->from_bytes($sha256)->as_bin,0,$nlen));
  return $z;
}

sub ecdsa_verify {
   my ($message, $pubkey, $r, $s) = @_;
   my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');
   my $n = $curve->n;
   return unless $r > 0 and $r < $n and $s > 0 and $s < $n;

   my $nlen  = length($n->as_bin);
   my $sha256 = Digest::SHA::sha256( $message );
   my $z = Math::BigInt->new(substr(Math::BigInt->from_bytes($sha256)->as_bin,0,$nlen));

   my $w = $s->copy->bmodinv($n);
   my $u1 = ($w * $z)->bmod($n); my $u2 = ($w * $r)->bmod($n);
   my $x1 = $curve->g->multiply($u1)->add($pubkey->multiply($u2))->x->bmod($n);
   return $x1 == $r;
}


sub calcPubKeyRecoveryParam {
  my ( $message, $r, $s, $Q ) = @_;
  for ( my $i = 0; $i < 4; $i++ ){
     my $Qprime = recoverPubKey($message,$r,$s,$i);
     if( $Qprime->x == $Q->x and $Qprime->y == $Q->y ){
       return Math::BigInt->new($i);
     }
  }

  die ('Unable to find valid recovery factor')
}


sub recoverPubKey {
  my ( $message, $r, $s, $i ) = @_;

  $i //= 0;
  my $e = bytes_32_sha256($message );
  die "i must be 0 <= i < 4" unless $i >= 0 and $i < 4;

  my $n = $curve->n;
  my $G = $curve->g;

  die "invalid r" if $r < 0 or $r > $n;
  die "invalid s" if $s < 0 or $s > $n;

  my $isYOdd = ( $i == 1 or $i == 3 );

  my $isSecondKey = $i > 2;

  my $x = $isSecondKey ? ( $r + $n ) : $r;
  my $R = point_from_x( $r, $isYOdd );

  my $nR = $R->multiply( $n );
  die "nR is not a valid curve point " unless $nR->infinity;

  my $eNeg = $e->copy->bneg->bmod($n);

  my $rInv = $r->copy->bmodinv($n);

  my $Q = $R->multiply( $s )->badd( $G->multiply($eNeg) )->multiply( $rInv );

  return $Q;
}

sub get_compressed_public_key {
   my( $key ) = @_;

   my $Q = get_public_key_point( $key );
   my $buffer;

   if( $Q->y % 2 ){
      $buffer = pack 'C', 0x03;
   }else{
      $buffer = pack 'C', 0x02;
   }

   $buffer .= pack( 'H*', "0" x (( length($curve->p->to_bytes) - length($Q->x->to_bytes) ) * 2 ));
   $buffer .= $Q->x->to_bytes;

   return $buffer;
}

sub get_recovery_factor {
   my ( $x,$y ) = @_;
   my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');
   my ($p, $a, $b) = ($curve->p, $curve->a, $curve->b);
   $x = $x->copy;
   $y = $y->copy;

   my $yr = ($x->bmodpow(3,$p)+$a*$x+$b)->bmodpow(($p+1)/4,$p);
   if( $y eq $yr ){
      return $yr%2;
   }
   $yr = $p - $y;
   if( $y eq $yr ){
      return ( $yr%2 + 1 ) % 2;
   }
   confess "unable to determine recovery factor";
}

sub point_from_x {
   my ( $x,$i ) = @_;
   my $y = recover_y( $x, $i );
   return Math::EllipticCurve::Prime::Point->new(
      x => $x,
      y => $y,
      curve => $curve
   );
}

sub recover_y {
   my ( $x,$i ) = @_;
   my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');
   my ($p, $a, $b) = ($curve->p, $curve->a, $curve->b);
   $x = $x->copy;

   my $y = ($x->bmodpow(3,$p)+$a*$x+$b)->bmodpow(($p+1)/4,$p);

   $y = $p - $y if $i%2 ne $y%2;
   return $y;
}


sub get_public_key_point {
   my( $key ) = @_;

   die "key needs to be a Math::BigInt Object " unless( $key->isa('Math::BigInt') );

   my $public_key = $curve->g->multiply( $key );

   return $public_key;
}
1;


__END__

=head1 NAME

Steemit::ECDSA - perl library wich implements ecda helper methods used by the Steemit::WsClient distribution

=head1 SYNOPSIS

   use Steemit::ECDSA;

   my ( $r, $s, $i ) = Steemit::ECDSA::ecdsa_sign( $message, Math::BigInt->from_bytes( $plain_secret_key) );

   my $pubkey = Steemit::ECDSA::recoverPubKey($message, $r, $s, $i )

   Steemit::ECDSA::ecdsa_verify( $message, $pubkey, $r, $s) or die "invalid signature";





=head1 SUBROUTINES/METHODS


=head2    is_signature_canonical_canonical($binary_signature)

accepts a binary representation of ($i+27+4).$r.$s and will check for a canonical signature
its internaly used and canonical signatures are important for security, and enforced by teh server

=head2    bytes_32_sha256 {

take a message and return the 32 most significant bytes from the scha256 hash

=head2    calcPubKeyRecoveryParam {

internaly used to determine the parameter that lets us recalculate the public key from the signature

=head2    recoverPubKey {

recover the signature

=head2    get_compressed_public_key {

transform the x and y based coordinates from a public key to only teh x and a parameter wich defines whether y is even or odd

=head2    get_recovery_factor {

get the parameter needed by the above method

=head2    point_from_x {

get the point on the curve wich coresponds to a point x and a recovery factor

=head2    recover_y {

get only the y coorinate of the point

=head2    get_public_key_point {

take a key and get the public key for it as point


=head1 REPOSITORY

L<https://github.com/snkoehn/perlSteemit>


=head1 AUTHOR

snkoehn, C<< <snkoehn at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-steemit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Steemit::WsClient>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Steemit::ECDSA


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Steemit::WsClient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Steemit::WsClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Steemit::WsClient>

=item * Search CPAN

L<http://search.cpan.org/dist/Steemit::WsClient/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 snkoehn.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut







