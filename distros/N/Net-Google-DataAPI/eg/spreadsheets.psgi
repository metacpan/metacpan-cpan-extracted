use strict;
use warnings;
use lib 'lib';
use Amon2::Lite;
use Amon2::Util;
use Net::Google::DataAPI::Auth::OAuth2;
use Net::Google::Spreadsheets;

=pod

=head1 NAME

spreadsheets.psgi - sample web app using google spreadsheets with OAuth 2.0

=head1 SYNOPSIS

  CLIENT_ID=your_google_api_client_id CLIENT_SECRET=your_google_api_client_secret plackup eg/spreadsheets.psgi

=head1 DEPENDENCY

you need to have Amon2::Lite and Net::Google::Spreadsheets distributions in your box.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

https://developers.google.com/accounts/docs/OAuth2

=cut

sub oauth2 {
    my $state = shift || '';
    Net::Google::DataAPI::Auth::OAuth2->new(
        client_id => $ENV{CLIENT_ID},
        client_secret => $ENV{CLIENT_SECRET},
        redirect_uri => 'http://localhost:5000/callback',
        scope => ['http://spreadsheets.google.com/feeds/'],
        state => $state,
    );
}

get '/' => sub {
    my ($c) = @_;
    my @ss;
    if (my $token = $c->session->get('token')) {
        my $oauth2 = oauth2();
        $oauth2->access_token($token);
        @ss = Net::Google::Spreadsheets->new(auth => $oauth2)->spreadsheets;
    }
    return $c->render('index.tt', {ss => \@ss});
};

get '/login' => sub {
    my ($c) = @_;
    my $state = Amon2::Util::random_string(30);
    $c->session->set(state => $state);
    $c->redirect(oauth2($state)->authorize_url());
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
    my $state = $c->session->get('state')
        or return $c->redirect($c->uri_for('/'));
    $c->req->param('state') eq $state
        or return $c->res_403;
    my $oauth2 = oauth2();
    my $at = $oauth2->get_access_token($code)
        or return $c->res_403;
    $c->session->set(token => $at);
    $c->redirect($c->uri_for('/'));
};

__PACKAGE__->enable_session();
__PACKAGE__->to_app;

__DATA__

@@ index.tt
<html>
<body>
[% IF c().session.get('token') %]
<ul>
[% FOR i IN $ss %]
<li>[% i.title() %]</li>
[% END %]
</ul>
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

