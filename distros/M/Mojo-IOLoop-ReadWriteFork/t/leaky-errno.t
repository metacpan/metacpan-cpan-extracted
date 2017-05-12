use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

BEGIN {
  eval 'use Test::Memory::Cycle;1' or Mojo::Util::monkey_patch(main => memory_cycle_ok => sub { });
}

$ENV{PATH} ||= '';
plan skip_all => 'bash is missing' unless grep { -x "$_/bash" } split /:/, $ENV{PATH};

my $fork = Mojo::IOLoop::ReadWriteFork->new;
my $err;

$fork->on(close => sub { Mojo::IOLoop->stop });
$fork->on(error => sub { $err = "$_[1]" });
$fork->on(read  => sub { $! = 2 });

$fork->start(program => 'bash', program_args => [-c => 'echo test123'], conduit => 'pty',);

Mojo::IOLoop->start;
is $err, undef, 'no error when callback change ERRNO';

done_testing;
