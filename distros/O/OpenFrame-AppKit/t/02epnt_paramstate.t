#!/usr/bin/perl

use lib './lib', '../openframe3/lib','../pipeline2/lib';
use strict;
use Test::More no_plan => 1;

package MyApp;

use strict;
use OpenFrame::AppKit::App;
use base qw( OpenFrame::AppKit::App );

sub entry_points {
   return {
	    handler_a => [ [ state => 1 ], "username", "password" ],
	    handler_b => [ [ state => 0 ], "username", "password" ],
	    handler_c => [
			  [ state => qr/^closed/ ],
			  [ username => 'james' ],
			  [ password => qr/^$/ ],
                         ],
	    handler_d => [
                          [ state => qr/^closed/ ],
                          [ username => 'james' ],
                          [ password => 'kaboom!' ],
			 ]
	  };
}

sub default {
  main::ok(1, "default called in lieu of anything else");
  1;
}

sub handler_a {
  main::ok(1, "reached handler_a");
  return bless {}, 'This';
}

sub handler_b {
  main::ok(1, "reached handler_b");
  1;
}

sub handler_c {
  main::ok(1, "reached handler_c");
  1;
}

sub handler_d {
  main::ok(0, "should never have reached this point");
  1;
}

package main;

use URI;
use OpenFrame::Request;
use Pipeline::Segment::Tester;
use OpenFrame::AppKit::Session;

ok( my $pt   = Pipeline::Segment::Tester->new(), "pst created" );
ok( my $app  = MyApp->new(),          "created an application" );
ok( $app->uri(qr!/!),                 "uri assigned okay"      );

ok( my $res = $pt->test( $app,
	      	         OpenFrame::Request->new()
                                           ->uri(
                                                 URI->new( 'http://test/' )
                                                )
                                           ->arguments(
			     		               {
					                username => 'james',
					                password => 'secret',
					                state    => 1
					               }
					              ),
                         OpenFrame::AppKit::Session->new(),
                       ), "tested app okay" );

ok( my $res = $pt->test( $app,
                         OpenFrame::Request->new()
                                           ->uri(
                                                 URI->new( 'http://test/' )
                                                )
                                           ->arguments(
                                                       {
                                                        username => 'james',
                                                        password => 'secret',
                                                        state    => 0
                                                       }
                                                      ),
                         OpenFrame::AppKit::Session->new(),
                       ), "tested app okay" );

ok( my $res = $pt->test( $app,
                         OpenFrame::Request->new()
                                           ->uri(
                                                 URI->new( 'http://test/' )
                                                )
                                           ->arguments(
                                                       {
                                                        username => 'james',
                                                        password => '',
                                                        state    => 'closed'
                                                       }
                                                      ),
                         OpenFrame::AppKit::Session->new(),
                       ), "tested app okay" );



ok( my $res = $pt->test( $app,
                         OpenFrame::Request->new()
                                           ->uri(
                                                 URI->new( 'http://test/' )
                                                )
                                           ->arguments(
                                                       {
                                                        username => 'james',
                                                        password => 'secret',
                                                        state    => 'closed'
                                                       }
                                                      ),
                         OpenFrame::AppKit::Session->new(),
                       ), "tested app okay" );


