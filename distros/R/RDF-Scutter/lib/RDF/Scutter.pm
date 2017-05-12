package RDF::Scutter;

use strict;
use warnings;
use Carp;

our $VERSION = '0.1';

use base ('LWP::RobotUA');

use RDF::Redland;

sub new {
  my ($that, %params) = @_;
  my $class = ref($that) || $that;

  my $scutterplan = $params{scutterplan};
  croak("No place to start, please give an arrayref with URLs as a 'scutterplan' parameter") unless (ref($scutterplan) eq 'ARRAY');
  delete $params{scutterplan};

  # Some parameters, that should be deleted before passing them to SUPER
  my $skip = $params{skipregexp};
  delete $params{skipregexp};
  my $okwait = $params{okwait} || 1;
  delete $params{okwait};

  unless ($params{agent}) { # agent is required by SUPER, set it to who I am
    $params{agent} = $class . '/' . $VERSION;
  }

  croak "Setting an e-mail address using the 'from' parameter is required" unless ($params{from});

  my $self = $class->SUPER::new(%params);

  foreach my $url (@{$scutterplan}) {
    $self->{QUEUE}->{$url} = ''; # Internally, QUEUE holds a hash where the keys are URLs to be visited and values are the URL they were referenced from.
  }

  $self->{VISITED} = {};
  $self->{SKIP} = $skip;
  $self->{OKWAIT} = $okwait;

  bless($self, $class);
  return $self;
}

sub scutter {
  my ($self, $storage, $maxcount) = @_;
  LWP::Debug::trace('scutter');
  my $model = new RDF::Redland::Model($storage, ""); # $model will contain all we find.
  croak "Failed to create RDF::Redland::Model for storage\n" unless $model;

  my $count = 0;

  # -----------------------------------------------------------------
  # Main loop starts here.
  # Iterate over the QUEUE (which is changing as we go)
  while (my ($url, $referer) = each(%{$self->{QUEUE}})) {
    local $SIG{TERM} = sub { $model->sync; };
    next if ($self->{VISITED}->{$url}); # Then, we've been there in this run
#    LWP::Debug::debug('Retrieving ' . $url);

    $count++;
    my $uri = new RDF::Redland::URI($url); # Set up some basic nodes.
    my $context=new RDF::Redland::BlankNode('context'.$count);
    my $fetch=new RDF::Redland::BlankNode('fetch'.$count); # It is actually unique to this run, but will have to change later
    my $rdftype = new RDF::Redland::URI('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');

    
    # Now, statements about the contexts
    $model->add_statement($context,  
			  $rdftype,
			  new RDF::Redland::URINode('http://purl.org/net/scutter#Context'), $context);
    $model->add_statement($context,  
			  new RDF::Redland::URINode('http://purl.org/net/scutter#source'), 
			  $uri, $context);

    if ($referer) {
      $model->add_statement($context,
			    new RDF::Redland::URINode('http://purl.org/net/scutter#origin'), 
			    new RDF::Redland::URINode($referer), $context);
    }

    if ($self->{SKIP} and ($url =~ m/$self->{SKIP}/)) { # Support skipping per a regexp
      LWP::Debug::debug('Skipping ' . $url);
      LWP::Debug::debug('Disallowed as per regular expression: ' . $self->{SKIP});
      $model = $self->_error_statements(model => $model,
					fetch => $fetch,
					count => $count,
					context => $context,
					rel => 'skip',
					message => 'Disallowed as per regular expression: ' . $self->{SKIP});
      delete $self->{QUEUE}->{$url};
      next;
    }

    unless ($self->rules->allowed($url)) {
      # This is not actually likely to run, it seems, as LWP::RobotUA
      # may not have decided yet at this point, and will throw a 403
      # Forbidden instead.
      LWP::Debug::debug('Skipping ' . $url); 
      LWP::Debug::debug('Disallowed as per robots.txt');
      $model = $self->_error_statements(model => $model,
					fetch => $fetch,
					count => $count,
					context => $context,
					rel => 'skip',
					message => 'Disallowed as per robots.txt');
      delete $self->{QUEUE}->{$url};
      next;
    }

    # TODO: Doesn't seem to work
    if ($self->host_wait($url) > $self->{OKWAIT}) { # We can't request, and won't bother to wait.
      LWP::Debug::debug("Do $url later.");
      delete $self->{QUEUE}->{$url}; # Delete where we are
      $self->{QUEUE}->{$url} = $referer; # And reinsert
      next;
    }

    print STDERR "No: $count, Retrieving $url\n";
    my $response = $self->get($url, 'Referer' => $referer);


    my $fetchtime = $response->header('Date'); # Get a time somehow.
    unless ($fetchtime) {
      $fetchtime = localtime;
    }

    # More statements about the fetch we just did.
    $model->add_statement($context,
			  new RDF::Redland::URINode('http://purl.org/net/scutter#fetch'), 
			  $fetch, $context);
    $model->add_statement($fetch,
			  $rdftype, 
			  new RDF::Redland::URINode('http://purl.org/net/scutter#Fetch'), $context);
    $model->add_statement($fetch,
			  new RDF::Redland::URINode('http://purl.org/dc/elements/1.1/date'), 
			  new RDF::Redland::LiteralNode($fetchtime), $context);
    $model->add_statement($fetch,
			  new RDF::Redland::URINode('http://purl.org/net/scutter#status'), 
			  new RDF::Redland::LiteralNode($response->code), $context);

    $self->{VISITED}->{$url} = 1;  # Been there, done that,
    delete $self->{QUEUE}->{$url}; # one teeshirt is sufficient

    if ($response->is_success) {
      # W00T, we really got the document!

      my $parser=new RDF::Redland::Parser;
      unless ($parser) {
	LWP::Debug::debug('Skipping ' . $url);
	LWP::Debug::debug('Could not create parser for MIME type '.$response->header('Content-Type'));
	$model = $self->_error_statements(model => $model,
					  fetch => $fetch,
					  count => $count,
					  context => $context,
					  message => 'Could not create Redland parser for MIME type '.$response->header('Content-Type'));
	next;
      }

      my $thisdoc;
      eval { # We try to parse it
	$thisdoc = $parser->parse_string_as_stream($response->decoded_content, $uri);
      };
      if ($@){
	LWP::Debug::debug('Skipping ' . $url);
	LWP::Debug::debug('Parser error: ' . $@);
	LWP::Debug::conns($response->decoded_content);
	$model = $self->_error_statements(model => $model,
					  fetch => $fetch,
					  count => $count,
					  context => $context,
					  message => 'Redland parser reported ' . $@);
	next;
      }

      unless ($thisdoc) {
	LWP::Debug::debug('Skipping ' . $url);
	LWP::Debug::debug('Parser returned no content.');
	LWP::Debug::conns($response->decoded_content);
	$model = $self->_error_statements(model => $model,
					  fetch => $fetch,
					  count => $count,
					  context => $context,
					  message => 'Redland parser returned no content.');
	next;
      }

      # Now build a temporary model for this resource
      my $tmpstorage=new RDF::Redland::Storage("memory", "tmpstore", "new='yes',contexts='yes'");
      my $thismodel = new RDF::Redland::Model($tmpstorage, "");
      while($thisdoc && !$thisdoc->end) { # Add the statements to both models
	my $statement=$thisdoc->current;
	$model->add_statement($statement,$context);
	$thismodel->add_statement($statement,$context);

	$thisdoc->next;
      }

      # More about the fetch
      $model->add_statement($fetch,
			    new RDF::Redland::URINode('http://purl.org/net/scutter#raw_triple_count'), 
			    new RDF::Redland::LiteralNode($thismodel->size), $context);
      if ($response->header('ETag')) {
	$model->add_statement($fetch,
			      new RDF::Redland::URINode('http://purl.org/net/scutter#etag'), 
			      new RDF::Redland::LiteralNode($response->header('ETag')), $context);
      }
      if ($response->header('Last-Modified')) {
	$model->add_statement($fetch,
			      new RDF::Redland::URINode('http://purl.org/net/scutter#last_modified'), 
			      new RDF::Redland::LiteralNode($response->header('Last-Modified')), $context);
      }

      # The query will get out the seeAlso links from the resource,
      # which is what we'll follow
      my $query=new RDF::Redland::Query('SELECT DISTINCT ?doc WHERE { [ <http://www.w3.org/2000/01/rdf-schema#seeAlso> ?doc ] }', undef, undef, "sparql");

      my $results;
      eval {
	$results = $query->execute($thismodel);
      };
      if ($@){
	LWP::Debug::debug('Failed to query links, Redland reported: ' . $@);
	LWP::Debug::conns($response->decoded_content);
	next;
      }

      # OK, here we go through all the results and get the URLs we want.
      while(!$results->finished) {
	for (my $i=0; $i < $results->bindings_count(); $i++) {
	  my $value=$results->binding_value($i);
	  $self->_check_and_add($url, $value->uri->as_string);
	}
	$results->next_result;
      }
 #     $model->sync; # Finally, make sure this is saved to the storage. Needed?


      # If we have a maxcount, then check if we should jump out of the
      # loop
      last if (defined($maxcount) and ($count >= $maxcount));   

    } elsif (($response->is_redirect) && ($response->header('Location'))) {
      # Hmm, dull, just a redirect, lets add it to the queue if we
      # haven't been there
      $self->_check_and_add($url, $response->header('Location'));
      $model = $self->_error_statements(model => $model,
					fetch => $fetch,
					count => $count,
					context => $context,
					rel => 'skip',
					message => 'HTTP Redirect');


    } else { # Error situation, retrieval not OK
      $model = $self->_error_statements(model => $model,
					fetch => $fetch,
					count => $count,
					context => $context,
					message => 'HTTP Error. Message: '.$response->message);
    }

  }
  return $model;
}


# This is a sub just for internal use, and it creates a few statements
# in case of an error. It is just a shorthand really.
# There are lots of usage examples in the code... :-)
sub _error_statements {
  my ($self, %msg) = @_;
  my $reason=new RDF::Redland::BlankNode('reason'.$msg{count});
  my $rel = $msg{rel} || 'error'; # Error relationship if nothing else is given.
  my $model = $msg{model};
  $model->add_statement($msg{fetch},
			new RDF::Redland::URINode('http://purl.org/net/scutter#'.$rel), 
			$reason, $msg{context});
  $model->add_statement($reason,
			new RDF::Redland::URI('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),  
			new RDF::Redland::URINode('http://purl.org/net/scutter#Reason'), $msg{context});
  $model->add_statement($reason,
			new RDF::Redland::URINode('http://purl.org/dc/elements/1.1/description'), 
			new RDF::Redland::LiteralNode($msg{message}), $msg{context});
  return $model;
}

# Internal sub, to check if we have been on an URL before, and if not,
# add it to the QUEUE. First argument is where we are now, second is
# the URL we're checking.
sub _check_and_add {
  my ($self, $thisurl, $foundurl) = @_;
  unless ($self->{VISITED}->{$foundurl}) {
    $self->{QUEUE}->{$foundurl} = $thisurl;
    print STDERR "Adding URL: " . $foundurl ."\n";
    return 1;
  } else {
    delete $self->{QUEUE}->{$foundurl};
    LWP::Debug::debug('Has been visited, so skipping ' . $foundurl);
    return 0;
  }
}

1;
__END__


=head1 NAME

RDF::Scutter - Perl extension for harvesting distributed RDF resources

=head1 SYNOPSIS

  use RDF::Scutter;
  use RDF::Redland;
  my $scutter = RDF::Scutter->new(scutterplan => ['http://www.kjetil.kjernsmo.net/foaf.rdf',
                                                  'http://my.opera.com/kjetilk/xml/foaf/'],
                                  from => 'scutterer@example.invalid');

  my $storage=new RDF::Redland::Storage("hashes", "rdfscutter", "new='yes',hash-type='bdb',dir='/tmp/',contexts='yes'");
  my $model = $scutter->scutter($storage, 30);
  my $serializer=new RDF::Redland::Serializer("ntriples");
  print $serializer->serialize_model_to_string(undef,$model);


=head1 DESCRIPTION

As the name implies, this is an RDF Scutter. A scutter is a web robot
that follows C<seeAlso>-links, retrieves the content it finds at those
URLs, and adds the RDF statements it finds there to its own store of
RDF statements.

This module is an alpha release of such a Scutter. It builds a
L<RDF::Redland::Model>, and can add statements to any
L<RDF::Redland::Storage> that supports contexts. Among Redland
storages, we find file, memory, Berkeley DB, MySQL, etc.

This class inherits from L<LWP::RobotUA>, which again is a
L<LWP::UserAgent> and can therefore use all methods of these classes.

The latter implies it is robot that by default behaves nicely, it
checks C<robots.txt>, and sleeps between connections to make sure it
doesn't overload remote servers.

It implements most of the ScutterVocab at http://rdfweb.org/topic/ScutterVocab

=head1 CAUTION

This is an alpha release, and I haven't tested very thoroughly what it
can do if left unsupervised, and you might want to be careful about
finding out... The example in the Synopsis a complete scutter, but one
that will retrieve only 30 URLs before returning. You could test it by
entering your own URLs (optional) and a valid email address
(mandatory). It'll count and report what it is doing.

=head1 METHODS

=head2 new(scutterplan => ARRAYREF, from => EMAILADDRESS, [skipregexp => REGEXP, any LWP::RobotUA parameters])

This is the constructor of the Scutter. You will have to initialise it
with a C<scutterplan> argument, which is an ARRAYREF containing URLs
pointing to RDF resources. The Scutter will start its traverse of the
web there. You must also set a valid email address in a C<from>, so
that if your scutter goes amok, your victims will know who to blame.

You may supply a C<skipregexp> argument, containing a regular
expression. If the regular expression matches the URL of a resource,
the resource will be skipped.

Finally, you may supply any arguments a L<LWP::RobotUA> and
L<LWP::UserAgent> accepts.

=head2 scutter(RDF::Redland::Storage [, MAXURLS]);

This method will launch the Scutter. As first argument, it takes a
L<RDF::Redland::Storage> object. This allows you to store your model
any way Redland supports, and it is very flexible, see its
documentation for details. Optionally, it takes an integer as second
argument, giving the maximum number of URLs to retrieve
successfully. This provides some security against a runaway robot.

It will return a L<RDF::Redland::Model> containing a model with all
statements retrieved from all visited resources.


=head1 BUGS/TODO

There are no known real bugs at the time of this writing, keeping in
mind it is an alpha. If you find any, please use the CPAN Request
Tracker to report them.

However, I have tried to add some code to allow the robot to
temporarily skip over and later revisit a resource that couldn't be
visited at the time of initital request per robot guidelines. This
code is in there, but is undocumented as I couldn't get it to work.

I'm in it slightly over my head when I try to add the ScutterVocab
statements. Time will show if I have understood it correctly.

Allthough it uses L<LWP::Debug> to debugging, the author feels it is
somewhat problematic to find the right amount of output from the
module. Subsequent releases are likely to be more quiet than the
present release, however.

For an initial release, heeding C<robots.txt> is actually pretty
groundbreaking. However, a good robot should also make use of HTTP
caching, keywords are Etags, Last-Modified and Expiry. It will be a
focus of upcoming development, and many of these things are now being
stated about the context in the RDF.

It is not clear how long it would be running, or how it would perform
if set to retrieve as much as it could. Currently, it is a serial
robot, but there exists Perl modules to make parallell robots. If it
is found that a serial robot is too limited, it will necessarily
require attention.

One of these days, it seems like I will have to make a full HTTP
headers vocabulary...


=head1 SEE ALSO

L<RDF::Redland>, L<LWP>.

=head1 SUBVERSION REPOSITORY

This code is maintained in a Subversion repository. You may check out
the trunk using e.g.

  svn checkout http://svn.kjernsmo.net/RDF-Scutter/trunk/ RDF-Scutter


=head1 AUTHOR

Kjetil Kjernsmo, E<lt>kjetilk@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Many thanks to Dave Beckett for writing the Redland framework and for
helping when the author was confused, and to Dan Brickley for
interesting discussions. Also thanks to the LWP authors for their
excellent library.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kjetil Kjernsmo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
