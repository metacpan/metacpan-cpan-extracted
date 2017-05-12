# Copyright (c) 2008 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;
use lib 't/lib';

# assertions on
#sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use DummyServer;
use Email::Simple;
use POE qw(Component::Client::NNTP::Tail);

use Test::More tests => 9;

my $DEBUG = 0;

POE::Session->create(
  package_states => [
    main => [ qw( 
      _start 
      _setup
      _waiting
      _shutdown
      add_articles
      new_article
      got_it
    )],
  ],
  options => { trace => $DEBUG },
);

$poe_kernel->run;

#--------------------------------------------------------------------------#
# event handlers
#--------------------------------------------------------------------------#

sub _start { 
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  $kernel->yield( '_setup' );
  return;
}

sub _shutdown{
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  $kernel->call( 'MyTail' => 'unregister' );
  $kernel->call( 'MyTail', 'shutdown' );
  $kernel->call( 'DummyServer', 'shutdown' );
  $kernel->alarm_remove( $heap->{kill_id} );
  $heap->{kill} = 1;
  return;
}

sub _setup { 
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  # start the server
  $heap->{server} = DummyServer->spawn( 
    port => 10119, 
    Debug => $DEBUG, 
  );
  isa_ok( $heap->{server}, 'DummyServer' );
  # seed the group
  my $article = Email::Simple->new( "Subject: seed\n\nHello world\n" );
  $heap->{server}->add_article( 'test.group', $article->as_string );

  # follow the group
  $heap->{tail} = POE::Component::Client::NNTP::Tail->spawn(
    Alias => 'MyTail',
    Group => 'test.group',
    NNTPServer => '127.0.0.1',
    Port => 10119,
    Interval => 1,
    Debug => $DEBUG,
  );
  $kernel->post( 'MyTail' => 'register' => 'new_article' );
  $kernel->delay( 'add_articles' => 2 );
  $heap->{kill_id} = $kernel->alarm_set( '_shutdown' => time + 30 ); # Kill switch
  return;
}

sub _waiting {
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  $heap->{first_wait} ||= time;
  # articles not processed just wait
  if ( $heap->{kill} || ! keys %{$heap->{cases}} ) { 
    $kernel->yield( '_shutdown' );
  }
  else {
    $kernel->delay( '_waiting', 1 );
  }
  return;
}

sub add_articles {
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  
  # add two articles with random subject and record subject for verification
  for ( 0 .. 1 ) {
    my $rand = int( rand(2**16) + 1 );
    my $article = Email::Simple->new( "Subject: $rand\n\nHello $rand world\n" );
    $heap->{server}->add_article( 'test.group', $article->as_string );
    $heap->{cases}{$rand} = 1;
  }

  # repeat once to test polling
  if ( ! $heap->{done} ) {
    $heap->{done}++;
    $kernel->delay( 'add_articles', 2);
  }
  else {
    $kernel->yield( '_waiting' );
  }
  return;
}

sub new_article {
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  my ($article_id, $lines) = @_[ARG0,ARG1];
  my $article = Email::Simple->new( join("\n", @$lines) );
  my $subject = $article->header('Subject') || 'XXX';
  my $msg_id = $article->header('Message-ID') || '<YYYY.ZZZZ>';
  ok( delete $heap->{cases}{$subject}, 
    "got article header for $msg_id"
  );
  $kernel->post( 'MyTail', 'get_article', $article_id, 'got_it' );
  return;
}

sub got_it {
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  my ($article_id, $lines) = @_[ARG0,ARG1];
  my $article = Email::Simple->new( join("\n", @$lines) );
  my $subject = $article->header('Subject') || 'XXX';
  my $msg_id = $article->header('Message-ID') || '<YYYY.ZZZZ>';
  like( $article->as_string, qr/Hello $subject world/,
    "article body ok for $msg_id"
  );
  return;
}

