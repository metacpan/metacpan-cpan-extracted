package Mojolicious::Plugin::YubiVerify;

#
# Copyright (c) by Kirill Miazine <km@krot.org>
#
# This software is distributed under an ISC-style license, please see
# <http://km.krot.org/code/license.txt> for details.
#

use strict;
use warnings;
use base 'Mojolicious::Plugin';

our $VERSION = '0.06';

use Mojo::UserAgent;
use URI::Escape qw(uri_escape);
use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::HMAC_SHA1 qw(hmac_sha1); # Mojo::Util's hmac_sha1_sum gives HEX
use String::Random qw(random_string);
use List::Util qw(shuffle);

use constant API_ID => 1851;                            # API id and API key are "borrowed" from
use constant API_KEY => 'oBVbNt7IZehZGR99rvq8d6RZ1DM='; # http://demo.yubico.com/php-yubico/demo.php
use constant API_URLS => map { sprintf('http://api%s.yubico.com/wsapi/2.0/verify', $_) } ('', 2..5);
use constant PARALLEL => 2;
use constant STATUSMAP => (
    OK => 'The OTP is valid.',
    BAD_OTP => 'The OTP is invalid format.',
    REPLAYED_OTP => 'The OTP has already been seen by the service.',
    BAD_SIGNATURE => 'The HMAC signature verification failed.',
    MISSING_PARAMETER => 'The request lacks a parameter.',
    NO_SUCH_CLIENT => 'The request id does not exist.',
    OPERATION_NOT_ALLOWED => 'The request id is not allowed to verify OTPs.',
    BACKEND_ERROR => 'Unexpected error in our server. Please contact us if you see this error.',
    NOT_ENOUGH_ANSWERS => 'Server could not get requested number of syncs during before timeout.',
    REPLAYED_REQUEST => 'Server has seen the OTP/Nonce combination before.',
);

sub register {
    my ($plugin, $app, $conf) = @_;

    $conf->{'api_id'}   ||= API_ID;
    $conf->{'api_key'}  ||= API_KEY;
    $conf->{'parallel'} ||= PARALLEL;

    $app->helper(
        yubi_verify => sub {
            my $self = shift;
            my $otp = shift or return;
            my $ret_res = shift; # for testing

            my $ua = Mojo::UserAgent->new;
            my $nonce = random_string('c' x 40);
            my $query_string = _signedq(
                $conf->{'api_key'},
                id => $conf->{'api_id'},
                otp => $otp,
                nonce => $nonce,
                timestamp => 1,
                sl => 42,
                timeout => undef,
            );
            my @res = grep { ref($_) eq 'HASH' and defined $_->{'status'} }
                      map { {_resp2p($_->res->body)} }
                      grep { $_->res->code and $_->res->code == 200 }
                      map { $ua->get("$_?$query_string") }
                          (shuffle(API_URLS))[0..($conf->{'parallel'}-1)];

            for my $res (@res) {
                next if $res->{'status'} ne 'OK';
                next if !defined $res->{'otp'} or $res->{'otp'} ne $otp;
                next if !defined $res->{'nonce'} or $res->{'nonce'} ne $nonce;
                my ($key_id) = ($res->{'otp'} =~ /^(.+)(.{32})$/);
                my $h = delete $res->{'h'};
                return ($key_id, ($ret_res ? \@res : ()))
                    if $res->{'status'} eq 'OK' and $h eq
                                                    _b64hmacsig(_sortedq(%{$res}),
                                                                decode_base64($conf->{'api_key'}));
            }

            return (undef, ($ret_res ? \@res : ()))
        }
    );
}

sub _sortedq {
    my %p = @_; join('&', map { join('=', $_, uri_escape($p{$_}, '^A-Za-z0-9:._~-')) }
                               sort grep { defined $p{$_} } keys %p);
}

sub _b64hmacsig {
    encode_base64(hmac_sha1(@_), '');
}

sub _signedq {
    my $key = shift;
    my $q = _sortedq(@_);
    # avoid BAD_SIGNATURE,
    # as in http://code.google.com/p/php-yubico/source/browse/trunk/Yubico.php
    (my $h = _b64hmacsig($q, decode_base64($key))) =~ s/\+/%2B/g;
    return "$q&h=$h";
}

sub _resp2p {
    my $p = {map { split /=/, $_, 2 } grep { /=/ } split /\r?\n/, $_[0]};
    return map { $_ => $p->{$_} } qw(otp nonce h t status timestamp sessioncounter sessionuse sl);
}

42;

__END__

=head1 NAME

Mojolicious::Plugin::YubiVerify - Verify YubiKey one time passwords.

=head1 DESCRIPTION

L<Mojolicous::Plugin::YubiVerify> verifies YubiKey one time passwords. The
library implements YubiKey Validation Protocol version 2.0 as described here:

http://code.google.com/p/yubikey-val-server-php/wiki/ValidationProtocolV20

This library will query following servers: api.yubico.com, api2.yubico.com,
api3.yubico.com, api4.yubico.com and api5.yubico.com. User may wish to use all
- or only some - of the servers. If number of servers to query is lower than 5,
then the server(s) to query will be selected randomly.

=head1 USAGE

Yubico API key and API id are required and must be obtained prior to using this module.
http://api.yubico.com/get-api-key/

yubi_verify(<otp>) helper function takes one time password as its argument and returns
the id associated with the one time password if authentication was successful.

Below is a usage example togehter with basic_auth. Note that if using one time passwords
with basic auth, you have to set some session parameter if initial authentication was
successful. Don't forget to expire it!

    use Mojolicious::Lite;

    app->plugin('basic_auth');
    app->plugin('yubi_verify',
      api_id => '...',  # API id
      api_key => '...', # API key
      parallel => 3,    # number of servers to query
    );

    get '/' => sub {
        my $self = shift;

        return $self->render(text => "yubikey id is @{[$self->session->{'yubi'}]}")
          if $self->basic_auth(
                  realm => sub { return 1 if $self->session->{'yubi'};
                                 return 1 if $self->session->{'yubi'} =
                                             $self->yubi_verify($_[1])  }
          );
    };

    app->start;

=head1 METHODS

L<Mojolicious::Plugin::YubiVerify> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register condition in L<Mojolicious> application. Please see USAGE above for arguments.

=head1 SEE ALSO

L<Mojolicious>

=head1 VERSION

0.01

=head1 AUTHOR

Kirill Miazine km@krot.orgrg

=cut
