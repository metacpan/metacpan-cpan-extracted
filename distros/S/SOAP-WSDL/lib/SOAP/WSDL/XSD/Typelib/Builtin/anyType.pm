package SOAP::WSDL::XSD::Typelib::Builtin::anyType;
use strict;
use warnings;
use Class::Std::Fast::Storable constructor => 'none';

our $VERSION = 3.003;

sub get_xmlns { 'http://www.w3.org/2001/XMLSchema' };

# start_tag creates a XML start tag either for a XML element or a attribute.
# The method is highly optimized for performance:
# - operates on @_
# - uses no private variables
# - uses no blocks

sub start_tag {
    # return empty string if no second argument ($opt) or no name
    return q{} if (! $#_);
    return q{} if (! exists $_[1]->{ name });
    # return attribute start if it's an attribute
    return qq{ $_[1]->{name}="} if $_[1]->{ attr };
    # return with xsi:nil="true" if it is nil
    return join
        q{} ,
        "<$_[1]->{ name }" ,
        (defined $_[1]->{ xmlns }) ? qq{ xmlns="$_[1]->{ xmlns }"} : (),
        $_[0]->serialize_attr($_[1]) ,
        q{ xsi:nil="true"/>}
            if ($_[1]->{ nil });
    # return "empty" start tag if it's empty
    return join
        q{},
        "<$_[1]->{ name }",
        (defined $_[1]->{ xmlns }) ? qq{ xmlns="$_[1]->{ xmlns }"} : (),
        $_[0]->serialize_attr($_[1]) ,
        '/>'
        if ($_[1]->{ empty });
    # return XML element start tag
    return join
        q{},
        "<$_[1]->{ name }",
        (defined $_[1]->{ xmlns }) ? qq{ xmlns="$_[1]->{ xmlns }"} : (),
        , $_[0]->serialize_attr($_[1])
        , '>';
}

# start_tag creates a XML end tag either for a XML element or a attribute.
# The method is highly optimized for performance:
# - operates on @_
# - uses no private variables
# - uses no blocks
sub end_tag {
    # return empty string if no second argument ($opt) or no name
    return q{} if (! $#_);
    return q{} if (! exists $_[1]->{ name });
    return q{"} if $_[1]->{ attr };
    return "</$_[1]->{name}>";
};

sub serialize_attr {};

# sub serialize { q{} };

sub serialize_qualified :STRINGIFY {
    return $_[0]->serialize( { qualified => 1 } );
}

sub as_list :ARRAYIFY {
    return [ $_[0] ];
}

Class::Std::initialize();           # make :STRINGIFY overloading work

1;

