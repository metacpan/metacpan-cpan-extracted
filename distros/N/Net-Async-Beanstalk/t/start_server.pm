# Copied from AnyEvent::Beanstalk

use strict;
use warnings;
package t::start_server;

use Test::Builder;
use Net::Async::Beanstalk;

our @ISA = qw(Exporter);
our @EXPORT = qw($server_port);

our $exe         = $ENV{BEANSTALKD_EXE};
our $server_port = $ENV{BEANSTALKD_PORT} || 11300;

my $builder = Test::Builder->new();

unless ($exe) {
  ($exe) = grep { -x $_ } qw(/opt/local/bin/beanstalkd /usr/local/bin/beanstalkd /usr/bin/beanstalkd);
}

unless ($exe && -x $exe) {
  $builder->plan(skip_all => 'Set environment variable BEANSTALKD_EXE &/ BEANSTALKD_PORT to run live tests');
}

$SIG{CHLD} = 'IGNORE';
if (my $pid = fork()) {
  END { kill 9, $pid if $pid }
  sleep(2);
  $builder->plan(skip_all => "Cannot start server: $!")
    unless kill 0, $pid;
  $builder->note('Started test beanstalkd server');
}
elsif (defined $pid) {
  exec($exe, '-p', $server_port);
  die("Cannot exec $exe: $!\n");
}
else {
  $builder->plan(skip_all => "Cannot fork: $!");
}
1;
