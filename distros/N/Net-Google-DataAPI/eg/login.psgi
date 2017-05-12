use strict;
use warnings;
use lib 'lib';
use Amon2::Lite;
use Net::Google::DataAPI::Auth::OAuth2;
use Data::Dumper;

=pod

=head1 NAME

login.psgi - sample web app for Google OpenID Connect login

=head1 SYNOPSIS

  CLIENT_ID=your_google_api_client_id CLIENT_SECRET=your_google_api_client_secret plackup eg/login.psgi

=head1 DEPENDENCY

you need to have Amon2::Lite distribution in you box.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

http://code.google.com/intl/ja-JP/apis/accounts/docs/OAuth2.html

=cut

sub oauth2 {
    Net::Google::DataAPI::Auth::OAuth2->new(
        client_id => $ENV{CLIENT_ID},
        client_secret => $ENV{CLIENT_SECRET},
        redirect_uri => 'http://localhost:5000/callback',
    );
}

get '/' => sub {
    my ($c) = @_;
    return $c->render('index.tt');
};

get '/login' => sub {
    my ($c) = @_;
    $c->redirect(oauth2()->authorize_url());
};

get '/logout' => sub {
    my ($c) = @_;
    $c->session->expire;
    $c->redirect($c->uri_for('/'));
};

get '/callback' => sub {
    my ($c) = @_;
    if ($c->req->param('error')) {
        return $c->render('error.tt');
    } 
    my $code = $c->req->param('code')
        or return $c->redirect($c->uri_for('/'));
    my $oauth2 = oauth2();
    my $at = $oauth2->get_access_token($code)
        or $c->return_403;
    my $info = $oauth2->userinfo;
    $c->session->set(user => $info);
    $c->redirect($c->uri_for('/'));
};

__PACKAGE__->enable_session();
__PACKAGE__->to_app;

__DATA__

@@ index.tt
<html>
<body>
[% IF $u = c().session().get('user') %]
<img src="[% $u.picture %]">
<a href="[% uri_for('/logout') %]">logout</a>
[% ELSE %]
<a href="[% uri_for('/login') %]">login</a>
[% END %]
</body>
</html>

@@ error.tt
<html>
<body>i'm sorry</body>
</html>
