package POE::Filter::XML::RPC::Fault;

use warnings;
use strict;

use POE::Filter::XML::RPC::Value;

use base('POE::Filter::XML::Node');

our $VERSION = '0.04';

sub new()
{
	my ($class, $code, $string) = @_;

	my $self = $class->SUPER::new('fault');

    my $hash = {'faultCode' => $code, 'faultString' => $string};
	my $struct = POE::Filter::XML::RPC::Value->new($hash);

	$self->appendChild($struct);

	return bless($self, $class);
}

sub code()
{
    return shift(@_)->find('child::value/child::struct/child::member[child::name/child::text() = "faultCode"]/child::value/child::*[self::int or self::i4]/child::text()');
}

sub string()
{
    return shift(@_)->find('child::value/child::struct/child::member[child::name/child::text() = "faultString"]/child::value/child::string/child::text()');
}

=pod

=head1 NAME

POE::Filter::XML::RPC::Fault - A XMLRPC Fault abstraction

=head1 SYNOPSIS

    use 5.010;
    use POE::Filter::XML::RPC::Fault;

    my $fault = POE::Filter::XML::RPC::Fault->new(503, 'Fail text here');

    say $fault->code(); # 503
    say $fault->string(); # Fail text here

=head1 DESCRIPTION

POE::Filter::XML::RPC::Fault provides a convient object for representing faults
within XMLRPC without having to construct them manually.

=head1 PUBLIC METHODS

=over 4

=item new() 

new() accepts two arguments, one, the integer code value for the fault, and
two, a string explaining the fault. Both arguments are required.

=item code()

code() returns the integer value for the particular Fault. Takes no arguments.

=item string()

string() returns the string value for the particular Fault. Takes no arguments.

=back

=head1 NOTES

Fault is actually a subclass of POE::Filter::XML::Node and so all of its
methods, including XML::LibXML::Element's, are available for use. This could 
ultimately be useful to avoid marshalling all of the data out of the Node and
instead apply an XPATH expression to target specifically what is desired deep
within a nested structure.

=head1 AUTHOR

Copyright 2009 Nicholas Perez.
Licensed and distributed under the GPL.

=cut

1;
