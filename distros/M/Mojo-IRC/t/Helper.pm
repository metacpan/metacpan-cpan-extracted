package t::Helper;
use Mojo::Base -strict;
use Mojo::Util 'monkey_patch';
use Test::More ();
use Mojo::IRC;

sub import {
  my $class  = shift;
  my $caller = caller;

  strict->import;
  warnings->import;

  eval <<"HERE" or die $@;
  package $caller;
  use Test::More;
  1;
HERE

  eval "use Mojo::IOLoop; use Mojo::IOLoop::Server";

  monkey_patch $caller => generate_port => sub {
    Mojo::IOLoop->can('generate_port') ? Mojo::IOLoop->generate_port : Mojo::IOLoop::Server->generate_port;
  };
}

1;
