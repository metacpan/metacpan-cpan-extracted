#!perl
# vim:syntax=perl:tabstop=4:number:noexpandtab:

use Mojo::Base -strict;
use Mojolicious::Lite;
use Mojo::JSON qw();
use Test::Mojo;
use Test::More;

plugin 'ReCAPTCHAv2' => {
	'sitekey' => 'key',
	'secret'  => 'secret',
};

get '/' => sub {
	my $c = shift;
	$c->render( text => $c->recaptcha_get_html );
};

# we override the default handler to check that the ep
# handler is used for the inline template in the plugin
app->renderer->default_handler('something_else');

my $t = Test::Mojo->new;

$t
->get_ok('/')
->status_is(200)
->content_is(<<'RECAPTCHA');
<script src="https://www.google.com/recaptcha/api.js?hl=" async defer></script>
<div class="g-recaptcha" data-sitekey="key"></div>
RECAPTCHA

done_testing;
