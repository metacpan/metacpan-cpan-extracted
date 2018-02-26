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
