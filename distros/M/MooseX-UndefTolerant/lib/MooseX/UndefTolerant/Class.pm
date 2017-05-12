package MooseX::UndefTolerant::Class;

our $VERSION = '0.21';

# applied to metaclass, for Moose >= 1.9900

use strict;
use warnings;

use Moose::Role;

# TODO: this code should be in the attribute trait, in the inlined version of
# initialize_instance_slot, but this does not yet exist!

around _inline_init_attr_from_constructor => sub {
    my $orig = shift;
    my $self = shift;
    my ($attr, $idx) = @_;

    my @source = $self->$orig(@_);

    my $init_arg = $attr->init_arg;
    my $type_constraint = $attr->type_constraint;
    my $tc_says_clean = ($type_constraint && !$type_constraint->check(undef) ? 1 : 0);

    # FIXME: not properly sanitizing field names - e.g. consider a field name "Z'ha'dum"
    return ($tc_says_clean ? (
        "if ( exists \$params->{'$init_arg'} && defined \$params->{'$init_arg'} ) {",
        ) : (),
        @source,
        $tc_says_clean ? (
        '} else {',
            "delete \$params->{'$init_arg'};",
        '}',
        ) : (),
    );
};

no Moose::Role;
1;
