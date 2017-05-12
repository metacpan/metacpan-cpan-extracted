package POE::Filter::XML::RPC::Response;

use warnings;
use strict;

use base('POE::Filter::XML::Node');

our $VERSION = '0.04';

sub new()
{
	my ($class, $arg) = @_;

	my $node = $class->SUPER::new('methodResponse');
	
	bless($node, $class);

	if($arg->isa('POE::Filter::XML::RPC::Fault'))
	{
		$node->fault($arg);
	
	} elsif($arg->isa('POE::Filter::XML::RPC::Value')) {

		$node->return_value($arg);
	}

	return $node;
		
}	

sub fault()
{
	my ($self, $arg) = @_;

    my $fault = ($self->findnodes('child::fault'))[0];

	if(defined($arg))
	{	
		if(!defined($fault))
		{
            if($self->exists('child::params'))
            {
                $self->removeChild($self->firstChild());
            }
			$self->appendChild($arg);
		
		} else {
	
			$self->removeChild($fault);
			$self->appendChild($arg);
		}
	
		return $arg;

	} else {
        
        return undef if not defined $fault;
		return bless($fault, 'POE::Filter::XML::RPC::Fault');
	}

}

sub return_value()
{
	my ($self, $arg) = @_;
	
	if(defined($arg))
	{
		if(!$self->exists('child::params'))
		{
            if($self->exists('child::fault'))
            {
                $self->removeChild($self->firstChild());
            }
			$self->appendChild('params')->appendChild('param')->appendChild($arg);
		
		} else {
	
			($self->findnodes('child::params/child::param'))[0]->appendChild($arg);
		}

		return $arg;
	
	} else {
        
		if(my $value = ($self->findnodes('child::params/child::param/child::value'))[0])
        {
            return bless($value, 'POE::Filter::XML::RPC::Value');
        }

        return undef;
	}
}

=pod

=head1 NAME

POE::Filter::XML::RPC::Response - An abstracted XMLRPC response

=head1 SYNOPSIS

    use 5.010;
    use POE::Filter::XML::RPC::Response;
    use POE::Filter::XML::RPC::Value;

    my $response = POE::Filter::XML::RPC::Response->new
    (
        POE::Filter::XML::RPC::Value->new('Okay!');
    )

    say $response->return_value()->value() # Okay!

=head1 DESCRIPTION

POE::Filter::XML::RPC::Reponse provides a simple class for generating XMLRPC
responses. 

=head1 PUBLIC METHODS

=over 4

=item new()

new() takes a single argument that can either be a POE::Filter::XML::RPC::Value
object or it can be a POE::Filter::XML::RPC::Fault object.

=item fault()

If the response contains a Fault object, it will be returned. May also take a 
single argument of another Fault object. In that case, any previous Fault 
object will be replaced with the provided. Also, if the response contained a 
valid return Value, it will be replaced by the Fault.

=item return_value()

If the response contains a return Value, it will be returned. May also take a 
single argument of another Value object. In that case, any previous Value 
object will be replaced with the provided. Also, if the response contained a 
Fault, it will be replaced by the Value.

=back

=head1 NOTES

Response is actually a subclass of POE::Filter::XML::Node and so all of its
methods, including XML::LibXML::Element's, are available for use. This could 
ultimately be useful to avoid marshalling all of the data out of the Node and
instead apply an XPATH expression to target specifically what is desired deep
within a nested structure.

=head1 AUTHOR

Copyright 2009 Nicholas Perez.
Licensed and distributed under the GPL.

=cut

1;
