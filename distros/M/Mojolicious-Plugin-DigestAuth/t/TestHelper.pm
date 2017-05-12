package TestHelper;

use strict;
use warnings;
use base 'Exporter';

use Mojolicious::Lite;
use Mojolicious::Plugin::DigestAuth::Util qw{checksum parse_header};

our @EXPORT = qw{build_auth_request users create_action IE6};

my $users = { sshaw => 'itzme!' };
sub users { $_[0] ? $users->{$_[0]} : $users }
sub IE6 { 'Mozilla/5.0 (compatible; MSIE 6.0; Windows NT 5.1)' }

sub create_action
{
    my $options = { @_ };
    $options->{allow} ||= users();

    my $env = delete $options->{env} || {};
    sub {
        my $self = shift;
        $self->app->plugin('digest_auth', $options);
        $self->req->env($env);
        $self->render(text => "You're in!") if $self->digest_auth;
    };
}

# This fx() should use the same code as DigestAuth!
sub build_auth_request
{
    my ($tx, %defaults) = @_;
    my $req_header = parse_header($tx->res->headers->www_authenticate);
    my $res_header = {};
    my $user = delete $defaults{username};
    my $pass = delete $defaults{password};
    my @common_parts = qw{algorithm nonce opaque realm};

    $user = 'sshaw' if !defined $user;
    $pass = users($user) || '' if !defined $pass;

    @$res_header{@common_parts, keys %defaults} = (@$req_header{@common_parts}, values %defaults);

    # Test::Mojo handles the url differently between versions
    # What versions? Is this still necessary, maybe it was pre 1.32?
    if(!defined $res_header->{uri}) {
        $res_header->{uri} = $tx->req->url->path->to_string;
        $res_header->{uri} .= '?' . $tx->req->url->query if $tx->req->url->query->to_string;
    }

    $res_header->{nc} ||= 1;
    $res_header->{cnonce} ||= time();
    $res_header->{qop} ||= 'auth';
    $res_header->{username} = $user;
    $res_header->{response} = checksum(checksum($user, $res_header->{realm}, $pass),
                                       $res_header->{nonce},
                                       $res_header->{nc},
                                       $res_header->{cnonce},
                                       $res_header->{qop},
                                       checksum($tx->req->method, $res_header->{uri}));

    { Authorization => sprintf('Digest %s', join ', ', map { qq|$_="$res_header->{$_}"| } keys %$res_header) };
}

1;
