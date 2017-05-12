#!/usr/bin/perl
{
  package RATDemoServer;
  
  use HTTP::Server::Simple::CGI;
  use RDF::RDFa::Template::SimpleQuery;
  use File::Util;
  use base qw(HTTP::Server::Simple::CGI);
  
  
  sub handle_request {
    my $self = shift;
    my $cgi = shift;
    
    my $path = $cgi->path_info;
    my($f) = File::Util->new();
    
    if (-f ".$path") {
      print "HTTP/1.0 200 OK\r\n";
      print "Content-Type: text/html\n\n";
      my ($rat) = $f->load_file(".$path");
      my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, baseuri => 'http://localhost:8080/' );
      $query->execute;
      my $output = $query->rdfa_xhtml;

      print $output->toStringC14N;
    } else {
      print "HTTP/1.0 404 Not found\r\n";
      print $cgi->header,
	$cgi->start_html('Not found'),
	  $cgi->h1('Not found'),
	    $cgi->end_html;
    }
  }
}

1;

# start the server on port 8080
RATDemoServer->new(8080)->run();
