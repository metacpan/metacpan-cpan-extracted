use strict;
use warnings;
use Test::More;
use Module::New::Template;
use Module::New;

Module::New->setup('Module::New::ForTest');

subtest simple_interpolate => sub {
  Module::New->context->config->set( name => 'foo' );

  my $text = Module::New::Template->render('my name is <%= $c->config("name") %>');

  ok $text eq 'my name is foo', '<%= %> works';
};

subtest no_interpolate => sub {
  Module::New->context->config->set( name => 'bar' );

  my $text = Module::New::Template->render('my name is foo');

  ok $text eq 'my name is foo';
};

done_testing;
