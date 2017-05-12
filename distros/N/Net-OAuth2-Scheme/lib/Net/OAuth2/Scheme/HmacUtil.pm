use warnings;
use strict;

package Net::OAuth2::Scheme::HmacUtil;
BEGIN {
  $Net::OAuth2::Scheme::HmacUtil::VERSION = '0.03';
}
# ABSTRACT: hash functions and encodings

use Digest::SHA ();
# use MIME::Base64 qw(encode_base64 decode_base64);

use parent qw(Exporter);
our @EXPORT_OK = qw(
  hmac_name_to_len_fn
  sign_binary        unsign_binary
  encode_base64url   decode_base64url
  encode_plainstring decode_plainstring
  timing_indep_eq
);

our @Known_HMACs =
 # list of [id, key_length, underscored_name, dashed-name, hmac_function]
(
 # NIST's HMAC-SHA functions
 map {[$_->[0], $_->[1], "hmac_sha$_->[2]", "hmac-sha$_->[2]"]}
 map {[$_%107, $_/8, ($_ == 160 ? 1 : $_)]}
 160,224,256,384,512,
 # add more keylengths here as NIST adds new ones
),
(
 # more families
);

# Why 107?
# Short answer:
# Why not?  Really all that matters is that no id get used twice
# and whatever we do to achieve that, nobody should care.
# Long answer:
# 107 is THE prime smaller than 128 for which the sequence 2^n mod p
# whose subsequences starting with 8 (= 256/32) and 12 (= 384/32)
# that do not contain either each other or 5 (=160/32) or 7 (=224/32)
# are of maximal length.  The idea being that we can keep adding new
# SHA functions of lengths 256*2^n, 384*2^n and not run into
# previously used ids for a VERY long time...
# OR (more likely) we'll be able to intersperse other families of
# secure hash functions (i.e., once SHA turns out to be inadequate
# for whatever reason) and likewise have plenty of room for those to
# grow, too, assuming those, too, start with key lengths of 256 and
# 384.  E.g., for the next family, you could do
#
#  map {[($_*13)%107, $_/8, "hmac_xxx$_", "hmac-xxx$_", \&whatever]}
#
# Note that all internal id numbers will thus be 106 or smaller, so
# if all else fails you can uses id bytes with the high-bit set to
# indicate some jackass extension scheme, though, hopefully, by that
# point we will have burned through so many families of secure hash
# functions that I will be safely dead and won't care anymore.
# Actually, I already don't care,  so...   --rfc


our %Known_HMACs_by_name = ( map {$_->[2],$_,$_->[3],$_} @Known_HMACs );
our %Known_HMACs_by_id = ( map {$_->[0],$_} @Known_HMACs );

die "looks like we used an id number twice"
  if 2 * keys %Known_HMACs_by_id != keys %Known_HMACs_by_name;

our $Default_HMAC = 'hmac_sha256';

sub hmac_name_to_len_fn {
    my ($aname) = @_;
    my $a = $Known_HMACs_by_name{$aname} or return ();
    return ($a->[1], _hmac_fn($a));
}

sub _hmac_fn {
    my $a = shift;
    return ($a->[4] ||= \&{"Digest::SHA::$a->[2]"});
}

sub _hmac_name_to_id_fn {
    my ($aname) = @_;
    my $a = $Known_HMACs_by_name{$aname} or
      Carp::croak("unknown hmac function: $aname");
    return ($a->[0], _hmac_fn($a));
}

sub _hmac_id_to_len_fn {
    my ($id) = @_;
    my $a = $Known_HMACs_by_id{$id} or return ();
    return ($a->[1], _hmac_fn($a));
}

sub timing_indep_eq {
    no warnings 'uninitialized';
    my ($x, $y, $len)=@_;
    warnings::warn('uninitialized','Use of uninitialized value in timing_indep_eq')
	if (warnings::enabled('uninitialized') && !(defined($x) && defined($y)));

    my $result=0;
    for (my $i=0; $i<$len; $i++) {
        $result |= ord(substr($x, $i, 1)) ^ ord(substr($y, $i, 1));
    }

    return !$result;
}

sub sign_binary {
    my ($secret, $value, %o) = @_;
    my $aname = $o{hmac} || $Default_HMAC;
    my ($id, $fn) = _hmac_name_to_id_fn($aname);
    my $extra = $o{extra};
    $extra = '' unless defined $extra;
    return pack 'ww/a*a*', $id, $fn->($secret, $value . $extra), $value;
}

sub unsign_binary {
    my ($secret, $bin, $extra) = @_;
    my ($id, $hash, $value) = unpack 'ww/a*a*', $bin;
    my ($keylen, $fn) = _hmac_id_to_len_fn($id) or
      return (undef, "unknown hash function id: $id");
    $extra = '' unless defined $extra;
    return ($value)
      if length($hash) == $keylen &&
        timing_indep_eq($hash, $fn->($secret, $value . $extra), $keylen);
    # implement extensions here but for now, just fail
    return (undef, 'bad hash value');
}

# base64url is described in RFC 4648: use - and _ in place of + and /
# and we leave off trailing =s, all so as not to use characters that
# are meaningful in URLs

sub encode_base64url {
     local $_ = join '' , map {pack 'B6',$_} ((unpack 'B*',shift).'0000') =~ m/(.{6})/gs;
     y(\0\4\10\14\20\24\30\34\40\44\50\54\60\64\70\74\100\104\110\114\120\124\130\134\140\144\150\154\160\164\170\174\200\204\210\214\220\224\230\234\240\244\250\254\260\264\270\274\300\304\310\314\320\324\330\334\340\344\350\354\360\364\370\374)(A-Za-z0-9\-_);
#    local $_ = encode_base64(shift,'');
#    y|+/=|-_|d;
     return $_;
}

sub decode_base64url {
    local $_ = shift;
    y(A-Za-z0-9\-_)(\0\4\10\14\20\24\30\34\40\44\50\54\60\64\70\74\100\104\110\114\120\124\130\134\140\144\150\154\160\164\170\174\200\204\210\214\220\224\230\234\240\244\250\254\260\264\270\274\300\304\310\314\320\324\330\334\340\344\350\354\360\364\370\374);
    return pack 'B'. (((3*length)>>2)<<3) , join '', unpack 'B6'x(length), $_;

#   # for some reason this is way faster than:
#   y|-_=|+/|d;
#   return decode_base64($_ . substr('===',(3+length)>>2))
}

# plainstring is printable ascii excluding whitespace, backslash,
# and double quote (- 128 32 1 1 1 1)
sub encode_plainstring {
    my @ords = ();
    my $m = (length($_[0])+2) % 3 + 1;
    for my $c (split '', $_[0]) {
        my @ords2 = (ord($c), (map {$_*2} @ords));
        for my $i (0 .. $#ords) {
            $ords[$i] = 72*$ords[$i] + $ords2[$i];
        }
        push @ords, $ords2[$#ords2];
        my $rc = 0;
        unless (--$m) {
            $m = 3;
            for my $i (0 .. $#ords) {
                use integer;
                $ords[$i] += $rc;
                $rc = $ords[$i]/92;
                $ords[$i] %= 92;
            }
            while ($rc > 0) {
                use integer;
                push @ords, $rc % 92;
                $rc /= 92;
            }
        }
    }
    return join '', map {$_ >= 58 ? chr($_+35) : ($_ >= 1 ? chr($_+34) : '!')} @ords;
}

# 33, 35..91 93..126
# 0    1..57 58..92

sub decode_plainstring {
    my @ords = ();
    for my $c (reverse split '', $_[0]) {
        @ords = map {$_*92} @ords;
        my $o = ord($c);
        $ords[0] += ($o >= 93 ? $o-35 : $o >= 35 ? $o-34 : 0);
        my $rc = 0;
        for my $i (0 .. $#ords) {
            use integer;
            $ords[$i] += $rc;
            $rc = $ords[$i]>>8;
            $ords[$i] &= 255;
        }
        while ($rc > 0) {
            use integer;
            push @ords, $rc & 255;
            $rc >>= 8;
        }
    }
    return join '', map {chr($_)} reverse @ords;
}

1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::HmacUtil - hash functions and encodings

=head1 VERSION

version 0.03

=head1 DESCRIPTION

internal module.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

