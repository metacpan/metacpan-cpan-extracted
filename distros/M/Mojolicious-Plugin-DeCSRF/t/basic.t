use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

use lib 'lib';

plugin 'DeCSRF';

my $token;

app->mode('production');

app->hook(after_render => sub {
		my $self = shift;
		$token = $self->session->{token};
	}
);

get '/' => sub {
	my $self = shift;
} => 'index';

get '/protected' => sub {
	my $self = shift;
} => 'protected';

get '/url_with_placeholders/:name/blabla*' => sub {
	my $self = shift;
} => 'url_with_placeholders';

my $t = Test::Mojo->new;

is $token, undef, "Token uninitialized.";
is $t->app->decsrf->url, '', "Default result url is ''";
$t->get_ok('/')->status_is(200)
	->content_is("/protected\n/url_with_placeholders/Test/blablaTest?test=smthg\n");
$t->get_ok('/protected')->status_is(200)
	->content_is("/\n");
isnt $token, undef, "Token initialized.";

push @{app->decsrf->urls}, qw~/protected /url_with_placeholders/.*?/blabla.*~;

$t->get_ok('/')->status_is(200)
	->content_like(qr~^/protected\?token=\S{4}\n/url_with_placeholders/Test/blablaTest\?test=smthg\&token=\S{4}\n$~);
$t->get_ok('/protected?token=' . $token)->status_is(200)
	->content_is("/\n");
$t->get_ok('/protected')->status_is(403);
$t->get_ok('/protected?token=')->status_is(403);
$t->get_ok('/protected?token=****')->status_is(403);
$t->get_ok('/url_with_placeholders/tEsT/blablatEsT?test=smthng&token=' . $token)
	->status_is(200)->content_is("/\n");
$t->get_ok('/url_with_placeholders/tEsT/blablatEsT')->status_is(403);
$t->get_ok('/url_with_placeholders/tEsT/blabl')->status_is(404);

done_testing();
__DATA__
@@ protected.html.ep
<%= decsrf->url('index') %>
@@ index.html.ep
<%= decsrf->url('protected') %>
<%== decsrf->url('/url_with_placeholders/Test/blablaTest?test=smthg') %>
@@ url_with_placeholders.html.ep
<%= decsrf->url('index') %>
