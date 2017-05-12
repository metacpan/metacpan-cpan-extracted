# SOAP::MIME Perl Module
# This is a patch of sorts to SOAP::Lite <http://soaplite.com/>
#
# Author: Byrne Reese <byrne@majordojo.com>
#
# TO DO:
# * SOAP::Lite is incredibly inefficient in its use of memory. It passed
#   most objects around by value, which inadvertently create copies of
#   everything. SOAP::Lite needs to pass around references, especially
#   when passing around things as potentially big as attachments.
package SOAP::MIME;

$VERSION=0.55;

BEGIN {

  # This is being added by Byrne to support attachments. I need to add
  # an array property to the SOAP::SOM object as a placeholder for 
  # decoded attachments. I add this getter/setting for attachments, and
  # I will then call this in SOAP::Deserializer to populate the SOM object
  # with the decoded attachments (MIME::Entity's)

  # This exposes any MIME::Entities that were parsed out of a MIME formatted
  # response.
  sub SOAP::SOM::parts {
    my $self = shift;
    @_ ? ($self->{_parts} = shift, return $self) : return $self->{_parts};
  }

  sub SOAP::Deserializer::deserialize {
    SOAP::Trace::trace('()');
    my $self = shift->new;

    # initialize 
    $self->hrefs({});
    $self->ids({});

    # TBD: find better way to signal parsing errors
    # This is returning a parsed body, however, if the message was mime
    # formatted, then the self->ids hash should be populated with mime parts

    # I think I am going to chunk this - and have the decode subroutine
    # parse the MIME::Entity objects into SOAP::SOM parts.
    my $parsed = $self->decode($_[0]); # TBD: die on possible errors in Parser?

    $self->decode_object($parsed);
    my $som = SOAP::SOM->new($parsed);

    # TODO
    # okay - here is a problem: on the server side it does not look like the
    # parts are properly parsed out, but it works client side
    # Latest - higher up the execution stack this is cool - parts are found. I
    # can even print them out. But when I get here, either a) I don't access them
    # properly, or b) they have been lost somehow.
    if ($self->mimeparser->{'_parts'}) {
      $som->{'_parts'} = $self->mimeparser->{'_parts'};
    }

    # if there are some IDs (from mime processing), then process others
    # otherwise delay till we first meet IDs
    if (keys %{$self->ids()}) {
      $self->traverse_ids($parsed);
    } else {
      $self->ids($parsed);
    }
    return $som;
  }

  sub SOAP::MIMEParser::DESTROY {
    my $self = shift;
    $self->{_parts} = undef;
  }

  sub SOAP::MIMEParser::get_multipart_id { (shift || '') =~ /^<?(.+)>?$/; $1 || '' }

  sub SOAP::MIMEParser::generate_random_string
    {
      my ($self,$len) = @_;
      my @chars=('a'..'z','A'..'Z','0'..'9','_');
      my $random_string;
      foreach (1..$len) {
	$random_string .= $chars[rand @chars];
      }
      return $random_string;
    }

  sub SOAP::MIMEParser::decode {
    my $self = shift;
    my $entity = eval { $self->parse_data(shift) }
      or die "Something wrong with MIME message: @{[$@ || $self->last_error]}\n";
    # I changed this to better populate the array with references 
    # to the MIME::Entity to prevent memory bloat
    for (my $i=1;$i<=$entity->parts;$i++) {
      push(@{$self->{_parts}},\$entity->parts($i))
	if ref($entity->parts($i)) eq "MIME::Entity";
    }
    my @result = ();
    if ($entity->head->mime_type eq 'multipart/form-data') {
      @result = $self->decode_form_data($entity);
    } elsif ($entity->head->mime_type eq 'multipart/related') {
      @result = $self->decode_related($entity);
    } elsif ($entity->head->mime_type eq 'text/xml') {
      @result = ();
    } else {
      die "Can't handle MIME messsage with specified type (@{[$entity->head->mime_type]})\n";
    }
    @result ? @result 
      : $entity->bodyhandle->as_string ? [undef, '', undef, $entity->bodyhandle->as_string]
	: die "No content in MIME message\n";
  }

  sub SOAP::MIMEParser::decode_related {
    my($self, $entity) = @_;
    my $start = SOAP::MIMEParser::get_multipart_id($entity->head->mime_attr('content-type.start'));
    my $location = $entity->head->mime_attr('content-location') || 'thismessage:/';
    my @result;
    foreach my $part ($entity->parts) {
      # SOAP::MIME comments:
      # Weird, the following use of head->get(SCALER[,INDEX]) doesn't work as
      # expected. Work around is to eliminate the INDEX.
      # my $pid = get_multipart_id($part->head->mime_attr('content-id',0));
      # my $plocation = $part->head->get('content-location',0) || '';
      # my $type = $part->head->mime_type || '';
      my $pid = SOAP::MIMEParser::get_multipart_id($part->head->mime_attr('content-id'));
      # If Content-ID is not supplied, then generate a random one (HACK - because
      # MIME::Entity does not do this as it should... content-id is required according
      # to MIME specification)
      $pid = $self->generate_random_string(10) if $pid eq '';
      my $type = $part->head->mime_type;
      # If a Content-Location header cannot be found, this will look for an
      # alternative in the following MIME Header attributes
      my $plocation = $part->head->get('content-location') ||
	$part->head->mime_attr('Content-Disposition.filename') ||
	  $part->head->mime_attr('Content-Type.name');
      if ($start && $pid eq $start) {
	unshift(@result, [$start, $location, $type, $part->bodyhandle->as_string]);
      } else {
	push(@result, [$pid, $plocation, $type, $part->bodyhandle->as_string]);
      }
    }
    die "Can't find 'start' parameter in multipart MIME message\n"
      if @result > 1 && !$start;
    @result;
  }

  # This exposes an accessor for setting and getting the MIME::Entities
  # that will be attached to the SOAP Envelope.
  sub SOAP::Lite::parts {
    my $self = shift;
    @_ ? ($self->{_parts} = \@_, return $self) : return $self->{_parts};
  }

  # This overrides the SOAP::Lite call subroutine used internally by
  # SOAP::Lite to marshall the request and make a call to the SOAP::Transport
  # module.
  sub SOAP::Lite::call {
    my $self = shift;

    return $self->{_call} unless @_;

    my $serializer = $self->serializer;

    die "Transport is not specified (using proxy() method or service description)\n"
      unless defined $self->proxy && UNIVERSAL::isa($self->proxy => 'SOAP::Client');

    my $top;
    my $headers=new HTTP::Headers();
    if ($self->parts) {
      $top = MIME::Entity->build(
				 'Type' => "Multipart/Related"
				);

      my @args = @_;
      $top->attach(
		   'Type'             => 'text/xml',
		   'Content-Transfer-Encoding' => '8bit',
		   'Content-Location' => '/main_envelope',
		   'Content-ID'       => '<main_envelope>',
		   'Data'             => $serializer->envelope(method => shift(@args), @args),
		  );

      foreach $a (@{$self->parts}) {
	$top->add_part($a);
      }

      my ($boundary) = $top->head->multipart_boundary;
      $headers->header('Content-Type' => 'Multipart/Related; type="text/xml"; start="<main_envelope>"; boundary="'.$boundary.'"');
    }

    $serializer->on_nonserialized($self->on_nonserialized);
    my $response = $self->transport->send_receive(
      endpoint => $self->endpoint,
      action   => scalar($self->on_action->($serializer->uriformethod($_[0]))),
                  # leave only parameters so we can later update them if required
      envelope => ($self->parts() ? $top->stringify_body : $serializer->envelope(method => shift, @_)),
      encoding => $serializer->encoding,
      headers  => $headers,
    );

    $self->parts(undef); # I need to reset this.

    return $response if $self->outputxml;

    # deserialize and store result
    my $result = $self->{_call} = eval { $self->deserializer->deserialize($response) } if $response;

    if (!$self->transport->is_success || # transport fault
        $@ ||                            # not deserializible
        # fault message even if transport OK 
        # or no transport error (for example, fo TCP, POP3, IO implementations)
        UNIVERSAL::isa($result => 'SOAP::SOM') && $result->fault) {
      return $self->{_call} = ($self->on_fault->($self, $@ ? $@ . ($response || '') : $result) || $result);
    }

    return unless $response; # nothing to do for one-ways

    # little bit tricky part that binds in/out parameters
    if (UNIVERSAL::isa($result => 'SOAP::SOM') &&
        ($result->paramsout || $result->headers) &&
        $serializer->signature) {
      my $num = 0;
      my %signatures = map {$_ => $num++} @{$serializer->signature};
      for ($result->dataof(SOAP::SOM::paramsout), $result->dataof(SOAP::SOM::headers)) {
        my $signature = join $;, $_->name, $_->type || '';
        if (exists $signatures{$signature}) {
          my $param = $signatures{$signature};
          my($value) = $_->value; # take first value
          UNIVERSAL::isa($_[$param] => 'SOAP::Data') ? $_[$param]->SOAP::Data::value($value) :
          UNIVERSAL::isa($_[$param] => 'ARRAY')      ? (@{$_[$param]} = @$value) :
          UNIVERSAL::isa($_[$param] => 'HASH')       ? (%{$_[$param]} = %$value) :
          UNIVERSAL::isa($_[$param] => 'SCALAR')     ? (${$_[$param]} = $$value) :
                                                       ($_[$param] = $value)
        }
      }
    }
    return $result;
  } # end of call()


  #
  # Added to add server-side attachment support
  # TO DO: in composing the response, I need to parse MIME::Entities that are returned...
  # breese - 3/17/2003
  sub SOAP::Server::handle {

    SOAP::Trace::trace('()');
    my $self = shift;

    # we want to restore it when we are done
    local $SOAP::Constants::DEFAULT_XML_SCHEMA = $SOAP::Constants::DEFAULT_XML_SCHEMA;

    # SOAP version WILL NOT be restored when we are done.
    # is it problem?

    my $result = eval {
      local $SIG{__DIE__};
      $self->serializer->soapversion(1.1);
      my $request = eval { $self->deserializer->deserialize($_[0]) };
      die SOAP::Fault
	->faultcode($SOAP::Constants::FAULT_VERSION_MISMATCH)
	  ->faultstring($@)
	    if $@ && $@ =~ /^$SOAP::Constants::WRONG_VERSION/;
      die "Application failed during request deserialization: $@" if $@;
      my $som = ref $request;
      die "Can't find root element in the message" unless $request->match($som->envelope);
      $self->serializer->soapversion(SOAP::Lite->soapversion);
      $self->serializer->xmlschema($SOAP::Constants::DEFAULT_XML_SCHEMA
				   = $self->deserializer->xmlschema)
	if $self->deserializer->xmlschema;

      die SOAP::Fault
	->faultcode($SOAP::Constants::FAULT_MUST_UNDERSTAND)
	  ->faultstring("Unrecognized header has mustUnderstand attribute set to 'true'")
	    if !$SOAP::Constants::DO_NOT_CHECK_MUSTUNDERSTAND &&
	      grep { $_->mustUnderstand && 
		       (!$_->actor || $_->actor eq $SOAP::Constants::NEXT_ACTOR)
		     } $request->dataof($som->headers);

      die "Can't find method element in the message" unless $request->match($som->method);

      my($class, $method_uri, $method_name) = $self->find_target($request);

      my @results = eval {
	local $^W;
	my @parameters = $request->paramsin;

	# SOAP::Trace::dispatch($fullname);
	SOAP::Trace::parameters(@parameters);

	push @parameters, $request 
	  if UNIVERSAL::isa($class => 'SOAP::Server::Parameters');

	SOAP::Server::Object->references(defined $parameters[0] &&
					 ref $parameters[0] &&
					 UNIVERSAL::isa($parameters[0] => $class)
		? do {
		  my $object = shift @parameters;
		  SOAP::Server::Object->object(ref $class ? $class : $object)
		      ->$method_name(SOAP::Server::Object->objects(@parameters)),
			# send object back as a header
			# preserve name, specify URI
			SOAP::Header
			    ->uri($SOAP::Constants::NS_SL_HEADER => $object)
			    ->name($request->dataof($som->method.'/[1]')->name)
		}
		: $class->$method_name(SOAP::Server::Object->objects(@parameters))
        );
      };
      SOAP::Trace::result(@results);

      # let application errors pass through with 'Server' code
      die ref $@ ?
	$@ : $@ =~ /^Can't locate object method "$method_name"/ ?
          "Failed to locate method ($method_name) in class ($class)" :
	    SOAP::Fault->faultcode($SOAP::Constants::FAULT_SERVER)->faultstring($@)
		if $@;

    return $self->serializer
      ->prefix('s') # distinguish generated element names between client and server
      ->uri($method_uri)
      ->envelope(response => $method_name . 'Response', @results);
  };

    # void context
    return unless defined wantarray;

    # normal result
    return $result unless $@;

    # check fails, something wrong with message
    return $self->make_fault($SOAP::Constants::FAULT_CLIENT, $@) unless ref $@;

    # died with SOAP::Fault
    return $self->make_fault($@->faultcode   || $SOAP::Constants::FAULT_SERVER,
			     $@->faultstring || 'Application error',
			     $@->faultdetail, $@->faultactor)
      if UNIVERSAL::isa($@ => 'SOAP::Fault');

    # died with complex detail
    return $self->make_fault($SOAP::Constants::FAULT_SERVER, 'Application error' => $@);

  } # end of handle()

} # end of BEGIN block

sub SOAP::Transport::HTTP::Server::make_response {
  my $self = shift;
  my($code, $response) = @_;

  my $encoding = $1
    if $response =~ /^<\?xml(?: version="1.0"| encoding="([^"]+)")+\?>/;
  $response =~ s!(\?>)!$1<?xml-stylesheet type="text/css"?>!
    if $self->request->content_type eq 'multipart/form-data';

  $self->options->{is_compress} ||=
    exists $self->options->{compress_threshold} && eval { require Compress::Zlib };

  my $compressed = $self->options->{is_compress} &&
    grep(/\b($COMPRESS|\*)\b/, $self->request->header('Accept-Encoding')) &&
      ($self->options->{compress_threshold} || 0) < SOAP::Utils::bytelength $response;
  $response = Compress::Zlib::compress($response) if $compressed;
  my ($is_multipart) = ($response =~ /content-type:.* boundary="([^\"]*)"/im);
  $self->response(HTTP::Response->new(
     $code => undef,
     HTTP::Headers->new(
			'SOAPServer' => $self->product_tokens,
			$compressed ? ('Content-Encoding' => $COMPRESS) : (),
			'Content-Type' => join('; ', 'text/xml',
					       !$SOAP::Constants::DO_NOT_USE_CHARSET &&
					       $encoding ? 'charset=' . lc($encoding) : ()),
			'Content-Length' => SOAP::Utils::bytelength $response),
     $response,
  ));
  $self->response->headers->header('Content-Type' => 'Multipart/Related; type="text/xml"; start="<main_envelope>"; boundary="'.$is_multipart.'"') if $is_multipart;
}

sub SOAP::Serializer::envelope {
  SOAP::Trace::trace('()');
  my $self = shift->new;
  my $type = shift;

  # SOAP::MIME added the attachments bit here
  my(@parameters, @header, @attachments);
  for (@_) { 
    defined $_ && ref $_ && UNIVERSAL::isa($_ => 'SOAP::Header') ?
      push(@header, $_) :
	UNIVERSAL::isa($_ => 'MIME::Entity') ?
	    push(@attachments, $_) :
	      push(@parameters, $_);
  }
  my $header = @header ? SOAP::Data->set_value(@header) : undef;
  my($body,$parameters);
  if ($type eq 'method' || $type eq 'response') {
    SOAP::Trace::method(@parameters);
    my $method = shift(@parameters) or die "Unspecified method for SOAP call\n";
    $parameters = @parameters ? SOAP::Data->set_value(@parameters) : undef;
    $body = UNIVERSAL::isa($method => 'SOAP::Data') 
      ? $method : SOAP::Data->name($method)->uri($self->uri);
    $body->set_value($parameters ? \$parameters : ());
  } elsif ($type eq 'fault') {
    SOAP::Trace::fault(@parameters);
    $body = SOAP::Data
      -> name(SOAP::Serializer::qualify($self->envprefix => 'Fault'))
    # commented on 2001/03/28 because of failing in ApacheSOAP
    # need to find out more about it
    # -> attr({'xmlns' => ''})
      -> value(\SOAP::Data->set_value(
        SOAP::Data->name(faultcode => SOAP::Serializer::qualify($self->envprefix => $parameters[0])),
        SOAP::Data->name(faultstring => $parameters[1]),
        defined($parameters[2]) ? SOAP::Data->name(detail => do{my $detail = $parameters[2]; ref $detail ? \$detail : $detail}) : (),
        defined($parameters[3]) ? SOAP::Data->name(faultactor => $parameters[3]) : (),
      ));
  } elsif ($type eq 'freeform') {
    SOAP::Trace::freeform(@parameters);
    $body = SOAP::Data->set_value(@parameters);
  } else {
    die "Wrong type of envelope ($type) for SOAP call\n";
  }

  $self->seen({}); # reinitialize multiref table
  my($encoded) = $self->encode_object(
    SOAP::Data->name(SOAP::Serializer::qualify($self->envprefix => 'Envelope') => \SOAP::Data->value(
      ($header ? SOAP::Data->name(SOAP::Serializer::qualify($self->envprefix => 'Header') => \$header) : ()),
      SOAP::Data->name(SOAP::Serializer::qualify($self->envprefix => 'Body')   => \$body)
    ))->attr($self->attr)
  );
  $self->signature($parameters->signature) if ref $parameters;

  # IMHO multirefs should be encoded after Body, but only some
  # toolkits understand this encoding, so we'll keep them for now (04/15/2001)
  # as the last element inside the Body 
  #                 v -------------- subelements of Envelope
  #                      vv -------- last of them (Body)
  #                            v --- subelements
  push(@{$encoded->[2]->[-1]->[2]}, $self->encode_multirefs) if ref $encoded->[2]->[-1]->[2];

  # SOAP::MIME magic goes here...
  if (@attachments) {
    my $top = MIME::Entity->build(
				  'Type' => "Multipart/Related"
				 );
    $top->attach(
		 'Type'             => 'text/xml',
		 'Content-Transfer-Encoding' => '8bit',
		 'Content-Location' => '/main_envelope',
		 'Content-ID'       => '<main_envelope>',
		 'Data'             => $self->xmlize($encoded)
		);
    foreach $a (@attachments) {
      $top->add_part($a);
    }
    # Each Transport layer is responsible for setting the proper top level MIME type with a
    # start="<main_envelope>" mime attribute.
    # my ($boundary) = $top->head->multipart_boundary;
    # $headers->header('Content-Type' => 'Multipart/Related; type="text/xml"; start="<main_envelope>"; boundary="'.$boundary.'"');
    return $top->stringify;
  }
  return $self->xmlize($encoded);
}


#############################################################################
# Many hacks and additional functionality tweaked to make this work. All code
# changes made by me to get this to work are identified by a 'MIME:' comment.
#
package SOAP::Transport::HTTP::Client;
use Compress::Zlib;
use SOAP::Transport::HTTP;

sub send_receive {
  my($self, %parameters) = @_;
  my($envelope, $endpoint, $action, $encoding, $headers) =
    @parameters{qw(envelope endpoint action encoding headers)};
  # MIME:                                            ^^^^^^^
  # MIME: I modified this because the transport layer needs access to the
  #       HTTP headers to properly set the content-type
  $endpoint ||= $self->endpoint;

  my $method='POST';
  $COMPRESS='gzip';
  my $resp;

  $self->options->{is_compress}
    ||= exists $self->options->{compress_threshold}
      && eval { require Compress::Zlib };

 COMPRESS: {

    my $compressed
      = !exists $SOAP::Transport::HTTP::Client::nocompress{$endpoint} &&
	$self->options->{is_compress} &&
	  ($self->options->{compress_threshold} || 0) < length $envelope;
    $envelope = Compress::Zlib::memGzip($envelope) if $compressed;

    while (1) {

      # check cache for redirect
      $endpoint = $SOAP::Transport::HTTP::Client::redirect{$endpoint}
	if exists $SOAP::Transport::HTTP::Client::redirect{$endpoint};
      # check cache for M-POST
      $method = 'M-POST'
	if exists $SOAP::Transport::HTTP::Client::mpost{$endpoint};

      my $req =
	HTTP::Request->new($method => $endpoint,
			   (defined $headers ? $headers : $HTTP::Headers->new),
      # MIME:              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      # MIME: This is done so that the HTTP Headers instance is properly
      #       created.
			   $envelope);
      $req->protocol('HTTP/1.1');

      $req->proxy_authorization_basic($ENV{'HTTP_proxy_user'},
				      $ENV{'HTTP_proxy_pass'})
	if ($ENV{'HTTP_proxy_user'} && $ENV{'HTTP_proxy_pass'});
      # by Murray Nesbitt

      if ($method eq 'M-POST') {
	my $prefix = sprintf '%04d', int(rand(1000));
	$req->header(Man => qq!"$SOAP::Constants::NS_ENV"; ns=$prefix!);
	$req->header("$prefix-SOAPAction" => $action) if defined $action;
      } else {
	$req->header(SOAPAction => $action) if defined $action;
      }

      # allow compress if present and let server know we could handle it
      $req->header(Accept => ['text/xml', 'multipart/*']);

      $req->header('Accept-Encoding' => 
		   [$SOAP::Transport::HTTP::Client::COMPRESS])
	if $self->options->{is_compress};
      $req->content_encoding($SOAP::Transport::HTTP::Client::COMPRESS)
	if $compressed;

      if(!$req->content_type){
	$req->content_type(join '; ',
			   'text/xml',
			   !$SOAP::Constants::DO_NOT_USE_CHARSET && $encoding ?
			   'charset=' . lc($encoding) : ());
      }elsif (!$SOAP::Constants::DO_NOT_USE_CHARSET && $encoding ){
	my $tmpType=$req->headers->header('Content-type');
	# MIME:     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	# MIME: This was changed from $req->content_type which was a bug,
	#       because it does not properly maintain the entire content-type
	#       header.
	$req->content_type($tmpType.'; charset=' . lc($encoding));
      }

      $req->content_length(length($envelope));
      SOAP::Trace::transport($req);
      SOAP::Trace::debug($req->as_string);

      $self->SUPER::env_proxy if $ENV{'HTTP_proxy'};

      $resp = $self->SUPER::request($req);

      SOAP::Trace::transport($resp);
      SOAP::Trace::debug($resp->as_string);

      # 100 OK, continue to read?
      if (($resp->code == 510 || $resp->code == 501) && $method ne 'M-POST') {
	$SOAP::Transport::HTTP::Client::mpost{$endpoint} = 1;
      } elsif ($resp->code == 415 && $compressed) { 
	# 415 Unsupported Media Type
	$SOAP::Transport::HTTP::Client::nocompress{$endpoint} = 1;
	$envelope = Compress::Zlib::memGunzip($envelope);
	redo COMPRESS; # try again without compression
      } else {
	last;
      }
    }
  }

  $SOAP::Transport::HTTP::Client::redirect{$endpoint} = $resp->request->url
    if $resp->previous && $resp->previous->is_redirect;

  $self->code($resp->code);
  $self->message($resp->message);
  $self->is_success($resp->is_success);
  $self->status($resp->status_line);

  my $content =
    ($resp->content_encoding || '') 
      =~ /\b$SOAP::Transport::HTTP::Client::COMPRESS\b/o &&
	$self->options->{is_compress} ? 
	  Compress::Zlib::memGunzip($resp->content)
	      : ($resp->content_encoding || '') =~ /\S/
		? die "Can't understand returned Content-Encoding (@{[$resp->content_encoding]})\n"
		  : $resp->content;
  $resp->content_type =~ m!^multipart/!
    ? join("\n", $resp->headers_as_string, $content) : $content;
}

##############################################################################
##############################################################################

1;

__END__

=head1 NAME

SOAP::MIME - Patch to SOAP::Lite to add attachment support. This module allows
Perl clients to both compose messages with attachments, and to parse messages
with attachments.

=head1 SYNOPSIS

SOAP::Lite (http://www.soaplite.com/) is a SOAP Toolkit that
allows users to create SOAP clients and services. As of
July 15, 2002, MIME support in SOAP::Lite was minimal. It could
parse MIME formatted messages, but the data contained in those
attachments was "lost."

This Perl module, patches SOAP::Lite so that users can not only send MIME
formatted messages, but also gain access to those MIME attachments that are
returned in a response.

=head1 TODO/ChangeLog

6/12/2002 - Need to add ability to compose and send attachments.
            FIXED on 7/15/2002
7/15/2002 - Ability to process attachments on the server side has not yet
            been tested.
7/26/2002 - Reworked the parsing of the response to return an array
            of MIME::Entity objects which enables to user to more fully
            utilize the functionality contained within that module
3/18/2003 - Added server-side attachment support for HTTP

=head1 REFERENCE

=over 8

=item B<SOAP::SOM::parts()>

Used to retrieve MIME parts returned in a response. The
subroutine parts() returns a I<reference> to an array of MIME::Entity
objects parsed out of a message.

=item B<SOAP::Lite::parts(ARRAY)>

Used to specify an array of MIME::Entities. These entities will be
attached to the SOAP message.

=back

=head1 EXAMPLES

=head2 Retrieving an Attachment

  use SOAP::Lite;
  use SOAP::MIME;

  my $soap = SOAP::Lite
    ->readable(1)
      ->uri($NS)
	->proxy($HOST);
  my $som = $soap->foo();

  foreach my $part (${$som->parts}) {
    print $part->stringify;
  }

=head2 Sending an Attachment

  use SOAP::Lite;
  use SOAP::MIME;
  use MIME::Entity;

  my $ent = build MIME::Entity
    Type        => "image/gif",
    Encoding    => "base64",
    Path        => "somefile.gif",
    Filename    => "saveme.gif",
    Disposition => "attachment";

  my $som = SOAP::Lite
    ->readable(1)
    ->uri($SOME_NAMESPACE)
    ->parts([ $ent ])
    ->proxy($SOME_HOST)
    ->some_method(SOAP::Data->name("foo" => "bar"));

=head2 Responding (server-side) with an Attachment

  sub echo {
    my $self = shift;
    my $envelope = pop;
    my $ent = build MIME::Entity
	'Id'          => "<1234>",
	'Type'        => "text/xml",
	'Path'        => "examples/attachments/some2.xml",
	'Filename'    => "some2.xml",
	'Disposition' => "attachment";
    return SOAP::Data->name("foo" => $STRING),$ent;
  }

=head1 SEE ALSO

L<SOAP::Lite>, L<MIME::Entity>
