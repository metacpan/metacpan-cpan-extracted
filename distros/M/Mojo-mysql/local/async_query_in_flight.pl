#!/usr/bin/env perl
use Mojo::Base -strict;
use Mojo::mysql;
use Applify;

my $mysql = Mojo::mysql->new('mysql://root@');
$mysql->max_connections(100);

Mojo::IOLoop->timer(4 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->recurring(0.01 => sub {
  my $db1 = $mysql->db;
  my $db2 = $mysql->db;
  Mojo::IOLoop->delay(
    sub {
      my($delay) = @_;
      my $sleep = int rand 2;
      $mysql->db->query("SELECT SLEEP($sleep), NOW() AS now", $delay->begin);      
      $mysql->db->query("SELECT SLEEP(1), NOW() AS now", $delay->begin);      
    },
    sub {
      my($delay, $err, $res, $err2, $res2) = @_;
      eval {
        warn $err if $err ||= $err2;
        warn $res->array->[1] if $res;
      } or do {
        warn $@;
        Mojo::IOLoop->stop;
      };
      ($db1, $db2) = ();
    }
  );
});

Mojo::IOLoop->start;
