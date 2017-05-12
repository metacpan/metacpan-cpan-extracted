package SADI::Simple::SyncService;
{
  $SADI::Simple::SyncService::VERSION = '0.15';
}

use SADI::Simple::Utils;
use SADI::Simple::OutputModel;
use RDF::Trine::Model 0.135;
use RDF::Trine::Parser 0.135;
use Log::Log4perl;
use Template;
use Encode;

use base 'SADI::Simple::ServiceBase';

sub handle_cgi_request {

    my $self = shift;

    # if this is a GET, send the service interface
    if ($ENV{REQUEST_METHOD} eq 'GET' or $ENV{REQUEST_METHOD} eq 'HEAD') {

        my $q = new CGI;
        print $q->header(-type=>$self->get_response_content_type());
        print $self->{Signature}->getServiceInterface($self->get_response_content_type());

    } else {
        # get the posted data
        my $data = join "",<STDIN>;

        # call the service
        my ($output, $success) =  $self->invoke($data);

        my $q = new CGI;

        if(!$success) {
            print $q->header(-status => 500);
            print $output;
        }
        if(($self->get_response_content_type =~ /quads/i) && !($self->{Signature}->NanoPublisher)){
			print $q->header(-status => 406, -type => "application/rdf-xml");
			print $output;
        } else {
	        # print the results
	        print $q->header(-type => $self->get_response_content_type());
	        print $output;        	
        }


    }

}

# Please keep this, I am expecting it to be useful in future versions.
# This method has not been tested yet.

#sub plack_app {
#
#    my $self = shift;
#
#    return sub {
#
#        my $env = shift;
#        
#        my $status;
#        my $headers = [];
#        my $body = [];
#
#        push(@$headers, 'Content-type', $self->get_response_content_type());
#
#        my $request = Plack::Request->new($env);
#
#        if ($request->method eq 'GET' || $request->method eq 'HEAD') {
#
#            my $content_type = SADI::Simple::Utils->get_standard_content_type($env);
#            push(@$body, $self->{Signature}->getServiceInterface($content_type));
#            return [200, $headers, $body];
#
#        } else {
#
#            my $data = decode($request->content_encoding, $request->content);
#            push(@$body, $self->invoke($data));
#            return [200, $headers, $body]; 
#
#        }
#
#    } 
#    
#}

sub invoke {

    my ($self, $data) = @_;

    my $success = 1;
    my $LOG = Log::Log4perl->get_logger(__PACKAGE__);

    Log::Log4perl::NDC->push ($$);
    $LOG->info ('*** REQUEST START *** ' . "\n" . $self->log_request);
    $LOG->debug ("Input raw data (first 1000 characters):\n" . substr ($data, 0, 1000)) if $LOG->is_debug;

    $self->default_throw_with_stack (0);

    my $input_model;
    my $output_model;
#    if ($self->get_response_content_type =~ /quads/i){
	    $output_model = SADI::Simple::OutputModel->new();  # catches quad statements necessary for NanoPubs
	    $output_model->_init($self);
#    } else {
#	    $output_model = RDF::Trine::Model->temporary_model;	
#   }

    # get/parse the incoming RDF
    eval {
        $input_model = $self->_build_model($data, $self->get_request_content_type);
    };

    # error in creating parser, or parsing input
    if ($@) {
        $success = 0;
		# construct an outgoing message
		my $stack = $self->format_stack ($@);
        #$self->_add_error_to_model($output_model, $@, 'Error parsing input message for sadi service!', $stack);
        $LOG->error ($stack);
		$LOG->info ('*** FATAL ERROR RESPONSE BACK ***');
		Log::Log4perl::NDC->pop();
        #SADI::Simple::Utils->serialize_model($output_model, $self->get_response_content_type);
        return ("Error parsing input RDF: $@", $success); 
    }
	
    # do something (this service main task)
    eval { 
    	my @inputs = $self->_get_inputs_from_model($input_model);
    	$self->process_it(\@inputs, $input_model, $output_model);
        $self->_type_outputs($output_model, \@inputs);
    };
    # error thrown by the implementation class
    if ($@) {
        $success = 0;
		my $stack = $self->format_stack ($@);
		$self->_add_error_to_model($output_model, $@, 'Error running sadi service!', $stack);
		$LOG->error ($stack);
		$LOG->info ('*** REQUEST TERMINATED RESPONSE BACK ***');
		Log::Log4perl::NDC->pop();
        my $output = SADI::Simple::Utils->serialize_model($output_model, $self->get_response_content_type);
        
        return ($output, $success);
    }

    # return result
    $LOG->info ('*** RESPONSE READY *** ');

    Log::Log4perl::NDC->pop();
    my $output;
    if(($self->get_response_content_type =~ /quads/i) && !($self->{Signature}->NanoPublisher)){    		
			$output = SADI::Simple::Utils->serialize_model($output_model, 'rdfxml');
    } else {
	        $output = SADI::Simple::Utils->serialize_model($output_model, $self->get_response_content_type);     	
    }

   
    return ($output, $success);
}

1;

__END__

=head1 NAME

SADI::Simple::SyncService - a superclass for all synchronous SADI services

=head1 SYNOPSIS

 use base qw( SADI::Simple::SyncService )

=head1 DESCRIPTION

A common superclass for all SADI::Simple services.

=head1 SUBROUTINES

=head2 process_it

A job-level processing: B<This is the main method to be overriden by a
service provider!>. Here all the business logic belongs to.

This method is called once for each service invocation request.

Note that here, in C<SADI::Simple::SyncService>, this method does
nothing. Which means it leaves the output job empty, as it was given
here. Consequence is that if you do not override this method in a 
sub-class, the client will get back an empty request. Which may be 
good just for testing but not really what a client expects (I guess).

You are free to throw an exception (TBD: example here). However, if
you do so the complete processing of the whole client request is
considered failed. After such exception the client will not get any
data back (only an error message).

=head1 AUTHORS, COPYRIGHT, DISCLAIMER

 Ben Vandervalk (ben.vvalk [at] gmail [dot] com)
 Edward Kawas  (edward.kawas [at] gmail [dot] com)

Copyright (c) 2009 Edward Kawas. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided "as is" without warranty of any kind.

=cut


