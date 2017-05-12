package POE::Filter::XML::RPC::Value;

use 5.010;
use warnings;
use strict;

use base('POE::Filter::XML::Node', 'Exporter');
use Scalar::Util('looks_like_number', 'reftype');
use Regexp::Common('time');
use Hash::Util('fieldhash');

our $VERSION = '0.04';

use constant 
{
    'ARRAY'     => 'array',
    'BASE64'    => 'base64',
    'BOOL'      => 'bool',
    'DATETIME'  => 'dateTime.iso8601',
    'DOUBLE'    => 'double',    
    'INT'       => 'int',
    'STRING'    => 'string',
    'STRUCT'    => 'struct',
    'DATA'      => 'data',
    'NAME'      => 'name',
    'VALUE'     => 'value',
    'MEMBER'    => 'member',
};

our @EXPORT= qw/ ARRAY BASE64 BOOL DATETIME DOUBLE INT STRING STRUCT /;

sub new
{
	my $class = shift(@_);
    my $arg = shift(@_);
    my $force_type = shift(@_);
    
    my $val = process($arg, $force_type);
    bless($val, $class);

    $val->_type($force_type // determine_type($arg));
    return $val;
}

sub process
{
    my ($arg, $force) = (shift(@_), shift(@_));
    
    my $val = __PACKAGE__->SUPER::new(+VALUE);
    
    given($force // determine_type($arg))
    {
        when(+ARRAY)
        {
            my $data = $val->appendChild(+ARRAY)->appendChild(+DATA);
            
            foreach(@$arg)
            {
                $data->appendChild(process($_));
            }
        }
        when(+STRUCT)
        {
            my $struct = $val->appendChild(+STRUCT);

            while(my ($key, $val) = each %$arg)
            {
                my $member = $struct->appendChild(+MEMBER);
                $member->appendChild(+NAME)->appendText($key);
                $member->appendChild(process($val));
            }
        }
        default
        {
            $val->appendChild($_)->appendText($arg);
        }
    }

    return $val;
}

sub value()
{
    my ($self, $arg, $force_type) = (shift(@_), shift(@_), shift(@_));
    
    if(defined($arg))
    {
        $self->removeChild($self->firstChild());
        my $type = $force_type // determine_type($arg);
        $self->appendChild($type)->appendText($arg);
        $self->_type($type);
    }
    else
    {
        my $content = $self->findvalue('child::text()');
        if(defined($content) && length($content))
        {
            return $content;
        }
        else
        {
            return node_to_value($self);
        }
    }
}

sub node_to_value
{
    my $node = shift(@_);
    
    my $content = $node->findvalue('child::text()');
    return $content if defined($content) && length($content);

    my $val = $node->firstChild();
    given($val->nodeName())
    {
        when(+STRUCT)
        {
            my $struct = {};
            foreach($val->findnodes('child::member'))
            {
                $struct->{$_->findvalue('child::name/child::text()')} =
                    node_to_value(($_->findnodes('child::value'))[0]);
            }

            return $struct;
        }
        when(+ARRAY)
        {
            my $array = [];

            foreach($val->findnodes('child::data/child::value'))
            {
                push(@$array, node_to_value($_));
            }

            return $array;
        }
        default
        {
            return $val->findvalue('child::text()');
        }
    }
}

sub type()
{
    my $self = shift(@_);
    if(!defined($self->_type()))
    {
        my $content = $self->findvalue('child::text()');
        
        if(defined($content) && length($content))
        {
            # string
            $self->_type(+STRING);
            return +STRING;
        }
        
        my $determined = determine_type($self->value());
        $self->_type($determined);
        return $determined;
    }
    else
    {
        return $self->_type();
    }
}

sub _type()
{
    my ($self, $arg) = (shift(@_), shift(@_));
    fieldhash state %type;

    if(defined($arg))
    {
        $type{$self} = $arg;
    }
    else
    {
        return $type{$self};
    }
}

sub determine_type($)
{
    my $arg = shift(@_);

    given($arg)
    {
        when(m@^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$@)
        {
            return +BASE64;
        }
        when(/^(?:1|0){1}$|^true$|^false$/i)
        {
            return +BOOL;
        }
    }

    if(looks_like_number($arg))
    {
        if($arg =~ /\.{1}/)
        {
            return +DOUBLE;
        }
        else
        {
            return +INT;
        }
    }

    given(reftype($arg) // '')
    {
        when('ARRAY')
        {
            return +ARRAY;
        }
        when('HASH')
        {
            return +STRUCT;
        }
        default
        {
            state $iso = "$RE{'time'}{'iso'}";
            if($arg =~ /$iso/)
            {
                return +DATETIME;
            }
            return +STRING;
        }
    }
}

=pod

=head1 NAME

POE::Filter::XML::RPC::Value - Represents XMLRPC value types

=head1 SYNOPSIS

    use 5.010;
    use POE::Filter::XML::RPC::Value;

    my $val1 = POE::Filter::XML::RPC::Value->new([qw/one two three/]);
    my $val2 = POE::Filter::XML::RPC::Value->new('1A2B3C==');
    my $val3 = POE::Filter::XML::RPC::Value->new(1);
    my $val4 = POE::Filter::XML::RPC::Value->new('19980717T14:08:55');
    my $val5 = POE::Filter::XML::RPC::Value->new(1.00);
    my $val6 = POE::Filter::XML::RPC::Value->new(42);
    my $val7 = POE::Filter::XML::RPC::Value->new('some text');
    my $val8 = POE::Filter::XML::RPC::Value->new({'key' => 'val'});
    my $val9 = POE::Filter::XML::RPC::Value->new(1234, +STRING);

    say $val1->type(); # array
    say $val2->type(); # base64
    say $val3->type(); # bool
    say $val4->type(); # dateTime.iso8601
    say $val5->type(); # double
    say $val6->type(); # int
    say $val7->type(); # string
    say $val8->type(); # struct
    say $val9->type(); # string

=head1 DESCRIPTION

POE::Filter::XML::RPC::Value does most of the automagical marshalling that is
expected when dealing with XMLRPC value types. Structs are converted to hashes.
Arrays are converted to arrays, etc. And it works both ways. So if passed a 
complex, nested Perl data structure, it will Do The Right Thing.

=head1 PUBLIC METHODS

=over 4

=item new()

new() accepts a scalar, and an optional type argument to use to construct the 
the value. See EXPORTED CONSTANTS for acceptable types.

The scalar provided can contain a string, hash or array reference, or may be a
numerical value. Scalar::Util is put to good use to determine what kind of
value was passed, and some good old fashion regular expression magic thrown at
it to see if it is a ISO 8601 datetime, or perhaps BASE64 encoded data. 

If the type determination turns out wrong for whatever reason, a type argument
can also be supplied to force a particular type. 

=item type()

type() returns what type of value is represented. For values received from some
where else, it will spelunk into the data and determine the type using the same
heuristics used for construction. Will be one of the EXPORTED CONSTANTS

=item value()

value() returns the data properly marshalled into whatever Perl type is valid. 
Arrays and Structs will be marshalled into their Perl equivalent and returned 
as a reference to that type, while all other types will be return as a scalar.

value() can also take a new value to replace the old one. It can even be of a 
different type. And again if the heuristics for your data don't do the right 
thing, you can also provide a second argument of what type the data should be.

=back

=head1 PRIVATE METHODS

=over 4

=item _type()

_type() stores the cached type of the current Value with examining the content
to determine if that still holds true. Use with care.

=back

=head1 PROTECTED FUNCTIONS

These are not exported or available for export at all.

=over 4

=item determine_type

This function contains the logic behind the type guessing heuristic. Simply 
supply whatever scalar you want to it and it will return one of the EXPORTED
CONSTANTS. 

=item node_to_value

This function takes a POE::Filter::XML::Node of the following structure:

<value>
    <!-- some other stuff in here, could be <array/>,<struct/>, etc -->
</value>

then marshals and returns that data to you.

=back

=head1 EXPORTED CONSTANTS

Here are the exported constants and their values. Note that the values for 
these constants are the same as valid tag names for value types in XMLRPC.

    +ARRAY     => 'array',
    +BASE64    => 'base64',
    +BOOL      => 'bool',
    +DATETIME  => 'dateTime.iso8601',
    +DOUBLE    => 'double',    
    +INT       => 'int',
    +STRING    => 'string',
    +STRUCT    => 'struct',

=head1 NOTES

Value is actually a subclass of POE::Filter::XML::Node and so all of its
methods, including XML::LibXML::Element's, are available for use. This could 
ultimately be useful to avoid marshalling all of the data out of the Node and
instead apply an XPATH expression to target specifically what is desired deep
within a nested structure.

=head1 AUTHOR

Copyright 2009 Nicholas Perez.
Licensed and distributed under the GPL.

=cut

1;
