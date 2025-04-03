#!/usr/bin/perl
use FindBin;
use lib ("$FindBin::Bin/../../lib");
use Mojo::IOLoop::ReadWriteProcess 'process';

# Not all systems have /bin/true, this is /usr/bin/true on osx for instance
my $p
  = process(execute => 'command -v true || which true')
  ->start()
  ->wait_stop->read_all_stdout;
exit process(execute => $p)->start()->wait_stop()->exit_status();
