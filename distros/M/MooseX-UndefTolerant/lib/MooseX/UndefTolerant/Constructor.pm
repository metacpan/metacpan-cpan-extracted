package MooseX::UndefTolerant::Constructor;

our $VERSION = '0.21';

# applied to constructor method metaclass, for Moose < 1.9900

use Moose::Role;

use strict;
use warnings;

around _generate_slot_initializer => sub {
    my $orig = shift;
    my $self = shift;

    # note the key in the params may not match the attr name.
    my $key_name = $self->_attributes->[$_[0]]->init_arg;

    # insert a line of code at the start of the initializer,
    # clearing the param if it's undefined.

    if (defined $key_name)
    {
        # leave the value unscathed if the attribute's type constraint can
        # handle undef (or doesn't have one, which implicitly means it can)
        my $type_constraint = $self->_attributes->[$_[0]]->type_constraint;
        if ($type_constraint and not $type_constraint->check(undef))
        {
            my $tolerant_code =
                qq# delete \$params->{'$key_name'} unless # .
                qq# exists \$params->{'$key_name'} && defined \$params->{'$key_name'};\n#;

            return $tolerant_code . $self->$orig(@_);
        }
    }

    return $self->$orig(@_);
};

no Moose::Role;
1;
