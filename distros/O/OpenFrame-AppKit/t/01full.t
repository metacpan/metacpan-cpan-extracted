#!/usr/bin/perl -w

use strict;
use lib './lib', '../openframe3/lib', '../pipeline2/lib';
use Pipeline;
use OpenFrame::AppKit;
use OpenFrame::Segment::HTTP::Request;
use OpenFrame::AppKit::Examples::Hangman;
use OpenFrame::AppKit::Examples::NameForm;
use HTTP::Request;
use Test::More tests => 29;
use URI;

# Get the front page
my $url = URI->new('http://localhost/');
my($r, $s) = run(HTTP::Request->new(GET => $url));
ok($r->is_success);
is($r->headers->content_type, 'text/html');
like($r->content, qr/Welcome to AppKit/);
like($r->content, qr/What is your name/);
is(ref($s), 'OpenFrame::AppKit::Session');

# Grab the session id and give it back later on
my $cookie = $r->headers->header('Set-Cookie');
my($id) = $cookie =~ /session=([0-9a-f]+);/;
is(length($id), 16);
my $headers = HTTP::Headers->new;
$headers->header('Cookie' => "session=$id");

# Put in the name
$url->query_form(name => 'Leon');
($r, $s) = run(HTTP::Request->new(GET => $url, $headers));
ok($r->is_success);
is($r->headers->content_type, 'text/html');
like($r->content, qr/Welcome to AppKit/);
like($r->content, qr/Congratulations Leon/);
is(ref($s), 'OpenFrame::AppKit::Session');
is($s->{application}->{nameform}->{name}, 'Leon');

# Get a 404
$url = URI->new('http://localhost/xyzzy');
($r, $s) = run(HTTP::Request->new(GET => $url));
is($r->code, 500);
is($r->headers->content_type, 'text/html');
like($r->content, qr/File Not Found/);

# Get an image
$url = URI->new('http://localhost/hangman/images/h0.gif');
($r, $s) = run(HTTP::Request->new(GET => $url, $headers));
ok($r->is_success);
is($r->headers->content_type, 'image/gif');

# Get the front page of hangman
$url = URI->new('http://localhost/hangman/');
($r, $s) = run(HTTP::Request->new(GET => $url, $headers));
ok($r->is_success);
is($r->headers->content_type, 'text/html');
like($r->content, qr/Hangman/);
like($r->content, qr{/hangman/images/h0.gif});
is(ref($s), 'OpenFrame::AppKit::Session');
is(ref($s->{application}->{hangman}), 'HASH');

# Make a guess
$url = URI->new('http://localhost/hangman/');
$url->query_form(guess => 'E');
($r, $s) = run(HTTP::Request->new(GET => $url, $headers));
ok($r->is_success);
is($r->headers->content_type, 'text/html');
like($r->content, qr/Hangman/);
is(ref($s), 'OpenFrame::AppKit::Session');

if ($r->content =~ qr/Chances: 5<br>/) {
  # We guessed wrongly
  like($r->content, qr/Word: \*+</);
  like($r->content, qr{/hangman/images/h1.gif});
} else {
  # We guessed correctly
  like($r->content, qr/Word: [*e]+</);
  like($r->content, qr{/hangman/images/h0.gif});
}

sub run {
  my $r = shift;

  my $pipeline = Pipeline->new();
  my $http_request   = OpenFrame::Segment::HTTP::Request->new();
  my $image_loader = OpenFrame::AppKit::Segment::Images->new()
                     ->directory("./templates");
  my $session_loader = OpenFrame::AppKit::Segment::SessionLoader->new();
  my $name_form      = OpenFrame::AppKit::Examples::NameForm->new()
                       ->uri( qr:/(index\.html|)$: )
                       ->namespace( 'nameform' );
  my $hangman        = OpenFrame::AppKit::Examples::Hangman->new()
                       ->uri( '/hangman' )
                       ->namespace( 'hangman' )
                       ->wordlist( './words.txt' );
  my $content_loader = OpenFrame::AppKit::Segment::TT2->new()
                       ->directory("./templates");
  my $logger         = OpenFrame::AppKit::Segment::LogFile->new();

  # Do we want lots of debugging?
  foreach my $slot ($http_request, $image_loader, $session_loader, $name_form,
		    $hangman, $content_loader, $logger) {
    #      $slot->debug(10);
  }

  ## order is important here.
  $pipeline->add_segment(
			 $http_request,
			 $image_loader,
			 $session_loader,
			 $name_form,
			 $hangman,
			 $content_loader,
			);

  $pipeline->cleanups->add_segment( $logger );

  ## create a new store
  my $store = Pipeline::Store::Simple->new();

  ## add the request into the store and then add the store to the pipeline
  $pipeline->store( $store->set( $r ) );

  ## dispatch the pipeline
  $pipeline->dispatch();

  ## get the response and session out
  my $response = $pipeline->store->get('HTTP::Response');
  my $session = $pipeline->store->get('OpenFrame::AppKit::Session');

  return ($response, $session);
}



