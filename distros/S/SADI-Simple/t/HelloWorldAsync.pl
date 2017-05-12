#!/usr/bin/perl

#-----------------------------------------------------------------
# CGI HANDLER PART
#-----------------------------------------------------------------

package HelloWorld;

use strict;
use warnings;

# async-service.t repeatedly loads the HelloWorld class,
# causing redefined sub warning for process_it
no warnings 'redefine';

use lib 'lib';

use Log::Log4perl qw(:easy);
use base 'SADI::Simple::AsyncService';

Log::Log4perl->easy_init($WARN);

my $config = {

    ServiceName => 'HelloWorld',
    Authority => 'sadiframework.org', 
    InputClass => 'http://sadiframework.org/examples/hello.owl#NamedIndividual',
    OutputClass => 'http://sadiframework.org/examples/hello.owl#GreetedIndividual',   
    Description => 'A \'Hello, World!\' service',
    Provider => 'myaddress@organization.org',

};

my $service = HelloWorld->new(%$config);
$service->handle_cgi_request;

#-----------------------------------------------------------------
# SERVICE IMPLEMENTATION PART
#-----------------------------------------------------------------

use RDF::Trine::Node::Resource;
use RDF::Trine::Node::Literal;
use RDF::Trine::Statement;

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
            WARN(sprintf('skipping input %s, doesn\'t have a name property with a literal value', $input->uri));
            next;
        }

        my $greeting = sprintf("Hello, '%s'!", $name->value);
        my $greeting_literal = RDF::Trine::Node::Literal->new($greeting);
        
        my $statement = RDF::Trine::Statement->new($input, $greeting_property, $greeting_literal);
        $output_model->add_statement($statement);

    }

}

__END__
