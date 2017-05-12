package MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects;

use 5.010;
use utf8;

use Moose;
use Moose::Util::TypeConstraints;

use version; our $VERSION = qv('v1.18.0');


with 'MooseX::Getopt::Defanged';


subtype 'MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects::Types::StringWrapper'
    => as class_type('StringWrapper');

subtype 'MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects::Types::ArrayRefOfStringWrappers'
    => as 'ArrayRef[MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects::Types::StringWrapper]';


coerce 'MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects::Types::StringWrapper'
    => from 'Str'
    => via { StringWrapper->new($_) };

coerce 'MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects::Types::ArrayRefOfStringWrappers'
    => from 'Str'
        => via { [ StringWrapper->new($_ )] }
    => from 'ArrayRef[Str]'
        => via { [ map { StringWrapper->new($_) } @{$_} ] };


has option_with_object_and_stringify_string => (
    traits              => [ qw< MooseX::Getopt::Defanged::Option > ],
    is                  => 'rw',
    isa                 => 'MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects::Types::StringWrapper',
    default             => 'http://www.example.com',
    coerce              => 1,
    getopt_type         => 'Str',
    getopt_stringifier  => 'as_string',
);

has option_with_object_and_stringify_coderef => (
    traits              => [ qw< MooseX::Getopt::Defanged::Option > ],
    is                  => 'rw',
    isa                 => 'MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects::Types::StringWrapper',
    default             => 'http://www.example.com',
    coerce              => 1,
    getopt_type         => 'Str',
    getopt_stringifier  => sub { shift->as_string() },
);

has option_with_arrayref_of_objects => (
    traits              => [ qw< MooseX::Getopt::Defanged::Option > ],
    is                  => 'rw',
    isa                 => 'MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects::Types::ArrayRefOfStringWrappers',
    default             => sub { [ 'http://www.example.com', 'http://www.example.net' ] },
    coerce              => 1,
    getopt_type         => 'Str',
    getopt_stringifier  => 'as_string',
);

no Moose;

__PACKAGE__->meta()->make_immutable();


1;

__END__

=encoding utf8

=head1 NAME

MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithObjects - Consumer of L<MooseX::Getopt::Defanged> role that has objects as attributes.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :
