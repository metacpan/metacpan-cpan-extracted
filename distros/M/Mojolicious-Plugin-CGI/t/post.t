use warnings;
use strict;
use Test::More;
use Test::Mojo;

# http://cpantesters.org/cpan/report/dc79de2e-c956-11e4-9245-4861e0bfc7aa
# http://cpantesters.org/cpan/report/676eae4c-24f6-11e5-ad16-fd611bfff594
# http://cpantesters.org/cpan/report/908763b4-24f6-11e5-8c9c-b46a1bfff594
# http://cpantesters.org/cpan/report/1c1f3f16-8a17-11e5-b552-e159351a082c
plan skip_all => 'TEST_PIPES=1; No idea how to test this consistently' unless $ENV{TEST_PIPES};

my @pipes = get_pipes();
my %LSOF_PIPE;    # Map lsof DEVICE and NAME to same pipe.

use Mojolicious::Lite;
plugin CGI => ['/postman' => 't/cgi-bin/postman'];
my $t = Test::Mojo->new;

$t->post_ok('/postman', {}, "some\ndata\n")->status_is(200)->content_like(qr{^\d+\n--- some\n--- data\n$});

my $pid = $t->tx->res->body =~ /(\d+)/ ? $1 : 0;

ok !(kill 0, $pid), "child $pid is taken care of ($$, @{[time]})"
  or is waitpid($pid, 0), $pid, "waitpid $pid, 0 ($$, @{[time]})";

is_deeply \@pipes, [get_pipes()], 'no leaky leaks';

sub get_pipes {
  return diag "test for leaky pipes under Debian build", 1 if $ENV{DEBIAN_BUILD};

  my @pipes;

  if (-d "/proc/$$/fd") {
    for my $fd (glob "/proc/$$/fd/*") {
      my $pts = readlink sprintf '/proc/%s/fd/%s', $$, +(split '/', $fd)[-1] or next;
      push @pipes, $pts if $pts =~ /pipe:/;
    }
  }
  elsif (`which lsof` =~ /\blsof$/) {

    # Output of `lsof` for pipe looks like this:
    #   COMMAND    PID   USER   FD   TYPE             DEVICE  SIZE/OFF     NODE NAME
    #   perl5.18 57806 moejoe    3   PIPE 0xd52803906b02a64f     16384          ->0xd52803907288254f
    for (`lsof -p $$`) {
      / PIPE / or next;
      my ($device, $name) = /\b(0x[[:xdigit:]]+)/g;
      my $pipe = $LSOF_PIPE{$device} || $LSOF_PIPE{$name} || $device;
      $LSOF_PIPE{$device} = $LSOF_PIPE{$name} = $pipe;
      push @pipes, $pipe;
    }
  }
  else {
    diag "unable to test leaky pipes";
  }

  return sort @pipes;
}

done_testing;
