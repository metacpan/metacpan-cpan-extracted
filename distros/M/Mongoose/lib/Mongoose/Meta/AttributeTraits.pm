package Mongoose::Meta::AttributeTraits;
$Mongoose::Meta::AttributeTraits::VERSION = '2.01';
package Mongoose::Meta::Attribute::Trait::Binary;
$Mongoose::Meta::Attribute::Trait::Binary::VERSION = '2.01';
use strict;
use Moose::Role;

has 'column' => (
    isa             => 'Str',
    is              => 'rw',
);

has 'lazy_select' => (
    isa             => 'Bool',
    is              => 'rw',
    default         => 0,
);

# -----------------------------------------------------------------

{
    package Moose::Meta::Attribute::Custom::Trait::Binary;
$Moose::Meta::Attribute::Custom::Trait::Binary::VERSION = '2.01';
sub register_implementation {'Mongoose::Meta::Attribute::Trait::Binary'}
}

# -----------------------------------------------------------------

package Mongoose::Meta::Attribute::Trait::DoNotMongoSerialize;
$Mongoose::Meta::Attribute::Trait::DoNotMongoSerialize::VERSION = '2.01';
use strict;
use Moose::Role;

has 'column' => (
    isa             => 'Str',
    is              => 'rw',
);

has 'lazy_select' => (
    isa             => 'Bool',
    is              => 'rw',
    default         => 0,
);

# -----------------------------------------------------------------

{
    package Moose::Meta::Attribute::Custom::Trait::DoNotMongoSerialize;
$Moose::Meta::Attribute::Custom::Trait::DoNotMongoSerialize::VERSION = '2.01';
sub register_implementation {'Mongoose::Meta::Attribute::Trait::DoNotMongoSerialize'}
}

# -----------------------------------------------------------------

{
    package Mongoose::Meta::Attribute::Trait::Raw;
$Mongoose::Meta::Attribute::Trait::Raw::VERSION = '2.01';
use strict;
    use Moose::Role;
}
{
    package Moose::Meta::Attribute::Custom::Trait::Raw;
$Moose::Meta::Attribute::Custom::Trait::Raw::VERSION = '2.01';
sub register_implementation {'Mongoose::Meta::Attribute::Trait::Raw'}
}

=head1 NAME

Mongoose::Meta::AttributeTraits - Mongoose related attribute traits

=head1 DESCRIPTION

All Moose attribute traits used by Mongoose are defined here.

=head2 DoNotMongoSerialize

Makes Mongoose skip collapsing or expanding the attribute.

=head2 Raw

Skips unblessing of an attribute when saving an object.

=cut

1;
