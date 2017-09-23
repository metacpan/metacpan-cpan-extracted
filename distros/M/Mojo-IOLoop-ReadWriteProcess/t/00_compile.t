  use strict;
  use Test::More 0.98;

  use_ok $_ for qw(
    Mojo::IOLoop::ReadWriteProcess
    Mojo::IOLoop::ReadWriteProcess::Pool
    Mojo::IOLoop::ReadWriteProcess::Exception
  );

  done_testing;
