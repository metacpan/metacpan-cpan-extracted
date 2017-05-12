use Test::More;
use strict;
use warnings;

use WWW::Mechanize;

# the order is important
use Saml2Test;
use Dancer::Test;

# interact with the IdP live
my $mech = WWW::Mechanize->new;

## start a login
my $login = dancer_response(GET => '/login');
ok($login);
ok($login->{status} == 302);
ok($login->{headers}->header('location'));

## redirected to IdP login form

$mech->get( $login->{headers}->header('location') );
my $form = $mech->form_name('Login');

## submit login for with test credentials

my $params = {
	IDButton => 'Submit',
	IDToken0 => '',
	IDToken1 => 'demo',
	IDToken2 => 'demodemo',
};
for my $input ($form->inputs) {
	$params->{$input->name} = $input->value;
}

my $response = $mech->post($form->action, $params);
ok($mech->title eq 'Access rights validated');

## post the SAMLResponse form to the app

$form = $mech->form_number(1);
ok($form);
ok(qr!/consumer-post!, $form->action);

$params = { 
	SAMLResponse => $form->param('SAMLResponse'),
};

my $post = dancer_response(POST => '/consumer-post', { params => $params });
is $post->{status}, 200;
ok(qr/User: /, $post->{content});

done_testing;
