use strict;
use warnings;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;

plugin 'ReCAPTCHAv2Async', { sitekey => 'key', secret => 'secret' };

post '/test' => sub {
  my $c = shift;

  $c->render_later;

  $c->recaptcha_verify_p->then(sub {
    $c->render(json => { verify => 1, errors => []});
  })->catch(sub {
    $c->render(json => { verify => 0, errors => \@_ }, status => 403);
  })->wait;
};

group sub {
  under sub {
    my $c = shift;

    $c->render_later;

    $c->recaptcha_verify_p->then(sub {
      $c->continue
    })->catch(sub {
      $c->render(json => { verify => 0, errors => \@_ }, status => 403);
    })->wait;

    return undef;
  };

  post '/under' => sub {
    my $c = shift;
    $c->render(json => { verify => 1, errors => [] }, status => 403);
  };
};

my $t = Test::Mojo->new();

$t->post_ok( '/test' => {} => form => { 'g-recaptcha-response' => 'foo' })
  ->status_is(403)
  ->json_is( '/verify' => 0 )
  ->json_is( '/errors/0' => 'invalid-input-response' )
  ->json_is( '/errors/1' => 'invalid-input-secret' );

$t->post_ok( '/under' => {} => form => { 'g-recaptcha-response' => 'foo' })
  ->status_is(403)
  ->json_is( '/verify' => 0 )
  ->json_is( '/errors/0' => 'invalid-input-response' )
  ->json_is( '/errors/1' => 'invalid-input-secret' );

done_testing;
