package SADI::Simple::AsyncService;
{
  $SADI::Simple::AsyncService::VERSION = '0.15';
}

use strict;
use warnings;

use SADI::Simple::ServiceDescription;
use SADI::Simple::Utils;
use SADI::Simple::OutputModel;

use Log::Log4perl;

use POSIX qw(setsid);
use Data::Dumper;

use RDF::Trine::Model 0.135;
use RDF::Trine::Serializer 0.135;
use RDF::Trine::Parser 0.135;
use RDF::Trine::Node::Resource 0.135;
use Template;
use File::Spec;
use File::Spec::Functions qw(catfile splitpath);
use File::Temp qw(tempfile);
use Storable ();

use base 'SADI::Simple::ServiceBase';


# in seconds
use constant POLL_INTERVAL => 30;

use constant POLLING_RDF_TEMPLATE => <<TEMPLATE;
<rdf:RDF
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
     xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
[% FOREACH uri IN inputURIs %]
   <rdf:Description rdf:about="[% uri %]">
     <rdf:type rdf:resource="[% outClass %]"/>
     <rdfs:isDefinedBy rdf:resource="[% url %]"/>
  </rdf:Description>
[% END %]
</rdf:RDF>
TEMPLATE

use constant NOT_FINISHED => 0;
use constant SUCCESS => 1;
use constant ERROR => 2;

sub handle_cgi_request
{
    my $self = shift;

    if ($ENV{REQUEST_METHOD} eq 'GET' or $ENV{REQUEST_METHOD} eq 'HEAD') {

        my $q = new CGI;
        
        # print the interface unless we are polling
        do {
            print $q->header(-type=>$self->get_response_content_type());
            print $self->{Signature}->getServiceInterface($self->get_response_content_type());
            return;
        } unless $q->param('poll');

        # we are polling ... 
        # $poll is the id for our file store
        my $poll = $q->param('poll');
        my $status;
        eval {$status = $self->status($poll);};
        # do something if $@
        print $q->header(-status=>"404 nothing found for the given polling parameter" ) if $@;
        return if $@;
        if ($status != NOT_FINISHED) {
            # we are done
            my $output;
            eval {$output = $self->retrieve($poll);};
            my $http_status = ($status == SUCCESS) ? 200 : 500;
            unless ($@) {
                print $q->header(-status => $http_status, -type => $self->get_response_content_type());
                print $output;
                return;
            }
        } else {
            # still waiting
            my $signature = $self->{Signature};
            print $q->redirect(-uri=>$self->get_polling_url($poll), -status=>302, -Retry_After=>POLL_INTERVAL);
            return;
        }
    } else {
        # call the service

        # get the posted data
        my $data = join "",<STDIN>;

        # call the service
        my ($poll_id, $input_uris, $error_msg) = $self->invoke($data);

        my $q = new CGI;

        if (!defined($poll_id)) {
            print $q->header(-status => 500);
            print $error_msg;
            return;
        }

        print $q->header(
            -type=>$self->get_response_content_type(),
            -status=>202,
            -Retry_After=>POLL_INTERVAL
        );
        
        print $self->get_polling_rdf($poll_id, @$input_uris);
    }

}

sub get_polling_url
{
   my ($self, $poll_id) = @_;

   my $base_url = $self->{Signature}->URL || CGI::url();
   return ($base_url . '?poll=' . $poll_id);    
}

#-----------------------------------------------------------------
# store
#   saves the state of our service invocation given a $uid.
# throws exception if there are any problems saving data to disk.
#----------------------------------------------------------------- 

sub store {

    my ($self, $output_model, $status, $poll_id) = @_;

    my $quads;

    if(($self->get_response_content_type =~ /quads/i) && ($self->{Signature}->NanoPublisher)){
			$quads = SADI::Simple::Utils->serialize_model($output_model, $self->get_response_content_type);

    } 
    my $output = SADI::Simple::Utils->serialize_model($output_model, 'application/rdf+xml');

    my %hash;
    
    $hash{rdfxml} = $output;
    $hash{quads} = $quads;
    $hash{status} = $status;

    my $filename = $self->_poll_id_to_filename($poll_id);
    Storable::store(\%hash, $filename) or $self->throw("unable to store state to $filename");

}

sub _poll_id_to_filename
{
    my ($self, $poll_id) = @_;
    return catfile(File::Spec->tmpdir(), $poll_id);
}

#-----------------------------------------------------------------
# retrieve
#   given a $uid, retrieves the current saved state for our service
#   invocation
# NOTE: if a value is retrieved, then it removed from the cache
#----------------------------------------------------------------- 
sub retrieve {

    my ($self, $poll_id) = @_;
    my $log = Log::Log4perl->get_logger(__PACKAGE__);
    my $filename = $self->_poll_id_to_filename($poll_id);

    my $hashref = Storable::retrieve($filename) or $self->throw("no data stored for poll_id $poll_id");
    my $rdfxml = $hashref->{rdfxml};
    my $quads = $hashref->{quads};

    unlink($filename) or $log->warn("failed to removed tempfile $filename: $!");

    if ($self->get_response_content_type eq 'text/rdf+n3') {
        return SADI::Simple::Utils->rdfxml_to_n3($rdfxml);
    } elsif ($self->get_response_content_type eq 'application/n-quads'){
    	return $quads
    } else {
	    return $rdfxml;     	
    }

}

#-----------------------------------------------------------------
# completed
#   given a $uid, retrieves the current state our service
#   invocation. a Perl true value if completed, 0 | undef otherwise.
# Throws exception if there is nothing to retrieve for the given $uid
#----------------------------------------------------------------- 
sub status {

    my ($self, $poll_id) = @_;

    my $filename = $self->_poll_id_to_filename($poll_id);
    my $hashref = Storable::retrieve($filename) or $self->throw("no data stored for poll_id $poll_id");
    return $hashref->{status};

}

#-----------------------------------------------------------------
# [% obj.ServiceName %]
#   the main method; corresponds to the name of this SADI web service
#----------------------------------------------------------------- 

sub invoke {

    my ($self, $data) = @_;

    my $error_msg;
    my $log = Log::Log4perl->get_logger(__PACKAGE__);

    Log::Log4perl::NDC->push ($$);

    $log->info ('*** REQUEST START *** ' . "\n" . $self->log_request);
    $log->debug ("Input raw data (first 1000 characters):\n" . substr ($data, 0, 1000)) if ($log->is_debug);
    
    $self->default_throw_with_stack (0);

    my $input_model;
    my $output_model; 
    #$output_model = RDF::Trine::Model->temporary_model;
	$output_model = SADI::Simple::OutputModel->new();  # catches quad statements necessary for NanoPubs
	$output_model->_init($self);


    my @inputs; 
    my @input_uris = ();
    
    # save the input URIs for polling RDF
    eval {   
        $input_model = $self->_build_model($data, $self->get_request_content_type);
        @inputs = $self->_get_inputs_from_model($input_model);

        push @input_uris, $_->uri foreach @inputs;
    };

    # error in creating parser, or parsing input
    if ($@) {
		my $stack = $self->format_stack ($@);
#        $self->_add_error_to_model($output_model, $@, 'Error parsing input message for sadi service!', $stack);
        $log->error ($stack);
		$log->info ('*** FATAL ERROR RESPONSE BACK ***');
		Log::Log4perl::NDC->pop();
#        $self->store($output_model, ERROR, $poll_id);
		return (undef, undef, "Error parsing input RDF: $@");
    }

    my ($fh, $filename) = tempfile(
                            TEMPLATE => 'sadi-XXXXXXXX', 
                            TMPDIR => 1,
                            UNLINK => 0,  # we do this in retrieve()
                        );

    close($fh) or $self->throw($!);

    my $poll_id = (splitpath($filename))[2];

    unless (defined( my $pid = fork() )) {
    } elsif ($pid == 0) {

        # Daemonize 

        # note: untie does no harm if the filehandle is not tied,
        # but prevents potential errors if STDIN/STDOUT/STDERR is
        # tied to a class that doesn't implement OPEN

        untie *STDIN;
        open STDIN, File::Spec->devnull;
        untie *STDOUT;
        open STDOUT, File::Spec->devnull;
        untie *STDERR;
        open STDERR, File::Spec->devnull;
        setsid unless ($^O eq 'MSWin32');
    
        # child process
        # do something (this service main task)
        eval {
            # save empty output model before we begin
            $self->store($output_model, NOT_FINISHED, $poll_id);
            $self->process_it(\@inputs, $input_model, $output_model);
            $self->_type_outputs($output_model, \@inputs);
        };
        # error thrown by the implementation class
        if ($@) {
    		my $stack = $self->format_stack ($@);
            $self->_add_error_to_model($output_model, $@, 'Error running sadi service!', $stack);
            $log->error ($stack);
    		$log->info ('*** REQUEST TERMINATED RESPONSE BACK ***');
    		Log::Log4perl::NDC->pop();
    		# signal that we are done
            $self->store($output_model, ERROR, $poll_id);
    		return ;
        }
        
        # return result
        $log->info ('*** RESPONSE READY *** ');

        Log::Log4perl::NDC->pop();
        $self->store($output_model, SUCCESS, $poll_id);

        exit 0;
    } 

    return ($poll_id, \@input_uris);
}

sub get_polling_rdf 
{
    my ($self, $poll_id, @input_uris) = @_;

    my $log = Log::Log4perl->get_logger(__PACKAGE__);

    my $tt = Template->new( ABSOLUTE => 1, TRIM => 1 );
    my $input = POLLING_RDF_TEMPLATE;
    my $signature = $self->{Signature};
    my $polling_rdf;

    $tt->process(
                  \$input,
                  {
                     inputURIs     => \@input_uris,
                     outClass      => $signature->OutputClass, 
                     url           => $self->get_polling_url($poll_id),
                  },
                  \$polling_rdf
    ) || $log->logdie( $tt->error() );

    if ($self->get_response_content_type() eq 'text/rdf+n3') {
        return SADI::Simple::Utils->rdfxml_to_n3($polling_rdf);
    }

    return $polling_rdf;
}

1;

__END__

=head1 NAME

SADI::Simple::AsyncService - a superclass for asynchronous SADI services

=head1 SYNOPSIS

 use base qw( SADI::Simple::AsyncService )

=head1 DESCRIPTION

A common superclass for all SADI::Simple services.

=head1 SUBROUTINES

=head2 process_it

A job-level processing: B<This is the main method to be overriden by a
service provider!>. Here all the business logic belongs to.

This method is called once for each service invocation request.

Note that here, in C<SADI::Simple::AsyncService>, this method does
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

