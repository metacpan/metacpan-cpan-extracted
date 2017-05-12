# -*- perl -*-
# $Id: Parallel.pm,v 1.21 2004/02/10 15:19:18 langhein Exp $

package LWP::Parallel;

$VERSION = '2.62';
sub Version { $VERSION };

require 5.004;
require LWP::Parallel::UserAgent;  # this should load everything you need

1;

__END__

=head1 NAME

LWP::Parallel - Extension for LWP to allow parallel HTTP and FTP access

=head1 SYNOPSIS

  use LWP::Parallel;
  print "This is LWP::Parallel_$LWP::Parallel::VERSION\n";

=head1 DESCRIPTION

=head2 Introduction

ParallelUserAgent is an extension to the existing libwww module. It
allows you to take a list of URLs (it currently supports HTTP, FTP, and
FILE URLs. HTTPS might work, too) and connect to all of them _in parallel_,
then wait for the results to come in.

See the Parallel::UserAgent for how to create a LWP UserAgent that
will access multiple Web resources in parallel. The Parallel::RobotUA
module will additionally offer proper handling of robot.txt file, the
de-facto exclusion protocol for Web Robots.

=head2 Examples

The following examples might help to get you started:


  require LWP::Parallel::UserAgent;
  use HTTP::Request; 

  # display tons of debugging messages. See 'perldoc LWP::Debug'
  #use LWP::Debug qw(+);

  # shortcut for demo URLs
  my $url = "http://localhost/"; 

  my $reqs = [  
     HTTP::Request->new('GET', $url),
     HTTP::Request->new('GET', $url."homes/marclang/"),
  ];

  my $pua = LWP::Parallel::UserAgent->new();
  $pua->in_order  (1);  # handle requests in order of registration
  $pua->duplicates(0);  # ignore duplicates
  $pua->timeout   (2);  # in seconds
  $pua->redirect  (1);  # follow redirects

  foreach my $req (@$reqs) {
    print "Registering '".$req->url."'\n";
    if ( my $res = $pua->register ($req) ) { 
	print STDERR $res->error_as_HTML; 
    }  
  }
  my $entries = $pua->wait();

  foreach (keys %$entries) {
    my $res = $entries->{$_}->response;

    print "Answer for '",$res->request->url, "' was \t", $res->code,": ",
          $res->message,"\n";
  }

Parallel::UserAgent (as well as the Parallel::RobotUA) offer three
default methods that will be called at certain points during the
connection: C<on_connect>, C<on_return> and C<on_failure>. 


  #
  # provide subclassed UserAgent to override on_connect, on_failure and
  # on_return methods
  #
  package myUA;

  use Exporter();
  use LWP::Parallel::UserAgent qw(:CALLBACK);
  @ISA = qw(LWP::Parallel::UserAgent Exporter);
  @EXPORT = @LWP::Parallel::UserAgent::EXPORT_OK;

  # redefine methods: on_connect gets called whenever we're about to
  # make a a connection
  sub on_connect {
    my ($self, $request, $response, $entry) = @_;
    print "Connecting to ",$request->url,"\n";
  }

  # on_failure gets called whenever a connection fails right away
  # (either we timed out, or failed to connect to this address before,
  # or it's a duplicate). Please note that non-connection based
  # errors, for example requests for non-existant pages, will NOT call
  # on_failure since the response from the server will be a well
  # formed HTTP response!
  sub on_failure {
    my ($self, $request, $response, $entry) = @_;
    print "Failed to connect to ",$request->url,"\n\t",
          $response->code, ", ", $response->message,"\n"
	    if $response;
  }

  # on_return gets called whenever a connection (or its callback)
  # returns EOF (or any other terminating status code available for
  # callback functions). Please note that on_return gets called for
  # any successfully terminated HTTP connection! This does not imply
  # that the response sent from the server is a success! 
  sub on_return {
    my ($self, $request, $response, $entry) = @_;
    if ($response->is_success) {
       print "\n\nWoa! Request to ",$request->url," returned code ", $response->code,
          ": ", $response->message, "\n";
       print $response->content;
    } else {
       print "\n\nBummer! Request to ",$request->url," returned code ", $response->code,
          ": ", $response->message, "\n";
       # print $response->error_as_HTML;
    }
    return;
  }

  package main;
  use HTTP::Request; 

  # shortcut for demo URLs
  my $url = "http://localhost/"; 

  my $reqs = [  
     HTTP::Request->new('GET', $url),
     HTTP::Request->new('GET', $url."homes/marclang/"),
  ];

  my $pua = myUA->new();

  foreach my $req (@$reqs) {
    print "Registering '".$req->url."'\n";
    $pua->register ($req);
  }
  my $entries = $pua->wait(); # responses will be caught by on_return, etc


The final example will demonstrate a simple Web Robot that keeps a
cache of the "robots.txt" permission files it has encountered so
far. This example also uses callbacks to handle the response as it
comes in.

  require LWP::Parallel::UserAgent;
  use HTTP::Request; 

  # persistent robot rules support. See 'perldoc WWW::RobotRules::AnyDBM_File'
  require WWW::RobotRules::AnyDBM_File;

  # shortcut for demo URLs
  my $url = "http://www.cs.washington.edu/"; 

  my $reqs = [  
     HTTP::Request->new('GET', $url),
	    # these are all redirects. depending on how you set
            # 'redirect_ok' they either just return the status code for
            # redirect (like 302 moved), or continue to follow redirection.
     HTTP::Request->new('GET', $url."research/ahoy/"),
     HTTP::Request->new('GET', $url."research/ahoy/doc/paper.html"),
     HTTP::Request->new('GET', "http://metacrawler.cs.washington.edu:6060/"),
	    # these are all non-existant server. the first one should take
            # some time, but the following ones should be rejected right
            # away
     HTTP::Request->new('GET', "http://www.foobar.foo/research/ahoy/"),
     HTTP::Request->new('GET', "http://www.foobar.foo/foobar/foo/"),
     HTTP::Request->new('GET', "http://www.foobar.foo/baz/buzz.html"),
	    # although server exists, file doesn't
     HTTP::Request->new('GET', $url."foobar/bar/baz.html"),
	    ];

  my ($req,$res);

  # establish persistant robot rules cache. See WWW::RobotRules for
  # non-permanent version. you should probably adjust the agentname
  # and cache filename.
  my $rules = new WWW::RobotRules::AnyDBM_File 'ParallelUA', 'cache';

  # create new UserAgent (actually, a Robot)
  my $pua = new LWP::Parallel::RobotUA ("ParallelUA", 
                                        'yourname@your.site.com', $rules);

  $pua->timeout   (2);  # in seconds
  $pua->delay    ( 5);  # in seconds
  $pua->max_req  ( 2);  # max parallel requests per server
  $pua->max_hosts(10);  # max parallel servers accessed
 
  # for our own print statements that follow below:
  local($\) = ""; # ensure standard $OUTPUT_RECORD_SEPARATOR

  # register requests
  foreach $req (@$reqs) {
    print "Registering '".$req->url."'\n";
    $pua->register ($req , \&handle_answer);
    #  Each request, even if it failed to # register properly, will
    #  show up in the final list of # requests returned by $pua->wait,
    #  so you can examine it # later.
  }

  # $pua->wait returns a pointer to an associative array, containing
  # an '$entry' for each request made, sorted by its url. (as returned
  # by $request->url->as_string)
  my $entries = $pua->wait(); # give another timeout here, 25 seconds

  # let's see what we got back (see also callback function!!)
  foreach (keys %$entries) {
    $res = $entries->{$_}->response;

    # examine response to find cascaded requests (redirects, etc) and
    # set current response to point to the very first response of this
    # sequence. (not very exciting if you set '$pua->redirect(0)')
    my $r = $res; my @redirects;
    while ($r) { 
	$res = $r; 
	$r = $r->previous; 
	push (@redirects, $res) if $r;
    }
    
    # summarize response. see "perldoc HTTP::Response"
    print "Answer for '",$res->request->url, "' was \t", $res->code,": ",
          $res->message,"\n";
    # print redirection history, in case we got redirected
    foreach (@redirects) {
	print "\t",$_->request->url, "\t", $_->code,": ", $_->message,"\n";
    }
  }

  # our callback function gets called whenever some data comes in
  # (same parameter format as standard LWP::UserAgent callbacks!)
  sub handle_answer {
    my ($content, $response, $protocol, $entry) = @_;

    print "Handling answer from '",$response->request->url,": ",
          length($content), " bytes, Code ",
          $response->code, ", ", $response->message,"\n";

    if (length ($content) ) {
	# just store content if it comes in
	$response->add_content($content);
    } else {
        # Having no content doesn't mean the connection is closed!
        # Sometimes the server might return zero bytes, so unless
        # you already got the information you need, you should continue
        # processing here (see below)
        
	# Otherwise you can return a special exit code that will
        # determins how ParallelUA will continue with this connection.

	# Note: We have to import those constants via "qw(:CALLBACK)"!

	# return C_ENDCON;  # will end only this connection
			    # (silly, we already have EOF)
	# return C_LASTCON; # wait for remaining open connections,
			    # but don't issue any new ones!!
	# return C_ENDALL;  # will immediately end all connections
			    # and return from $pua->wait
    }

    # ATTENTION!! If you want to keep reading from your connection,
    # you should have a final 'return undef' statement here. Even if
    # you think that all data has arrived, it does not hurt to return
    # undef here. The Parallel UserAgent will figure out by itself
    # when to close the connection!

    return undef;	    # just keep on connecting/reading/waiting 
                            # until the server closes the connection. 
  }

=head1 AUTHOR

Marc Langheinrich, marclang@cpan.org

=head1 SEE ALSO

See L<LWP> for an overview on Web communication using Perl. See
L<LWP::Parallel::UserAgent> and L<LWP::Parallel::RobotUA> for details
on how to use this library.

=head1 COPYRIGHT

Copyright 1997-2004 Marc Langheinrich E<lt>marclang@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
