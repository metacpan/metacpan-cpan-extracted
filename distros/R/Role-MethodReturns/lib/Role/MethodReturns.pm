package Role::MethodReturns;

our $VERSION = '0.04';

use strict;
use warnings;

use Function::Parameters;


our @ISA = qw/Exporter/;

our @EXPORT = qw(
    returns
    returns_maybe
    returns_self
    returns_maybe_self
    returns_object_does_interface
    returns_maybe_object_does_interface
);

use Import::Into;


use Type::Params qw/Invocant/;
use Types::Standard qw/ClassName Object Maybe/;
use Types::Interface qw/ObjectDoesInterface/;



sub returns {
    my $type_constraint = shift;
    
    $type_constraint->assert_return(@_)
}



sub returns_maybe {
    my $type_constraint = shift;
    
    ( Maybe[$type_constraint] )->assert_return(@_)
}



sub returns_self {
    my $self = shift;
    
    return $self if $self eq $_[0];
    
    die "Expected to return '\$self' [$self], got [$_[0]]\n";
}



sub returns_maybe_self {
    my $self = shift;
    
    return unless defined $_[0];
    
    return $self if $self eq $_[0];
    
    die "Expected to return '\$self' [$self], got [$_[0]]\n";
}



sub returns_object_does_interface {
    my $interface = shift;
    
    ( ObjectDoesInterface[$interface] )->assert_return(@_)
}



sub returns_maybe_object_does_interface {
    my $interface = shift;
    
    return unless defined $_[0];
    
    ( ObjectDoesInterface[$interface] )->assert_return(@_)
}



sub import {
    
    # TODO: We should only import what we really want to and select
    
    # see Function::Parameters on 'Wrapping Function::Parameters':
    #
    # Due to its nature as a lexical pragma, importing from Function::Parameters
    # always affects the scope that is currently being compiled. If you want to
    # write a wrapper module that enables Function::Parameters automatically,
    # just call Function::Parameters->import from your own import method (and
    # Function::Parameters->unimport from your unimport, as required).
    #
    Function::Parameters->import(
        {
            parameters => {
                shift => ['$orig', '$self'],
            }
        },
        {
            instance_method => {
                shift => ['$original', ['$instance', Object]    ],
            }
        },
        {
            class_method => {
                shift => ['$original', ['$class',    ClassName] ],
            }
        },
        {
            method_parameters => {
                shift => ['$original', ['$invocant', Invocant]  ],
            }
        },
    );
    
    Role::Tiny->import::into(scalar caller);
    #
    # provides `requires`, `with`
    # and the methodmodifiers `around`, `before`, and `after`
    
    __PACKAGE__->export_to_level( 1, @_ );
    #
    # whatever is in the list and can be exported, listed in `@EXPORT_OK`
    
}



1;

