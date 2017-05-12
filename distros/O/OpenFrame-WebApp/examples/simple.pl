#!/usr/bin/perl

=head1 NAME

simple.pl - a simple OpenFrame::WebApp example

=head2 SYNOPSIS

  perl ./simple.pl [port] [template_type] [debug]

=cut

use blib;
use strict;
use warnings;

use Pipeline;
use HTTP::Daemon;
use OpenFrame;
use OpenFrame::WebApp;
use OpenFrame::WebApp::Template::TT2;
use OpenFrame::WebApp::Template::Petal;
use OpenFrame::WebApp::Session::MemCache;
use OpenFrame::Segment::HTTP::Request;
use OpenFrame::Segment::ContentLoader;

my  $port  = shift || 8080;
my  $tmpl  = shift || 'tt2';
our $debug = shift || 0;
my  $httpd = HTTP::Daemon->new( LocalPort => $port, Reuse => 1) || die $!;

print "using template type: $tmpl\n";
print "server running at http://localhost:$port/\n";

my $pipe     = new Pipeline();
my $loadpipe = new LoadPipe();
$pipe->add_segment(
		   new OpenFrame::Segment::HTTP::Request(),
		   new OpenFrame::WebApp::Segment::Session::CookieLoader(),
		   $loadpipe,
		   new MyApp::Segment::TemplateMapper(),
		   new OpenFrame::WebApp::Segment::Template::Loader(),
		   new OpenFrame::Segment::ContentLoader()->directory("./htdocs"),
		  );
$loadpipe->add_segment(
		       new OpenFrame::WebApp::Segment::Decline::UserInSession(),
		       new OpenFrame::WebApp::Segment::User::RequestLoader(),
		       new OpenFrame::WebApp::Segment::User::SaveInSession(),
		      );

if ($debug) {
    print "debug set to: $debug\n";
    $pipe->debug( $debug );
    $_->debug( $debug ) for (@{ $pipe->segments }, @{ $loadpipe->segments });
    $OpenFrame::DEBUG{ALL} = $debug;
}

my $ufactory = new OpenFrame::WebApp::User::Factory()->type( 'webapp' );
my $tfactory = new OpenFrame::WebApp::Template::Factory()->type( $tmpl )->directory("./htdocs/$tmpl");
my $sfactory = new OpenFrame::WebApp::Session::Factory()->type( 'mem_cache' )->expiry( '1 minute' );

while (my $connection = $httpd->accept()) {
    while (my $request = $connection->get_request) {
	my $store = new Pipeline::Store::Simple()
	  ->set( $request )
	  ->set( $ufactory )
	  ->set( $tfactory )
	  ->set( $sfactory );

	$pipe->store( $store );
	$pipe->cleanups->segments( [] );

	print "\nserving request for " . $request->uri . "\n" if ($debug);
	$pipe->dispatch();

	my $response = $pipe->store->get('HTTP::Response');
	# no error handling here...

	$connection->send_response( $response );
    }
}


package MyApp::Segment::TemplateMapper;
use Data::Dumper;
use base qw( OpenFrame::WebApp::Segment::Session );

sub dispatch {
    my $self     = shift;
    my $request  = $self->store->get('OpenFrame::Request') || return;
    my $tfactory = $self->store->get('OpenFrame::WebApp::Template::Factory') || return;

    if ($request->uri =~ /^(.+)\.template$/i) {
	$self->emit("matched uri: $1");
	my $session = $self->get_session_from_store;
	$self->emit( Dumper( $session ) );
	return $tfactory->new_template( $1 )->template_vars( { session => $session } );
    }
}


package LoadPipe; # this class for pretty-printing only
use base qw( Pipeline );


__END__

=head1 DESCRIPTION

...

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=cut
