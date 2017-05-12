package SADI::Simple;

our $VERSION = '0.15';
# ABSTRACT: Module for creating Perl SADI services

1;

__END__

=head1 NAME

    SADI::Simple - Module for creating Perl SADI services.

=head1 SYNOPSIS

The following code is a complete implementation of a 'Hello, World!' SADI service as a Perl CGI
script. 

    #!/usr/bin/perl
    
    package HelloWorld;

    use strict;
    use warnings;
    
    #-----------------------------------------------------------------
    # CGI HANDLER PART
    #-----------------------------------------------------------------
    
    use Log::Log4perl qw(:easy);
    use base 'SADI::Simple::AsyncService'; # or 'SADI::Simple::SyncService'
    
    Log::Log4perl->easy_init($WARN);
    
    my $config = {
        ServiceName => 'HelloWorld',
        Description => 'A \'Hello, World!\' service',
        InputClass => 'http://sadiframework.org/examples/hello.owl#NamedIndividual',
        OutputClass => 'http://sadiframework.org/examples/hello.owl#GreetedIndividual',   
        Authority => 'sadiframework.org', 
        URL => 'http://somewhere.net/', 
        Provider => 'myaddress@organization.org',
        ServiceType => 'http://edamontology.org/retrieval',
        Authoritative => 0,
        NanoPublisher => 1,
    };
    
    my $service = HelloWorld->new(%$config);
    $service->handle_cgi_request;
    
    #-----------------------------------------------------------------
    # SERVICE IMPLEMENTATION PART
    #-----------------------------------------------------------------
    
    use RDF::Trine::Node::Resource;
    use RDF::Trine::Node::Literal;
    use RDF::Trine::Statement;
    use Log::Log4perl;
    
    =head2 process_it
    
     Function: implements the business logic of a SADI service
     Args    : $inputs - ref to an array of RDF::Trine::Node::Resource
               $input_model - an RDF::Trine::Model containing the input RDF data
               $output_model - an RDF::Trine::Model containing the output RDF data
     Returns : nothing (service output is stored in $output_model)
    
    =cut
    
    sub process_it {
    
        my ($self, $inputs, $input_model, $output_model) = @_;
    
        my $name_property = RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name');
        my $greeting_property = RDF::Trine::Node::Resource->new('http://sadiframework.org/examples/hello.owl#greeting');
    
        foreach my $input (@$inputs) {
            
            INFO(sprintf('processing input %s', $input->uri));
    
            my ($name) = $input_model->objects($input, $name_property);
    
            if (!$name || !$name->is_literal) {
                WARN('skipping input %s, doesn\'t have a <%s> property with a literal value');
                next;
            }
    
            my $greeting = sprintf("Hello, '%s'!", $name->value);
            my $greeting_literal = RDF::Trine::Node::Literal->new($greeting);
            
            my $statement = RDF::Trine::Statement->new($input, $greeting_property, $greeting_literal);
            
            $output_model->add_statement($statement, $input);  # this second parameter is required for NanoPublishing
            # every statement added to the output model must include $input as the second parameter
            # in order for all of the statements to be in the same Assertion graph
            
            # $output_model->add_statement($statement); # non nanopublishers may omit the second parameter
    
    		# if you are a NanoPublisher then add this line, at the end of the @inputs loop
    		# it will be ignored for non-nanopublishers (i.e. optional)
    		$output_model->nanopublish_result_for($input);
        }
    
    }

=head1 DESCRIPTION

This module provides classes for implementing SADI services in Perl. SADI
(Semantic Automated Discovery and Integration) is a standard for implementing Web 
services that natively consume and generate RDF.  

Key points of SADI standard: 

=over

=item * 

A SADI service consumes a single RDF document as input and generates a single RDF document as output.
The input RDF document may contain multiple input instances (i.e. graphs) representing separate
invocations of the service.

=item * 

A SADI service is invoked by an HTTP POST to the service URL, using an RDF document as the POSTDATA.

=item * 

The structure of the input/output instances for a SADI service are described using OWL. 
The service provider publishes one input OWL class and one output OWL class which describe the 
structure of an input instance and an output instance, respectively.

=item * 

Metadata for a SADI service is retrieved by an HTTP GET on the service URL.  This metadata includes the
URIs of the input and output OWL classes, as well as other information such as the service name, service
description, etc.

=back

The main strengths of SADI are:

=over

=item * 

No framework-specific messaging formats or ontologies are required for using SADI.

=item * 

SADI supports processing multiple inputs in a single request, i.e. batch processing.

=item * 

SADI supports long-running services, i.e. asynchronous services.

=back

For more information about the SADI standard, see L<http://sadiframework.org>.

=head1 SYNCHRONOUS SERVICES VS ASYNCHRONOUS SERVICES

Service providers may implement their SADI services as a subclass of either:

=over

=item C<SADI::Simple::SyncService>

A service that subclasses C<SADI::Simple::SyncService> is a 
synchronous service, which means that the service completes its computation before
returning any response to the caller. 

=item C<SADI::Simple::AsyncService>

A service that subclasses C<SADI::Simple::AsyncService> is a
an asynchronous service, which means that the service returns an immediate "ask me later"
response to a request, and must be polled for the results.

=back

In general, asynchronous services are a better choice as they can run for an arbitarily long
time. The main advantage of synchronous services is that there is less back-and-forth messaging
and so they are potentially more efficient for services that perform trivial operations.

=head1 Service Configuration Parameters

=head2 Required parameters:

=over 

=item C<ServiceName>

A human-readable name for your service.

=item C<Description>

A plain text description of your service.

=item C<InputClass>

The URI of the service's C<input OWL class>. The input OWL class describes the required properties (i.e. predicates) 
of each input RDF node. In the example of the SYNOPSIS, there is one required property (C<http://xmlns.com/foaf/0.1/name>).

=item C<OutputClass>

The URI of the service's C<output OWL class>. The output OWL class describes the properties (i.e. predicates) 
that are attached each input RDF node, as a result of the service's computation.  In the example of the SYNOPSIS,
there is one attached property (C<http://sadiframework.org/examples/hello.owl#greeting>).

=item C<Authority>

The hostname of the organization providing the service (e.g. sadiframework.org).

=item C<Provider>

The contact email address of the service provider, in case of questions / problems.

=back

=head2 Optional parameters:

=over 

=item C<URL>

The URL used to access your service. It is necessary to provide this parameter if the service is asynchronous
and sits behind proxies/redirects, to ensure that the polling URLs returned by the service are publicly accessible. 


=item C<ServiceType>

A URI indicating the type of service. Ideally, this URI should come from a public ontology of service types, such as the 
L<http://www.mygrid.org.uk/tools/service-management/mygrid-ontology/ myGrid ontology> for bioinformatics services.
Specifying this parameter can potentially help other SADI users find your service. 


=back

=cut

