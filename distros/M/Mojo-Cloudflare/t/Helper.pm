package t::Helper;

use Mojo::Base -base;
use Test::Mojo;
use Test::More;
use Mojo::Cloudflare;
use Mojo::UserAgent;

{
  use Mojolicious::Lite;
  use Mojo::JSON 'j';
  use Mojo::Util qw( spurt slurp );

  post '/api_json' => sub {
    my $self = shift;
    my $form = $self->req->params->to_hash;
    my $file = join '.', map { "$_-$form->{$_}" } grep { $_ ne 'tkn' } sort keys %$form;

    $file =~ s![^\w\.-]!_!g;

    if(-e "local/$file") {
      $self->app->log->debug("Read cache: local/$file");
      $self->render(text => slurp "local/$file");
    }
    else {
      $self->app->log->debug("Write cache: local/$file");
      my $res = $self->app->ua->post(Mojo::Cloudflare->new->api_url, form => $form)->res;
      spurt $res->body, "local/$file" if -d 'local';
      $self->render(text => $res->body);
    }
  };
}

sub import {
  my $class = shift;
  my $caller = caller;
  my $test_mojo = Test::Mojo->new;

  no strict 'refs';
  *{"$caller\::t"} = \$test_mojo;

  eval <<"  CODE" or die $@;
  package $caller;
  use Mojo::Base -base;
  use Test::More;
  strict->import;
  warnings->import;
  1;
  CODE
}

1;
