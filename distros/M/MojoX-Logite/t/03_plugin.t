#!/usr/bin/env perl

use strict;
use warnings;

use Cwd;

use Test::More tests => 15;

my $testlog = Cwd::cwd . '/testmojolitelog.db';

use Mojolicious::Lite;

use Mojo::Util;

# to avoid verbose default Mojo::Log noise on STDERR
delete $ENV{MOJO_LOG_LEVEL};
app->log->level('fatal');

plugin 'logite' => {
  'path' => $testlog,
  'prune' => 1
};

my %msgs = (
 'debug'  => "Why isn't this working?",
 'info'   => "FYI: it happened again",
 'warn'   => "This might be a problem",
 'error'  => "Garden variety error",
 'fatal'  => "Boom!"
);

# /
get '/(:level)' => sub {
  my ($self) = shift;

  $self->stash('logite')->log(
     $self->stash('level'),
     $msgs{ $self->stash('level') });

  $self->render(template => 'index', format => 'txt');
};

use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/debug')->status_is(200)->content_is($msgs{'debug'});
$t->get_ok('/info')->status_is(200)->content_is($msgs{'info'});
$t->get_ok('/warn')->status_is(200)->content_is($msgs{'warn'});
$t->get_ok('/error')->status_is(200)->content_is($msgs{'error'});
$t->get_ok('/fatal')->status_is(200)->content_is($msgs{'fatal'});

__DATA__

@@ index.txt.ep
% layout 'test';
<% my @rows = $logite->package_table->select( 'where l_level = ?', $level); %>
<%== $rows[0]->l_what =%>

@@ layouts/test.txt.ep
<%= content =%>
