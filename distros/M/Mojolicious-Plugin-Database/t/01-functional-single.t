#!/usr/bin/env perl
use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;

eval "use DBD::SQLite";
plan skip_all => 'DBD::SQLite required for this test!' if $@;
plan tests => 9;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;
use DBD::SQLite;
use DBI;
use Try::Tiny;
use File::Temp qw(tmpnam);

my $dbname = tmpnam();

plugin 'database', {
    'dsn'        => 'dbi:SQLite:dbname=' . $dbname,
    'options'    => { RaiseError => 1, PrintError => 0 },
    'on_connect' => sub {
      my $dbh = shift;
      $dbh->do("CREATE TEMP TABLE onConnectTest (foo TEXT PRIMARY KEY)");
      $dbh->do("INSERT INTO onConnectTest (foo) VALUES ('bar')")
      }
    };

get '/create-table' => sub {
    my $self = shift;
    my $r = 1;

    try {
        $self->db->do('CREATE TABLE foo ( bar INTEGER NOT NULL )');
    } catch {
        $r = 0;
    };
    $self->render(text => ($r) ? 'ok' : 'failed');
};

get '/drop-table' => sub {
    my $self = shift;
    my $r = 1;

    try {
        $self->db->do('DROP TABLE foo');
    } catch {
        $r = 0;
    };
    $self->render(text => ($r) ? 'ok' : 'failed');
};

get '/on-connect' => sub {
  my $self = shift;
  my ($foo) = $self->db->selectrow_array("SELECT foo FROM onConnectTest");
  $self->render(text=> $foo eq 'bar' ? 'ok' : 'failed');

};

my $t = Test::Mojo->new;

$t->get_ok('/create-table')->status_is(200)->content_is('ok');
$t->get_ok('/drop-table')->status_is(200)->content_is('ok');
$t->get_ok('/on-connect')->status_is(200)->content_is('ok');

unlink($dbname);
