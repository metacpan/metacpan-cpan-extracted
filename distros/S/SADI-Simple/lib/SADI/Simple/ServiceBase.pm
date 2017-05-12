package SADI::Simple::ServiceBase;
{
  $SADI::Simple::ServiceBase::VERSION = '0.15';
}

use strict;
use warnings;

use SADI::Simple::ServiceDescription;
use Log::Log4perl;
use RDF::Trine::Parser 0.135;
use RDF::Trine::Model 0.135;
use RDF::Trine::Statement 0.135;

use base qw( SADI::Simple::Base );

use constant RDF_TYPE_URI => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';

sub new {

    my $class = shift;	
    my @args = @_;

    my $self = {};
    $self->{Signature} = SADI::Simple::ServiceDescription->new(@_);

    bless $self, ref($class) || $class;
    return $self; 

}

#-----------------------------------------------------------------
# process_it
#-----------------------------------------------------------------
sub process_it {
	my ( $self, $values, $service ) = @_;

	# subclass over-rides this
}

#-----------------------------------------------------------------
# as_uni_string
#-----------------------------------------------------------------
#use SADI::Data::String;
#use Unicode::String;
#
#sub as_uni_string {
#	my ( $self, $value ) = @_;
#	return new SADI::Data::String( Unicode::String::latin1($value) );
#}

#-----------------------------------------------------------------
# log_request
#
# should be called when a request from a client comes; it returns
# information about the current call (request) that can be used in a
# log entry
#-----------------------------------------------------------------

my @ENV_TO_REPORT =
  ( 'REMOTE_ADDR', 'REQUEST_URI' ,'HTTP_USER_AGENT', 'CONTENT_LENGTH', 'CONTENT_TYPE', 'HTTP_ACCEPT' );

sub log_request {
	my ($self) = shift;

	my @buf;
	foreach my $elem (@ENV_TO_REPORT) {
		push( @buf, "$elem: $ENV{$elem}" ) if exists $ENV{$elem};
	}
	return join( ", ", @buf );
}

#sub get_service_signature {
#	my ( $self, $name ) = @_;
#	my $sig = undef;
#	eval {
#		my $services = SADI::Generators::GenServices->new->read_services( $name, );
#		# iterate over the services (should be only 1)
#		foreach my $s (@$services) {
#			$sig = $s;
#			last;
#		}
#	};
#	$LOG->error("Problems retrieving service signature!\n$@") if $@;
#	return $sig if $sig;
#	$self->throw("Couldn't find a signature for '$name'!.");
#}

# returns the request content type
# defaults to application/rdf+xml
sub get_request_content_type {
	my ($self) = @_;
    my $CONTENT_TYPE = 'application/rdf+xml';
    if (defined $ENV{CONTENT_TYPE}) {
        $CONTENT_TYPE = 'text/rdf+n3' if $ENV{CONTENT_TYPE} =~ m|text/rdf\+n3|gi;
        $CONTENT_TYPE = 'text/rdf+n3' if $ENV{CONTENT_TYPE} =~ m|text/n3|gi;
        $CONTENT_TYPE = 'application/n-quads' if $ENV{CONTENT_TYPE} =~ m|application/n\-quads|gi;
        
    }
    return $CONTENT_TYPE;
}

# returns the response requested content type
# defaults to application/rdf+xml
sub get_response_content_type {
    my ($self) = @_;
    my $CONTENT_TYPE = 'application/rdf+xml';
    if (defined $ENV{HTTP_ACCEPT}) {
        $CONTENT_TYPE = 'text/rdf+n3' if $ENV{HTTP_ACCEPT} =~ m|text/rdf\+n3|gi;
        $CONTENT_TYPE = 'text/rdf+n3' if $ENV{HTTP_ACCEPT} =~ m|text/n3|gi;
        $CONTENT_TYPE = 'application/n-quads' if $ENV{HTTP_ACCEPT} =~ m|application/n\-quads|gi;
        
    }
    return $CONTENT_TYPE;
}

sub _build_model
{
    my ($self, $data, $content_type) = @_;

    my $parser;
    if ($self->get_request_content_type eq 'text/rdf+n3') {
        $parser = RDF::Trine::Parser->new('turtle');
    } else {
        $parser = RDF::Trine::Parser->new('rdfxml');
    }

    my $model = RDF::Trine::Model->temporary_model;
    $parser->parse_into_model(undef, $data, $model);

    return $model;
}

sub _get_inputs_from_model
{
    my ($self, $model) = @_;
    
#    my $type = new RDF::Trine::Node::Resource(RDF_TYPE_URI);
    my $type = new RDF::Trine::Node::Resource('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
    
    my $input_class = new RDF::Trine::Node::Resource($self->{Signature}->InputClass);

    return $model->subjects($type, $input_class);
}

sub _type_outputs
{
    my ($self, $output_model, $inputs) = @_;
#    my $rdf_type = new RDF::Trine::Node::Resource(RDF_TYPE_URI);
    my $rdf_type = new RDF::Trine::Node::Resource('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
    my $output_type = new RDF::Trine::Node::Resource($self->{Signature}->OutputClass);
    my %input_uri_hash = ();
    $input_uri_hash{$_->uri()} = 1 foreach @$inputs;
    my %visited_output_uris = ();
    foreach my $s ($output_model->subjects()) {
        next if $s->is_blank();
        my $uri = $s->uri();
        if ($input_uri_hash{$uri} && !$visited_output_uris{$uri}) {
            my $statement = RDF::Trine::Statement->new($s, $rdf_type, $output_type);
            if ($self->{'Signature'}->NanoPublisher){
	            $output_model->add_statement($statement, $s);  # need to add context here, for nanopublications        	
            } else {
	            $output_model->add_statement($statement);
            }
            $visited_output_uris{$uri} = 1;
        }
    }
}

use constant SERVICE_ERROR_TEMPLATE => <<TEMPLATE;
<rdf:RDF
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
     xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
     xmlns:sadi="http://sadiframework.org/ontologies/sadi.owl#">
  <sadi:Exception>
    <rdfs:label>[% message %]</rdfs:label>
    <rdfs:comment>[% comment %]</rdfs:comment>
    <sadi:hasStackTrace rdf:parseType="Collection">
      <sadi:StackTraceElement>
        <rdfs:label>[% stack %]</rdfs:label>
      </sadi:StackTraceElement>
    </sadi:hasStackTrace>
  </sadi:Exception>
</rdf:RDF>
TEMPLATE

sub _add_error_to_model
{
    my ($self, $model, $msg, $comment, $stack) = @_;

    my $LOG = Log::Log4perl->get_logger(__PACKAGE__);

    # generate from template
    my $error_rdf = '';
    my $tt = Template->new( ABSOLUTE => 1, TRIM => 1 );

    my $input = SERVICE_ERROR_TEMPLATE;

    $msg ||= '';
    $comment ||= '';
    $stack ||= '';
    
    use CGI;
    $tt->process(
                  \$input,
                  {
                     message  => CGI::escapeHTML($msg),
                     comment  => CGI::escapeHTML($comment),
                     stack    => CGI::escapeHTML($stack),
                  },
                  \$error_rdf
    ) || $LOG->logdie( $tt->error() );

    # if problem generating error doc, return
    return unless defined ($error_rdf);
    return if $error_rdf eq '';

    my $parser = RDF::Trine::Parser->new('rdfxml');
    $parser->parse_into_model(undef, $error_rdf, $model); 
}

1;

__END__

=head1 NAME

SADI::Simple::ServiceBase - a superclass for all SADI::Simple services

=head1 SYNOPSIS

 use base qw( SADI::Simple::ServiceBase )

=head1 DESCRIPTION

A common superclass for all SADI::Simple services.

=head1 SUBROUTINES

=head2 process_it

A job-level processing: B<This is the main method to be overriden by a
service provider!>. Here all the business logic belongs to.

This method is called once for each service invocation request.

Note that here, in C<SADI::Simple::ServiceBase>, this method does
nothing. Which means it leaves the output job empty, as it was given
here. Consequence is that if you do not override this method in a 
sub-class, the client will get back an empty request. Which may be 
good just for testing but not really what a client expects (I guess).

You are free to throw an exception (TBD: example here). However, if
you do so the complete processing of the whole client request is
considered failed. After such exception the client will not get any
data back (only an error message).

=head2 get_request_content_type

 # Returns the content type of the incoming data, defaults to application/rdf+xml.
 #
 # Possible values: 'application/rdf+xml', 'text/rdf+n3'

=head2 get_response_content_type

 # Returns the requested content type of the outgoing data, defaults to application/rdf+xml.
 #
 # Possible values: 'application/rdf+xml', 'text/rdf+n3', 'application/n-quads'

=head1 AUTHORS, COPYRIGHT, DISCLAIMER

 Ben Vandervalk (ben.vvalk [at] gmail [dot] com)
 Edward Kawas  (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)
 Mark Wilkinson (markw [at] illuminae [dot] com)

Copyright (c) 2009 Edward Kawas. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided "as is" without warranty of any kind.

=cut

