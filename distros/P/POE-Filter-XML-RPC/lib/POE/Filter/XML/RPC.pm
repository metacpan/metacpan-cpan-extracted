package POE::Filter::XML::RPC;

use POE::Filter::XML::RPC::Request;
use POE::Filter::XML::RPC::Response;
use POE::Filter::XML::RPC::Fault;

use POE::Filter::XML::Node;

use base('POE::Filter');

use constant
{
	BUFFER => 0,
};

our $VERSION = '0.04';


sub new()
{
	my $class = shift;
	my $self = [];
	
	$self->[+BUFFER] = [];

	return bless($self, $class);
}

sub get_one_start()
{
	my ($self, $raw) = @_;
	if(@{$self->[+BUFFER]})
	{
		push(@{$self->[+BUFFER]}, @$raw);
	
	} elsif(ref($raw) eq 'ARRAY') {

		$self->[+BUFFER] = $raw;
	}
    else
    {
        $self->[+BUFFER] = [$raw];
    }
}

sub get_one()
{
	my $self = shift(@_);
	my $node = shift(@{$self->[+BUFFER]});
	

	if(defined($node))
	{
		if($node->nodeName() eq 'methodCall')
		{
			if($node->exists('child::methodName'))
			{
				if(!$node->exists('child::methodName/child::text()'))
				{
					return 
					[
                        POE::Filter::XML::RPC::Response->new
                        (
                            POE::Filter::XML::RPC::Fault->new
                            (
                                102,
                                'Malformed XML-RPC: No methodName data defined'
                            )
                        )
					];
				}
			
			} else {

				return
				[
                    POE::Filter::XML::RPC::Response->new
                    (
                        POE::Filter::XML::RPC::Fault->new
                        (
                            103,
                            'Malformed XML-RPC: No methodName child tag present'
                        )
                    )
				];
			}
			
			# params are optional, but let's be consistent for the
			# Request code's sake.

			if(!$node->exists('child::params'))
			{
				$node->appendChild('params');
			
			} else {
                
                my $params =()= $node->findnodes('child::params/child::param');
                my $vals =()= $node->findnodes('child::params/child::param/child::value');

                if($vals < $params)
                {
                    return
                    [
                        POE::Filter::XML::RPC::Response->new
                        (
                            POE::Filter::XML::RPC::Fault->new
                            (
                                110,
                                'Malformed XML-RPC: No value tag within param'
                            )
                        )
                    ];
                }
			}
					
			return [bless($node, 'POE::Filter::XML::RPC::Request')];
	
		} elsif ($node->nodeName() eq 'methodResponse') {
			
			if(!$node->exists('child::params') and !$node->exists('child::fault'))
            {
				return
				[
                    POE::Filter::XML::RPC::Response->new
                    (
                        POE::Filter::XML::RPC::Fault->new
                        (
                            104,
                            'Malformed XML-RPC: Response does not contain ' .	
                            'parameters or a fault object'
                        )
                    )
				]
			
			} elsif($node->exists('child::params')) {
					
				my $params =()= $node->findnodes('child::params/child::param');

				if(!$params)
				{
					return
					[
                        POE::Filter::XML::RPC::Response->new
                        (
                            POE::Filter::XML::RPC::Fault->new
                            (
                                105,
                                'Malformed XML-RPC: Return parameters does ' .
                                'not contain any param children'
                            )
                        )
					];
				
				} 
                
                my $node_count =()= $node->findnodes('child::params/child::*');
                
                if($node_count > $params)
                {
                    return
                    [
                        POE::Filter::XML::RPC::Response->new
                        (
                            POE::Filter::XML::RPC::Fault->new
                            (
                                108,
                                'Malformed XML-RPC: Params object ' .
                                'contains children other than param'
                            )
                        )
                    ];
                }

                my $value_count =()= $node->findnodes('child::params/child::param/child::value');
				
                if($value_count < $params)
                {
                    return
                    [
                        POE::Filter::XML::RPC::Response->new
                        (
                            POE::Filter::XML::RPC::Fault->new
                            (
                                109,
                                'Malformed XML-RPC: Param child does '.
                                'not contain a value object'
                            )
                        )
                    ];
                }
		
			} elsif($node->exists('child::fault')) {

                if(!$node->exists('child::fault/child::value'))
                {
					return
					[
                        POE::Filter::XML::RPC::Response->new
                        (
                            POE::Filter::XML::RPC::Fault->new
                            (
                                106,
                                'Malformed XML-RPC: Fault value is not a ' .
                                'valid struct object'
                            )
                        )
					];
                }
                
				if(!$node->exists('child::fault/child::value/child::struct'))
				{
					return
					[
                        POE::Filter::XML::RPC::Response->new
                        (
                            POE::Filter::XML::RPC::Fault->new
                            (
                                106,
                                'Malformed XML-RPC: Fault value is not a ' .
                                'valid struct object'
                            )
                        )
					];
				
				} 
                
                my $code = $node->findvalue('child::fault/child::value/child::struct/child::member[child::name/child::text() = "faultCode"]/child::value/child::*/child::text()');
                my $string = $node->findvalue('child::fault/child::value/child::struct/child::member[child::name/child::text() = "faultString"]/child::value/child::*/child::text()');

                if(!defined($code) or !defined($string) or !length($code) or !length($string))
                {
                    return
                    [
                        POE::Filter::XML::RPC::Response->new
                        (
                            POE::Filter::XML::RPC::Fault->new
                            (
                                107,
                                'Malformed XML-RPC: Fault value does not ' . 
                                'contain either a fault code or fault string'
                            )
                        )
                    ];
                }
			}
				
			return [bless($node, 'POE::Filter::XML::RPC::Response')];
		
		} else {
			
			return 
			[
                POE::Filter::XML::RPC::Response->new
                (
                    POE::Filter::XML::RPC::Fault->new
                    ( 
                        101, 
                        'Malformed XML-RPC: Top level node is not valid'
                    )
                )
			];
		}
	
	} else {

		return [];
	}
}

sub put()
{
	my ($self, $nodes) = @_;
	
	my $ret = [];

	foreach my $node (@$nodes)
	{
		push(@$ret, bless($node, 'POE::Filter::XML::Node'));
	}
	
	return $ret;
}

=pod

=head1 NAME

POE::Filter::XML::RPC - A POE Filter for marshalling XML-RPC

=head1 SYNOPSIS

    use POE::Filter::XML::RPC;
    use POE::Filter::XML::RPC::Request;
    use POE::Filter::XML::RPC::Response;
    use POE::Filter::XML::RPC::Fault;
    use POE::Filter::XML::RPC::Value;

    my $filter = POE::Filter::XML::RPC->new();

    # Build/send a request
    my $request = POE::Filter::XML::RPC::Request->new
    (
        'server_method', 
        POE::Filter::XML::RPC::Value->new({'NamedArgument' => 42})
    );

    $filter->put($request);

    # Build/send a response

    my $reponse = POE::Filter::XML::RPC::Response->new
    (
        POE::Filter::XML::RPC::Value->new([qw/somevalue1 somevalue2/])
    );

    $filter->put($reponse);

=head1 DESCRIPTION

POE::Filter::XML::RPC builds upon the work of POE::Filter::XML to parse XML-RPC
datagrams and deliver useful objects for the end developer.

This filter is expected to be used in a chain of filters where it will receive
POE::Filter::XML::Nodes on input and output.

=head1 PUBLIC METHODS

There are no public methods outside of the implemented POE::Filter API

=head1 NOTES

Response, Request, Fault, and Value are based on POE::Filter::XML::Node. See 
their individual PODs for more information.

This filter only implements part of the XMLRPC spec[1], the HTTP portion is not
accounted for within this filter and in fact, only concerns itself with 
POE::Filter::XML::Nodes received or sent.

[1]: http://www.xmlrpc.com/spec

=head1 AUTHOR

Copyright 2009 Nicholas Perez.
Licensed and distributed under the GPL.

=cut

1;
