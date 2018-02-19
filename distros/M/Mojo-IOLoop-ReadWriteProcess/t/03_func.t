#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");
use Mojo::IOLoop::ReadWriteProcess qw(process queue parallel);
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt);

no warnings;    # This test mocks a lot

subtest _new_err => sub {
  my $p = process();
  $p->_new_err("Test");
  is $p->error->last->to_string, "Test";
  $p->_new_err("Test", "Test");
  ok !$p->error->last->to_string;
};

subtest write_pidfile => sub {
  use Mojo::File 'tempfile';
  my $pidfile = tempfile;
  my $p = process(code => sub { exit 0 }, pidfile => $pidfile);
  $p->write_pidfile;
  ok !$pidfile->slurp;
};

subtest _fork => sub {
  plan skip_all => "Test is not possible on Windows" if $^O eq "MSWin32";
  use Mojo::Util 'monkey_patch';
  monkey_patch 'IO::Pipe', new => sub { undef };
  my $p = process(sub { exit 0 })->start->wait_stop;
  is $p->error->size, 7;

  like $p->error->last->to_string, qr/Failed creating internal return/
    or diag explain $p->error->last;
  like $p->error->first->to_string, qr/Failed creating input pipe/
    or diag explain $p->error->first;
  like @{$p->error}[2]->to_string, qr/Failed creating output error pipe/
    or diag explain @{$p->error}[2];
  like @{$p->error}[3]->to_string, qr/Failed creating Channel input pipe/
    or diag explain @{$p->error}[3];
  like @{$p->error}[4]->to_string, qr/Failed creating Channel output pipe/
    or diag explain @{$p->error}[4];
  like @{$p->error}[5]->to_string, qr/Failed creating internal error pipe/
    or diag explain @{$p->error}[5];
  like @{$p->error}[6]->to_string, qr/Failed creating internal return pipe/
    or diag explain @{$p->error}[6];
};

subtest DESTROY => sub {
  my $q = queue();
  $Mojo::IOLoop::ReadWriteProcess::Queue::AUTOLOAD
    = "Mojo::IOLoop::ReadWriteProcess::Queue::DESTROY";
  $q->pool(parallel(sub { return 1 } => 30));
  is $q->AUTOLOAD(), undef;
};

subtest open => sub {
  sub Mojo::IOLoop::ReadWriteProcess::open3 { return undef }

  my $p = process();
  {

    eval { $p->_open("/tmp") };
  };

  like $@, qr/Cannot create pipe:/ or diag explain $@;
};

subtest _fork_collect_status => sub {
  use IO::Pipe;

  is Mojo::IOLoop::ReadWriteProcess::_fork_collect_status, undef,
    "Protect when self is already garbage-collected";
  my $p   = process();
  my $end = IO::Pipe::End->new;
  $p->_internal_err($end);
  $p->_fork_collect_status();
  is $p->error->first->to_string, 'Cannot read from errors code pipe';
};


subtest attempt => sub {
  my $var = 0;
  attempt(5, sub { $var == 5 }, sub { $var++ });
  is $var, 5;
  $var = 0;
  attempt {
    attempts  => 6,
    condition => sub { $var == 6 },
    cb        => sub { $var++ }
  };
  is $var, 6;

  $var = 0;
  attempt {
    attempts  => 6,
    condition => sub { $var == 7 },
    cb        => sub { $var++ },
    or        => sub { $var = 42 }
  };

  is $var, 42;
};


done_testing;
