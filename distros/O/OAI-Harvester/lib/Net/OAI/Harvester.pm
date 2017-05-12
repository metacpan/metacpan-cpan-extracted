package Net::OAI::Harvester;

use strict;
use warnings;

use constant XMLNS_OAI => "http://www.openarchives.org/OAI/2.0/";

use URI;
use LWP::UserAgent;
use XML::SAX qw( Namespaces Validation );
use File::Temp qw( tempfile );
use Carp qw( carp croak );

use Net::OAI::Error;
use Net::OAI::ResumptionToken;
use Net::OAI::Identify;
use Net::OAI::ListMetadataFormats;
use Net::OAI::ListIdentifiers;
use Net::OAI::ListRecords;
use Net::OAI::GetRecord;
use Net::OAI::ListSets;
use Net::OAI::Record::Header;
use Net::OAI::Record::OAI_DC;

our $VERSION = "1.20";
our $DEBUG = 0;
# compatibility mode for metadataHandler
our $OLDmetadataHandler = 0;

=head1 NAME

Net::OAI::Harvester - A package for harvesting metadata using OAI-PMH

=head1 SYNOPSIS

    ## create a harvester for the Library of Congress
    my $harvester = Net::OAI::Harvester->new( 
	'baseURL' => 'http://memory.loc.gov/cgi-bin/oai2_0'
    );

    ## list all the records in a repository
    my $records = $harvester->listRecords( 
	'metadataPrefix'    => 'oai_dc' 
    );
    while ( my $record = $records->next() ) {
	my $header = $record->header();
	my $metadata = $record->metadata();
	print "identifier: ", $header->identifier(), "\n";
	print "title: ", $metadata->title(), "\n";
    }

    ## find out the name for a repository
    my $identity = $harvester->identify();
    print "name: ",$identity->repositoryName(),"\n";

    ## get a list of identifiers 
    my $identifiers = $harvester->listIdentifiers(
	'metadataPrefix'    => 'oai_dc'
    );
    while ( my $header = $identifiers->next() ) {
	print "identifier: ",$header->identifier(), "\n";
    }

    ## list all the records in a repository
    my $records = $harvester->listRecords( 
	'metadataPrefix'    => 'oai_dc' 
    );
    while ( my $record = $records->next() ) {
	my $header = $record->header();
	my $metadata = $record->metadata();
	print "identifier: ", $header->identifier(), "\n";
	print "title: ", $metadata->title(), "\n";
    }

    ## GetRecord, ListSets, ListMetadataFormats also supported

=head1 DESCRIPTION

Net::OAI::Harvester is a Perl extension for easily querying OAI-PMH 
repositories. OAI-PMH is the Open Archives Initiative Protocol for Metadata 
Harvesting.  OAI-PMH allows data repositories to share metadata about their 
digital assets.  Net::OAI::Harvester is a OAI-PMH client, so it does for 
OAI-PMH what LWP::UserAgent does for HTTP. 

You create a Net::OAI::Harvester object which you can then use to 
retrieve metadata from a selected repository. Net::OAI::Harvester tries to keep 
things simple by providing an API to get at the data you want; but it also has 
a framework which is easy to extend should you need to get more fancy.

The guiding principle behind OAI-PMH is to allow metadata about online 
resources to be shared by data providers, so that the metadata can be harvested
by interested parties. The protocol is essentially XML over HTTP (much like 
XMLRPC or SOAP). Net::OAI::Harvester does XML parsing for you 
(using XML::SAX internally), but you can get at the raw XML if you want to do 
your own XML processing, and you can drop in your own XML::SAX handler if you 
would like to do your own parsing of metadata elements.

A OAI-PMH repository supports 6 verbs: GetRecord, Identify, ListIdentifiers, 
ListMetadataFormats, ListRecords, and ListSets. The verbs translate directly 
into methods that you can call on a Net::OAI::Harvester object. More details 
about these methods are supplied below, however for the real story please 
consult the spec at http://www.openarchives.org.

Net::OAI::Harvester has a few features that are worth mentioning:

=over 4

=item 1

Since the OAI-PMH results can be arbitrarily large, a stream based (XML::SAX) 
parser is used. As the document is parsed corresponding Perl objects are 
created (records, headers, etc), which are then serialized on disk (using 
Storable if you are curious). The serialized objects on disk can then be 
iterated over one at a time. The benefit of this is a lower memory footprint 
when (for example) a ListRecords verb is exercised on a repository that 
returns 100,000 records.


=item 2

XML::SAX filters are used which will allow interested developers to write 
their own metadata parsing packages, and drop them into place. This is useful
because OAI-PMH is itself metadata schema agnostic, so you can use OAI-PMH 
to distribute all kinds of metadata (Dublin Core, MARC, EAD, or your favorite
metadata schema). OAI-PMH does require that a repository at least provides 
Dublin Core metadata as a baseline. Net::OAI::Harvester has built in support for 
unqualified Dublin Core, and has a framework for dropping in your own parser 
for other kinds of metadata. If you create a XML::Handler that you would like 
to contribute back into the Net::OAI::Harvester project please get in touch! 

=back

=head1 METHODS

All the Net::OAI::Harvester methods return other objects. As you would expect 
new() returns an Net::OAI::Harvester object; similarly getRecord() returns an 
Net::OAI::Record object, listIdentifiers() returns a Net::OAI::ListIdentifiers 
object, identify() returns an Net::OAI::Identify object, and so on. So when 
you use one of these methods you'll probably want to check out the docs for 
the object that gets returned so you can see what to do with it. Many 
of these classes inherit from Net::OAI::Base which provides some base 
functionality for retrieving errors, getting the raw XML, and the 
temporary file where the XML is stored (see Net::OAI::Base documentation for
more details).

=head2 new()

The constructor which returns an Net::OAI::Harvester object. You must supply the
baseURL parameter, to tell Net::OAI::Harvester what data repository you are 
going to be harvesting. For a list of data providers check out the directory 
available on the Open Archives Initiative homepage.  

    my $harvester = Net::OAI::Harvester->new(
	baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0'
    );

If you want to pull down all the XML files and keep them in a directory, rather
than having the stored as transient temp files pass in the dumpDir parameter.

    my $harvester = Net::OAI::Harvester->new(
        baseUrl => 'http://memory.loc.gov/cgi-bin/oai2_0',
        dumpDir => 'american-memory'
    );

Also if you would like to fine tune the HTTP client used by Net::OAI::Harvester
you can pass in a configured object. For example this can be handy if you 
want to adjust the client timeout:

    my $ua = LWP::UserAgent->new();
    $ua->timeout(20); ## set timeout to 20 seconds
    my $harvester = Net::OAI::Harvester->new(
        baseURL     => 'http://memory.loc.gov/cgi-bin/oai2_0',
        userAgent   => $ua 
    );

=cut

sub new {
    my ( $class, %opts ) = @_;

    ## uppercase options
    my %normalOpts = map { ( uc($_), $opts{$_} ) } keys( %opts );
    
    ## we must be told a baseURL
    croak( "new() needs the baseUrl parameter" ) if !$normalOpts{ BASEURL };
    my $baseURL = URI->new( $normalOpts{ BASEURL } ); 

    my $self = bless( { baseURL => $baseURL }, ref( $class ) || $class );

    ## set the user agent
    if ( $normalOpts{ USERAGENT } ) { 
	$self->userAgent( $normalOpts{ USERAGENT } ); 
    } else {
	my $ua = LWP::UserAgent->new();
	$ua->agent( $class );
	$self->userAgent( $ua );
    }

    # set up some stuff if we are dumping xml to a directory
    if ($normalOpts{ DUMPDIR }) {
      my $dir = $normalOpts{ DUMPDIR };
      croak "no such directory '$dir'" unless -d $dir;
      $self->{ dumpDir } = $dir;
      $self->{ lastDump } = 0;
    }

    return( $self );
}

=head2 identify()

identify() is the OAI verb that tells a metadata repository to provide a 
description of itself. A call to identify() returns a Net::OAI::Identify object 
which you can then call methods on to retrieve the information you are 
intersted in. For example: 

    my $identity = $harvester->identify();
    print "repository name: ",$identity->repositoryName(),"\n";
    print "protocol version: ",$identity->protocolVersion(),"\n";
    print "earliest date stamp: ",$identity->earliestDatestamp(),"\n";
    print "admin email(s): ", join( ", ", $identity->adminEmail() ), "\n";
    ...

For more details see the L<Net::OAI::Identify> documentation.

=cut 

sub identify {
    my $self = shift;
    my $uri = $self->{ baseURL }->clone();
    $uri->query_form( 'verb' => 'Identify' );

    my $identity = Net::OAI::Identify->new( $self->_get( $uri ) );
    return $identity if $identity->{ error };

    my $error = Net::OAI::Error->new( Handler => $identity );
    my $parser = _parser( $error ); 
    debug( "parsing Identify response " .  $identity->file() );
    eval { $parser->parse_uri( $identity->file() ) };
    if ( $@ ) { _xmlError( $error ); } 
    $error->set_handler( undef );
    $identity->{ error } = $error;
    return( $identity );
}

=head2 listMetadataFormats()

listMetadataFormats() asks the repository to return a list of metadata formats 
that it supports. A call to listMetadataFormats() returns an 
Net::OAI::ListMetadataFormats object.

    my $list = $harvester->listMetadataFormats();
    print "archive supports metadata prefixes: ", 
	join( ',', $list->prefixes() ),"\n";

If you are interested in the metadata formats available for 
a particular resource identifier then you can pass in that identifier. 
    
    my $list = $harvester->listMetadataFormats( identifier => '1234567' );
    print "record identifier 1234567 can be retrieved as ",
	join( ',', $list->prefixes() ),"\n";

See documentation for L<Net::OAI::ListMetadataFormats> for more details.

=cut

sub listMetadataFormats {
    my ( $self, %opts ) = @_;
    my $uri = $self->{ baseURL }->clone();

    $uri->query_form( verb => 'ListMetadataFormats', 
        map { (defined $opts{$_}) ? ($_ => $opts{$_}) : () } qw( identifier )
      );

    my $list = Net::OAI::ListMetadataFormats->new( $self->_get( $uri ) );
    return $list if $list->{ error };

    my $error = Net::OAI::Error->new( Handler => $list );
    my $parser = _parser( $error );
    debug( "parsing ListMetadataFormats response: ".$list->file() );
    eval { $parser->parse_uri( $list->file() ) };
    if ( $@ ) { _xmlError( $error ); } 
    $error->set_handler( undef );
    $list->{ error } = $error;
    return( $list );
}

=head2 getRecord()

getRecord() is used to retrieve a single record from a repository. You must pass
in the C<identifier> and an optional C<metadataPrefix> parameters to identify 
the record, and the flavor of metadata you would like. Net::OAI::Harvester 
includes a parser for OAI DublinCore, so if you do not specifiy a 
metadataPrefix 'oai_dc' will be assumed. If you would like to drop in your own 
XML::Handler for another type of metadata use either the C<metadataHandler>
or the C<recordHandler> parameter, either the name of the class as string
or an already instantiated object of that class.

    my $result = $harvester->getRecord( 
	identifier	=> 'abc123',
    );

    ## did something go wrong?
    if ( my $oops = $result->errorCode() ) { ... };

    ## get the result as Net::OAI::Record object
    my $record = $result->record();     # undef if error

    ## directly get the Net::OAI::Record::Header object
    my $header = $result->header();     # undef if error
    ## same as
    my $header = $result->record()->header();     # undef if error

    ## get the metadata object 
    my $metadata = $result->metadata(); # undef if error or harvested with recordHandler

    ## or if you would rather use your own XML::Handler 
    ## pass in the package name for the object you would like to create
    my $result = $harvester->getRecord(
	identifier		=> 'abc123',
	metadataHandler		=> 'MyHandler'
    );
    my $metadata = $result->metadata();
    
    my $result = $harvester->getRecord(
	identifier		=> 'abc123',
	recordHandler		=> 'MyCompleteHandler'
    );
    my $complete_record = $result->recorddata(); # undef if error or harvested with metadataHandler
    
=cut 

sub getRecord {
    my ( $self, %opts ) = @_;

    croak( "getRecord(): the 'identifier' parameter is required" )
	unless defined $opts{ 'identifier' };
    croak( "getRecord(): the 'metadataPrefix' parameter is required" )
	unless exists $opts{ 'metadataPrefix' };
    croak( "getRecord(): recordHandler and metadataHandler are mutually exclusive" )
        if $opts{ recordHandler } and $opts{ metadataHandler };

    my $uri = $self->{ baseURL }->clone();

    $uri->query_form( verb => 'GetRecord', 
        map { (defined $opts{$_}) ? ($_ => $opts{$_}) : () } qw( identifier metadataPrefix )
      );

    my $record = Net::OAI::GetRecord->new( $self->_get( $uri ), 
	recordHandler => $opts{ recordHandler },
	metadataHandler => $opts{ metadataHandler },
        );
    return $record if $record->{ error };

    my $error = Net::OAI::Error->new( Handler => $record );
    my $parser = _parser( $error ); 
    debug( "parsing GetRecord response " . $record->file() );
    eval { $parser->parse_uri( $record->file() ) };
    if ( $@ ) { _xmlError( $error ); } 

    $error->set_handler( undef );
    $record->{ error } = $error;
    return( $record );

}


=head2 listRecords()

listRecords() allows you to retrieve all the records in a data repository. 
You must supply the C<metadataPrefix> parameter to tell your Net::OAI::Harvester
which type of records you are interested in. listRecords() returns an 
Net::OAI::ListRecords object. There are four other optional parameters C<from>, 
C<until>, C<set>, and C<resumptionToken> which are better described in the 
OAI-PMH spec. 

    my $records = $harvester->listRecords( 
	metadataPrefix	=> 'oai_dc'
    );

    ## iterate through the results with next()
    while ( my $record = $records->next() ) { 
	my $metadata = $record->metadata();
	...
    }

If you would like to use your own metadata handler then you can specify 
the package name of the handler as the C<metadataHandler> (will be exposed
to events below the C<metadata> element) or C<recordHandler> (will be
exposed to the C<record> element and all its children) parameter, passing
either

=over 4

=item the name of the class as string, in that case a new instance
will be created for any OAI record encountered or

=item an already instantiated object of that class which will 
be reused for all records. 

=back

    my $records = $harvester->listRecords(
	metadataPrefix	=> 'mods',
	metadataHandler	=> 'MODS::Handler'
    );

    while ( my $record = $records->next() ) { 
	my $metadata = $record->metadata();
	# $metadata will be a MODS::Handler object
    }

If you want to automatically handle resumption tokens you can achieve
this with the listAllRecords() method. In this case the C<next()> 
method transparently causes the next response to be fetched from
the repository if the current response ran out of records and 
contained a resumptionToken.

If you prefer you can handle resumption tokens yourself with a 
loop, and the resumptionToken() method. You might want to do this
if you are working with a repository that wants you to wait between
requests or if connectivity problems become an issue during particulary
long harvesting runs and you want to implement a retransmission
strategy for failing requests.

    my $records = $harvester->listRecords( metadataPrefix => 'oai_dc' );
    my $responseDate = $records->responseDate();
    my $finished = 0;

    while ( ! $finished ) {

	while ( my $record = $records->next() ) { # a Net::OAI::Record object
	    my $metadata = $record->metadata();
	    # do interesting stuff here 
	}

	my $rToken = $records->resumptionToken();
	if ( $rToken ) { 
	    $records = $harvester->listRecords( 
		resumptionToken => $rToken->token()
	    );
	} else { 
	    $finished = 1;
	}

    }

Please note: Since C<listRecords()> stashes away the individual
records it encounters with C<Storable>, special care has to 
be taken if the handlers you provided make use of XS modules
since these objects cannot be reliably handled. Therefore you will
have to provide the special serializing and deserializing methods
C<STORABLE_freeze()> and C<STORABLE_thaw()> for the objects
used by your filter(s).


=cut

sub listRecords {
    my ( $self, %opts ) = @_;

    croak( "listRecords(): the 'metadataPrefix' parameter is required" )
	unless ( exists $opts{ 'metadataPrefix' } 
              or defined $opts{ 'resumptionToken' } );
    croak( "listRecords(): recordHandler and metadataHandler are mutually exclusive" )
        if $opts{ recordHandler } and $opts{ metadataHandler };

    my $uri = $self->{ baseURL }->clone();

    $uri->query_form( verb => 'ListRecords', 
        map { (defined $opts{$_}) ? ($_ => $opts{$_}) : () } qw( metadataPrefix from until set resumptionToken )
      );

    my $list = Net::OAI::ListRecords->new( $self->_get( $uri ), 
	metadataHandler => $opts{ metadataHandler },
	recordHandler => $opts{ recordHandler },
        );
    return $list if $list->{ error };

    my $token = Net::OAI::ResumptionToken->new( Handler => $list );
    my $error = Net::OAI::Error->new( Handler => $token );
    my $parser = _parser( $error ); 
    debug( "parsing ListRecords response " . $list->file() );
    eval { $parser->parse_uri( $list->file() ) };
    if ( $@ ) { _xmlError( $error ); } 

    $token->set_handler( undef );
    $list->{ token } = $token->token() ? $token : undef;

    $error->set_handler( undef );
    $list->{ error } = $error;

    return( $list );
}

=head2 listAllRecords() 

Does exactly what listRecords() does except the C<next()> method 
will automatically submit resumption tokens as needed.

    my $records = $harvester->listAllRecords( metadataPrefix => 'oai_dc' );

    while ( my $record = $records->next() ) { # a Net::OAI::Record object until undef
	my $metadata = $record->metadata();
	# do interesting stuff here 
    }


=cut

sub listAllRecords {
    my $self = shift;
    debug( "calling listRecords() as part of listAllRecords request" );
    my $list = listRecords( $self, @_ );
    $list->{ harvester } = $self;
    return( $list );
}

=head2 listIdentifiers()

listIdentifiers() takes the same parameters that listRecords() takes, but it 
returns only the record headers, allowing you to quickly retrieve all the 
record identifiers for a particular repository. The object returned is a 
L<Net::OAI::ListIdentifiers> object.

    my $headers = $harvester->listIdentifiers( 
	metadataPrefix	=> 'oai_dc'
    );

    ## iterate through the results with next()
    while ( my $header = $identifiers->next() ) {  # a Net::OAI::Record::Header object
	print "identifier: ", $header->identifier(), "\n";
    }

If you want to automatically handle resumption tokens use listAllIdentifiers().
If you are working with a repository that encourages pauses between requests
you can handle the tokens yourself using the technique described above
in listRecords().

=cut

sub listIdentifiers {
    my ( $self, %opts ) = @_;
    croak( "listIdentifiers(): the 'metadataPrefix' parameter is required" )
	unless ( exists $opts{ 'metadataPrefix' } 
              or defined $opts{ 'resumptionToken' } );
    my $uri = $self->{ baseURL }->clone();

    $uri->query_form( verb => 'ListIdentifiers', 
        map { (defined $opts{$_}) ? ($_ => $opts{$_}) : () } qw( metadataPrefix from until set resumptionToken )
      );

    my $list = Net::OAI::ListIdentifiers->new( $self->_get( $uri ) );
    return( $list ) if $list->{ error };

    my $token = Net::OAI::ResumptionToken->new( Handler => $list );
    my $error = Net::OAI::Error->new( Handler => $token );
    my $parser = _parser( $error );
    debug( "parsing ListIdentifiers response " . $list->file() );
    eval { $parser->parse_uri( $list->file() ) };
    if ( $@ ) { _xmlError( $error ); } 

    $token->set_handler( undef );
    $list->{ token } = $token->token() ? $token : undef; 

    $error->set_handler( undef );
    $list->{ error } = $error;

    return( $list );
}

=head2 listAllIdentifiers()

Does exactly what listIdentifiers() does except C<next()> will automatically 
submit resumption tokens as needed.

=cut

sub listAllIdentifiers {
    my $self = shift;
    debug( "calling listIdentifiers() as part of listAllIdentifiers() call" );
    my $list = listIdentifiers( $self, @_ );
    $list->{ harvester } = $self;
    return( $list );
}


=head2 listSets()

listSets() takes an optional C<resumptionToken> parameter, and returns a 
Net::OAI::ListSets object. listSets() allows you to harvest a subset of a 
particular repository with listRecords(). For more information see the OAI-PMH 
spec and the Net::OAI::ListSets docs.

    my $sets = $harvester->listSets();
    foreach ( $sets->setSpecs() ) { 
	print "set spec: $_ ; set name: ", $sets->setName( $_ ), "\n";
    }

=cut

sub listSets {
    my ( $self, %opts ) = @_;

    my $uri = $self->{ baseURL }->clone();

    $uri->query_form( verb => 'ListSets', 
        map { (defined $opts{$_}) ? ($_ => $opts{$_}) : () } qw( resumptionToken )
      );

    my $list = Net::OAI::ListSets->new( $self->_get( $uri ) );
    return( $list ) if $list->{ error };

    my $token = Net::OAI::ResumptionToken->new( Handler => $list );
    my $error = Net::OAI::Error->new( Handler => $token );
    my $parser = _parser( $error );
    debug( "parsing ListSets response " . $list->file() );
    eval { $parser->parse_uri( $list->file() ) };
    if ( $@ ) { _xmlError( $error ); } 

    $token->set_handler( undef );
    $list->{ token } = $token->token() ? $token : undef;
    $error->set_handler( undef );
    $list->{ error } = $error;
    return( $list );
}

=head2 baseURL()

Gets or sets the base URL for the repository being harvested (as L<URI/>).

    $harvester->baseURL( 'http://memory.loc.gov/cgi-bin/oai2_0' );

Or if you want to know what the current baseURL is

    $baseURL = $harvester->baseURL();

=cut

sub baseURL {
    my ( $self, $url ) = @_;
    if ( $url ) { $self->{ baseURL } = URI->new( $url ); } 
## The HTTP UserAgent modifies its URI object upon execution,
## therefore we'll always provide a clone <s>have to reconstruct: trim the query part ...</s>
#    my $c = $self->{ baseURL };           # ->canonical();
#    if ( $c && ($c =~ /^([^\?]*)\?/) ) {  # $c might be undefined
#        return $1};
#    return $c;
    return $self->{ baseURL };
}

=head2 userAgent()

Gets or sets the LWP::UserAgent object being used to perform the HTTP
transactions. This method could be useful if you wanted to change the 
agent string, timeout, or some other feature.

=cut

sub userAgent {
    my ( $self, $ua ) = @_;
    if ( $ua ) { 
	$ua->isa('LWP::UserAgent') or croak( "userAgent() needs a valid LWP::UserAgent" );
	$self->{ userAgent } = $ua;
    }
    return( $self->{ userAgent } );
}

## internal stuff

sub _get {
    my ($self,$uri) = @_;
    my $ua = $self->{ userAgent };

    my ($fh, $file);
    if ( $self->{ dumpDir } ) {
        my $filePrefix = $self->{lastDump}++;
        $file = sprintf("%s/%08d.xml", $self->{dumpDir}, $filePrefix);
        $fh = IO::File->new($file, 'w');
    } else {
        ( $fh, $file ) = tempfile(UNLINK => 1);
    }

    debug( "fetching ".$uri->as_string() );
    debug( "writing to file: $file" );
    my $request = HTTP::Request->new( GET => $uri->as_string() );
    my $response = $ua->request( $request, sub { print $fh shift; }, 8192 );
    close( $fh );

    if ( $response->is_error() ) { 
# HTTP::Request does not provide a file in case of HTTP level errors,
# therefore we do not return the name of the non-existant file but
# rather the original HTTP::Response object
        debug( "caught HTTP level error" . $response->message() );
        my $error = Net::OAI::Error->new(
            errorString     => 'HTTP Level Error: ' . $response->message(),
            errorCode       => $response->code(),
            HTTPError       => $response,
            HTTPRetryAfter  => $response->header("Retry-After") || "",
        );
	return( 
#	    file	    => $file, 
            error           => $error
	);
    }
    if ( my $ct = $response->header("Content-Type") ) {
        debug( "Content-type $ct in HTTP response" );
        unless ( $ct =~ /^text\/xml(;|$)/ ) {
            return (error => Net::OAI::Error->new(errorCode => 'xmlContentError',
                                                errorString => "Content-Type: text/xml is mandatory (got: $ct)!"),
                                                  HTTPError => $response,
                                            HTTPRetryAfter  => $response->header("Retry-After") || "",
                   )
          };
        if ( $ct =~ /; charset=(\S+)/ ) {
            my $cs = $1;
            return (error => Net::OAI::Error->new(errorCode => 'xmlContentError',
                                                errorString => "charset=UTF-8 is mandatory (got: $cs)!"),
                                                  HTTPError => $response,
                                            HTTPRetryAfter  => $response->header("Retry-After") || "",
                   ) unless $cs =~ /^utf-8/i;
          };
    }

    return( 
	    file	    => $file,
    );

}

sub _parser {
    my $handler = shift;
    my $factory = XML::SAX::ParserFactory->new();
    my $parser;
    $factory->require_feature(Namespaces);
    eval { $parser = $factory->parser( Handler => $handler ) };
    carp ref($factory)." threw an exception:\n\t$@" if $@;

    if ( $parser && ref($parser) ) {
        debug( "using SAX parser " . ref($parser) . " " . $parser->VERSION );
        return $parser;
      };

    carp "!!! Please check your setup of XML::SAX, especially ParserDetails.ini !!!\n";
    local($XML::SAX::ParserPackage) = "XML::SAX::PurePerl";
    eval { $parser = $factory->parser( Handler => $handler ) };
    carp ref($factory)." threw an exception again:\n\t$@" if $@;
    if ( $parser && ref($parser) ) {
        carp "Successfuly forced assignment of a parser: " . ref($parser) . " " . $parser->VERSION ."\n";
        return $parser;
      };

    croak( ref($factory)." on request did not even give us the default XML::SAX::PurePerl parser.\nGiving up." );
}

sub _xmlError {
    my $e = shift;
    carp "caught xml parsing error: $@";
    $e->errorString( "XML parsing error: $@" );
    $e->errorCode( 'xmlParseError' );
}


sub _verifyHandler {
    my $package_or_instance = shift;
    if ( ref($package_or_instance) ) {
        $package_or_instance->isa('XML::SAX::Base')
            or _fatal( "Handler $package_or_instance must inherit from XML::SAX::Base\n" )
      }
    else {
        eval( "use $package_or_instance" );
        _fatal( "unable to locate Handler $package_or_instance in: " . 
	    join( "\n\t", @INC ) ) if $@; 
        _fatal( "Handler $package_or_instance must inherit from XML::SAX::Base\n" )
            if ( ! grep { 'XML::SAX::Base' } eval( '@' . $package_or_instance . '::ISA' ) );
      }
    return( 1 );
}


sub debug {
    return unless $Net::OAI::Harvester::DEBUG;
    my $msg = shift; 
    carp "oai-harvester: " . localtime() . ": $msg\n";
}

sub _fatal {
    my $msg = shift;
    croak "fatal: $msg";
}

=head1 DIAGNOSTICS

If you would like to see diagnostic information when harvesting is running 
then set Net::OAI::Harvester::DEBUG to a true value.

    $Net::OAI::Harvester::DEBUG = 1;




=head1 PERFORMANCE 

XML::SAX is used for parsing, but it presents a generalized interface to many 
parsers. It comes with XML::Parser::PurePerl by default, which is nice since
you don't have to worry about getting the right libraries installed. However
XML::Parser::PurePerl is rather slow compared to XML::LibXML. If you 
are a speed freak install XML::LibXML from CPAN today.

If you have a particular parser you want to use you can set the
$XML::SAX::ParserPackage variable appropriately. See XML::SAX::ParserFactory
documentation for details.



=head1 ENVIRONMENT

The modules use LWP for HTTP operations, thus C<PERL_LWP_ENV_PROXY> controls
wether the "_proxy" environment settings shall be honored.


=head1 TODO

=over 4 

=item *

Allow Net::OAI::ListMetadataFormats to store more than just the metadata
prefixes.

=item *

Implement Net::OAI::Set for iterator access to Net::OAI::ListSets.

=item *

Implement Net::OAI::Harvester::listAllSets().

=item * 

More documentation of other classes.

=item * 

Document custom XML::Handler creation.

=item * 

Handle optional compression.

=item * 

Create common handlers for other metadata formats (MARC, qualified DC, etc).

=item *

Or at least provide a generic record handler as fallback, since using
L<Net::OAI::Record::OAI_DC> makes absolutely no sense except for ... oai_dc records.

=item *

Selectively load Net::OAI::* classes as needed, rather than getting all of them 
at once at the beginning of Net::OAI::Harvester.

=back

=head1 SEE ALSO

=over 4

=item *

OAI-PMH Specification at L<http://www.openarchives.org>

=item *

L<Net::OAI::Base>

=item *

L<Net::OAI::Error>

=item *

L<Net::OAI::GetRecord>

=item *

L<Net::OAI::Identify>

=item *

L<Net::OAI::ListIdentifiers>

=item *

L<Net::OAI::ListMetadataFormats>

=item *

L<Net::OAI::ListRecords>

=item *

L<Net::OAI::ListSets>

=item *

L<Net::OAI::Record>

=item *

L<Net::OAI::Record::Header>

=item *

L<Net::OAI::Record::OAI_DC>

=item *

L<Net::OAI::Record::DocumentHelper>

=item *

L<Net::OAI::Record::NamespaceFilter>

=item *

L<Net::OAI::ResumptionToken>

=item *

L<Storable>

=back


=head1 AUTHORS

Ed Summers <ehs@pobox.com>

Martin Emmerich <Martin.Emmerich@oew.de>

Thomas Berger <ThB@gymel.com>

=head1 LICENSE

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

1;

