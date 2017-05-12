package POE::Filter::XML::RPC::Request;

use warnings;
use strict;

use POE::Filter::XML::Node;

use base('POE::Filter::XML::Node');

our $VERSION = '0.04';

sub new()
{
	my ($class, $methodname, $params) = @_;
	
    my $self = POE::Filter::XML::Node->new('methodCall');
	$self->appendChild('methodName');
	$self->appendChild('params');

	bless($self, $class);

	$self->method_name($methodname);

	if(defined($params) and ref($params) eq 'ARRAY')
	{
		foreach my $param (@$params)
		{
			$self->add_parameter($param);
		}
	}

	return $self;
}

sub method_name()
{
	my ($self, $arg) = @_;

	if(defined($arg))
	{
		($self->findnodes('child::methodName'))[0]->appendText($arg);
		return $arg;
	
	} else {

		return $self->findvalue('child::methodName/child::text()');
	}
}

sub parameters()
{
	return [ map { bless($_, 'POE::Filter::XML::RPC::Value') } shift(@_)->findnodes('child::params/child::param/child::value') ];
}

sub add_parameter()
{
	my ($self, $val) = @_;

	$self->add($self->wrap($val));
    
    return bless($val, 'POE::Filter::XML::RPC::Value');
}

sub insert_parameter()
{
	my ($self, $val, $index) = @_;
	
	$self->insert($self->wrap($val), $index);

    return bless($val, 'POE::Filter::XML::RPC::Value');
}

sub delete_parameter()
{
	my ($self, $index) = @_;

	my $val = ($self->delete($index)->findnodes('child::value'))[0];

    return bless($val, 'POE::Filter::XML::RPC::Value');
}

sub get_parameter()
{
	my ($self, $index) = @_;
    
	my $val = ($self->get($index)->findnodes('child::value'))[0];
    
    return bless($val, 'POE::Filter::XML::RPC::Value');
}

sub add()
{
    my ($self, $val) = @_;
    return ($self->findnodes('child::params'))[0]->appendChild($val);
}

sub delete()
{
    my ($self, $index) = @_;
    return ($self->findnodes('child::params'))[0]->removeChild($self->get($index));
}

sub insert()
{
    my ($self, $val, $index) = @_;
    return ($self->findnodes('child::params'))[0]->insertBefore($val, $self->get($index));
}

sub get()
{
    my ($self, $index) = @_;
    return ($self->findnodes("child::params/child::param[position()=$index]"))[0];
}

sub wrap()
{
	my ($self, $val) = @_;

	my $param = POE::Filter::XML::Node->new('param');
	
	$param->appendChild($val);

	return $param;
}

=pod

=head1 NAME

POE::Filter::XML::RPC::Request - An abstracted XMLRPC request

=head1 SYNOPSIS

    use 5.010;
    use POE::Filter::XML::RPC::Request;
    use POE::Filter::XML::RPC::Value;

    my $request = POE::Filter::XML::RPC::Request->new
    (
        'SomeRemoteMethod',
        [
            POE::Filter::XML::RPC::Value->new('Some Argument')
        ]
    );

    say $request->method_name(); # SomeRemoteMethod
    say $request->get_parameter(1)->value(); # Some Argument

=head1 DESCRIPTION

POE::Filter::XML::RPC::Request provides and abstracted XMLRPC request object
to use when constructing requests to a remote server.

=head1 PUBLIC METHODS

=over 4

=item new()

new() accepts two arguments, one, the method name to be used, and two, an array
reference of POE::Filter::XML::RPC::Value objects that are the positional
arguments to the method in question. 

=item method_name()

method_name() returns the current method name of the request. Can also take an
argument that will change the method name to the provided argument.

=item parameters()

parameters() returns an array reference of all of the Values currently stored
in the request in the order they were provided. This is a zero based array.

=item get_parameter()

get_parameter() takes a one based index into the positional parameters of the 
request. Returns the Value object at that position.

=item insert_parameter()

insert_parameter() takes two arguments, one, the Value object to be inserted and
two, the one based index to which the Value should be associated.

=item delete_parameter()

delete_parameter() takes a one based index into the positional parameters of the
request. Returns the deleted Value.

=item add_parameter()

add_parameter() takes a Value object as its sole argument and appends it to the
end of the parameters of the request.

=back

=head1 Notes

Request is actually a subclass of POE::Filter::XML::Node and so all of its
methods, including XML::LibXML::Element's, are available for use. This could 
ultimately be useful to avoid marshalling all of the data out of the Node and
instead apply an XPATH expression to target specifically what is desired deep
within a nested structure.

The reason the parameter methods are one based indexed is because of how XPATH
works and what the spec calls out for when it comes to the position() 
predicate.

=head1 AUTHOR

Copyright 2009 Nicholas Perez.
Licensed and distributed under the GPL.

=cut

1;
