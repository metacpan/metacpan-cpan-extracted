  use strict;
  use Test::More 0.98;
  use FindBin;
  use lib ("$FindBin::Bin/lib", "../lib", "lib");

  use_ok $_ for qw(
    Mojo::IOLoop::ReadWriteProcess
    Mojo::IOLoop::ReadWriteProcess::Pool
    Mojo::IOLoop::ReadWriteProcess::Exception
    Mojo::IOLoop::ReadWriteProcess::Queue
    Mojo::IOLoop::ReadWriteProcess::Session
    Mojo::IOLoop::ReadWriteProcess::Container
    Mojo::IOLoop::ReadWriteProcess::CGroup
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2
  );

  done_testing;
