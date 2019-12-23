package App::Interface;

use strict;
use warnings;

use Function::Parameters;


our @ISA = qw(Exporter);
our @EXPORT = qw/&returns/;

use Import::Into;


use Types::Standard qw/ClassName Object/;
use Type::Params qw/Invocant/;



sub returns {
    my $type_constraint = shift;
    
    $type_constraint->assert_return(@_)
}

sub returns_self {
    my $self = shift;
    
    die "Opps, I am supposed to return 'my \$self'\n"
        unless "$_[0]" eq "$self";
    
    return @_;
}

sub import {
    
    Function::Parameters->import(
        {
            parameters => {
                shift => ['$orig', '$self'],
            }
        },
        {
            method_parameters => {
                shift => ['$original', ['$invocant', Invocant]  ],
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
    );
    
    __PACKAGE__->export_to_level( 1, @_ );
    
    Role::Tiny->import::into(scalar caller);
    
}

1;

