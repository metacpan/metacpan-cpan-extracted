# $Id: SSH1MP.pm,v 1.3 2001/04/17 00:55:19 btrott Exp $

package Net::SSH::Perl::Util::SSH1MP;
use strict;
use warnings;

use Digest::MD5 qw( md5 );
use Math::GMP;

sub _compute_session_id {
    my($check_bytes, $host, $public) = @_;
    my $id;
    $id .= _mp_linearize($host->{rsa}{n});
    $id .= _mp_linearize($public->{rsa}{n});
    $id .= $check_bytes;
    md5($id);
}

sub _mp_linearize {
    my($p, $l) = @_;
    $l ||= 0;
    my $base = Math::GMP->new(256);
    my $res = '';
    {
        my $r = $p % $base;
        my $d = Math::GMP->new($p-$r) / $base;
        $res = chr($r) . $res;
        if ($d >= $base) {
            $p = $d;
            redo;
        }
        elsif ($d != 0) {
            $res = chr($d) . $res;
        }
    }
    $res = "\0" x ($l-length($res)) . $res
        if length($res) < $l;
    $res;
}

1;
