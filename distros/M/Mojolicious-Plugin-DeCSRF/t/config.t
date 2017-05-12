use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

use lib 'lib';

plugin 'DeCSRF' => {
	on_mismatch => sub {
		shift->render(template => '503', status => 503);
	},
	token_length => 8,
	token_name => 'csrf',
	urls => qw~/protected~
};

my $token;

app->mode('production');

app->hook(after_render => sub {
		my $self = shift;
		$token = $self->session->{csrf};
	}
);

get '/' => sub {
	my $self = shift;
} => 'index';

get '/protected' => sub {
	my $self = shift;
} => 'protected';

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)
	->content_like(qr~^/protected\?csrf=\S{8}\n$~);
$t->get_ok('/protected?csrf=****')->status_is(503)
	->content_is("Service error!\n");
$t->get_ok('/protected?csrf=' . $token)->status_is(200)
	->content_is("/\n");

done_testing();
__DATA__
@@ protected.html.ep
<%= decsrf->url('index') %>
@@ index.html.ep
<%= decsrf->url('protected') %>
@@ 503.html.ep
Service error!
