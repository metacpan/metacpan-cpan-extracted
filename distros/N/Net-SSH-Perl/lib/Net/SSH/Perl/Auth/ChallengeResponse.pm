# $Id: ChallengeResponse.pm,v 1.3 2003/12/03 15:35:21 autarch Exp $

package Net::SSH::Perl::Auth::ChallengeResponse;
use strict;
use warnings;

use Net::SSH::Perl::Constants qw(
    SSH_CMSG_AUTH_TIS
    SSH_SMSG_AUTH_TIS_CHALLENGE
    SSH_CMSG_AUTH_TIS_RESPONSE
    SSH_SMSG_SUCCESS
    SSH_SMSG_FAILURE );

use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Util qw( _read_passphrase );
use Net::SSH::Perl::Auth;
use base qw( Net::SSH::Perl::Auth );

use Scalar::Util qw(weaken);

sub new {
    my $class = shift;
    my $ssh = shift;
    my $auth = bless { ssh => $ssh }, $class;
    weaken $auth->{ssh};
    $auth->enabled( $ssh->config->get('auth_ch_res') );
    $auth;
}

sub enabled {
    my $auth = shift;
    $auth->{enabled} = shift if @_;
    $auth->{enabled};
}

sub authenticate {
    my $auth = shift;
    my $ssh = $auth->{ssh};
    $ssh->debug("Password authentication is disabled by the client."), return
        unless $auth->enabled;

    $ssh->debug("Doing challenge response authentication.");
    for (1..$ssh->config->get('number_of_password_prompts')) {
        my $packet = $ssh->packet_start(SSH_CMSG_AUTH_TIS);
        $packet->send;

        $packet = Net::SSH::Perl::Packet->read($ssh);
        my $type = $packet->type;
        $ssh->fatal_disconnect("Protocol error in AUTH_TIS")
            unless $type == SSH_SMSG_FAILURE ||
                   $type == SSH_SMSG_AUTH_TIS_CHALLENGE;

        $ssh->debug("No challenge presented."), return
            unless $type == SSH_SMSG_AUTH_TIS_CHALLENGE;

        my $challenge = $packet->get_str;
        my $response = _read_passphrase($challenge);
        $packet = $ssh->packet_start(SSH_CMSG_AUTH_TIS_RESPONSE);
        $packet->put_str($response);
        $packet->send;

        $packet = Net::SSH::Perl::Packet->read($ssh);
        return 1 if $packet->type == SSH_SMSG_SUCCESS;

        $ssh->fatal_disconnect("Protocol error to AUTH_TIS response")
            unless $packet->type == SSH_SMSG_FAILURE;
    }

    return 0;
}

1;
