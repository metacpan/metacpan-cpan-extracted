# $Id: RSA.pm,v 1.3 2001/04/17 00:55:19 btrott Exp $

package Net::SSH::Perl::Util::RSA;
use strict;
use warnings;

use Net::SSH::Perl::Constants qw( SSH_CMSG_AUTH_RSA_RESPONSE );
use Net::SSH::Perl::Util qw( :ssh1mp );

use Carp qw( croak );
use Digest::MD5 qw( md5 );
use Math::GMP;

sub _respond_to_rsa_challenge {
    my($ssh, $challenge, $key) = @_;

    $challenge = _rsa_private_decrypt($challenge, $key);
    my $buf = _mp_linearize($challenge, 32);
    my $response = md5($buf, $ssh->session_id);

    $ssh->debug("Sending response to host key RSA challenge.");

    my $packet = $ssh->packet_start(SSH_CMSG_AUTH_RSA_RESPONSE);
    $packet->put_chars($response);
    $packet->send;
}

sub _rsa_public_encrypt {
    my($input, $key) = @_;
    my $bits = Math::GMP::sizeinbase_gmp($input, 2);
    my $input_len = int(($bits + 7) / 8);
    my $len = int(($key->{rsa}{bits} + 7) / 8);

    my $aux = Math::GMP->new(2);
    for my $i (2..$len-$input_len-2) {
        my $byte = 0;
        {
            $byte = int rand 128;
            redo if $byte == 0;
        }
        $aux = Math::GMP::mul_2exp_gmp($aux, 8);
        Math::GMP::add_ui_gmp($aux, $byte);
    }
    $aux = Math::GMP::mul_2exp_gmp($aux, 8 * ($input_len + 1));
    $aux = Math::GMP->new($aux + $input);

    _rsa_public($aux, $key);
}

sub _rsa_public {
    my($input, $key) = @_;
    Math::GMP::powm_gmp($input, $key->{rsa}{e}, $key->{rsa}{n});
}

sub _rsa_private_decrypt {
    my($input, $key) = @_;
    my $output = _rsa_private($input, $key->{rsa});
    my $len = int(($key->{rsa}{bits} + 7) / 8);
    my $res = _mp_linearize($output, $len);
    unless (vec($res, 0, 8) == 0 && vec($res, 1, 8) == 2) {
        croak "Bad result from rsa_private_decrypt";
    }
    my $i;
    for ($i=2; $i<$len && vec($res, $i, 8); $i++) { }
    Math::GMP::mod_2exp_gmp($output, 8 * ($len - $i - 1));
}

sub _rsa_private {
    my($input, $key) = @_;
    my($dp, $dq, $p2, $q2, $k);

    $dp = $key->{d} % ($key->{p}-1);
    $dq = $key->{d} % ($key->{q}-1);

    $p2 = Math::GMP::powm_gmp($input % $key->{p}, $dp, $key->{p});
    $q2 = Math::GMP::powm_gmp($input % $key->{q}, $dq, $key->{q});

    $k = (($q2 - $p2) * $key->{u}) % $key->{q};
    $p2 + ($key->{p} * $k);
}

1;
