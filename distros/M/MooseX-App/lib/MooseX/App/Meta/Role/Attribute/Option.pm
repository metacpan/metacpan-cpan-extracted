# ============================================================================
package MooseX::App::Meta::Role::Attribute::Option;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

use List::Util qw(uniq);

has 'cmd_type' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::CmdTypes',
    predicate   => 'has_cmd_type',
);

has 'cmd_tags' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::List',
    coerce      => 1,
    predicate   => 'has_cmd_tags',
);

has 'cmd_flag' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::Identifier',
    predicate   => 'has_cmd_flag',
);

has 'cmd_aliases' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::IdentifierList',
    predicate   => 'has_cmd_aliases',
    coerce      => 1,
);

has 'cmd_split' => (
    is          => 'rw',
    isa         => Moose::Util::TypeConstraints::union([qw(Str RegexpRef)]),
    predicate   => 'has_cmd_split',
);

has 'cmd_count' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => sub { 0 },
);

has 'cmd_negate' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::IdentifierList',
    coerce      => 1,
    predicate   => 'has_cmd_negate',
);

has 'cmd_env' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::Env',
    predicate   => 'has_cmd_env',
);

has 'cmd_position' => (
    is          => 'rw',
    isa         => 'Int',
    default     => sub { 0 },
);

my $GLOBAL_COUNTER = 1;

around 'new' => sub {
    my $orig = shift;
    my $class = shift;

    my $self = $class->$orig(@_);

    if ($self->has_cmd_type) {
        if ($self->cmd_position == 0) {
            $GLOBAL_COUNTER++;
            $self->cmd_position($GLOBAL_COUNTER);
        }
    }

    return $self;
};

sub cmd_check {
    my ($self) = @_;

    my $name = $self->name;
    my $from_constraint;
    my $type_constraint = $self->type_constraint;
    $from_constraint = $type_constraint->parameterized_from
        if $type_constraint && $type_constraint->isa('Moose::Meta::TypeConstraint::Parameterized');

    # Check for useless flags
    if ($self->cmd_type eq 'parameter') {
        if ($self->cmd_count) {
            Moose->throw_error("Parameter $name has 'cmd_count'. This attribute only works with options");
        }
        if ($self->has_cmd_negate) {
            Moose->throw_error("Parameter $name has 'cmd_negate'. This attribute only works with options");
        }
        if ($self->has_cmd_negate) {
            Moose->throw_error("Parameter $name has 'cmd_negate'. This attribute only works with options");
        }
        if (defined $type_constraint
            && $type_constraint->is_a_type_of('Bool')) {
            Moose->throw_error("Parameter $name has 'cmd_negate'. This attribute only works with options");
        }
        if (($from_constraint && $from_constraint->is_a_type_of('Ref'))
            || ($type_constraint && $type_constraint->is_a_type_of('Ref'))) {
            Moose->throw_error("Parameter $name may not have Ref type constraints");
        }
    }

    # Check negate
    if ($self->has_cmd_negate
        && (!$type_constraint || $type_constraint->is_a_type_of('Bool'))) {
        Moose->throw_error("Option $name has 'cmd_negate' but has no Bool type constraint");
    }

    # Check type constraints
    if (defined $type_constraint) {
        if ($self->cmd_count
            && ! $type_constraint->is_a_type_of('Num')) {
            Moose->throw_error("Option $name has 'cmd_count' but has no Num/Int type constraint");
        }
        if ($self->has_cmd_split
            && ! (
                ($from_constraint &&  $from_constraint->is_a_type_of('ArrayRef'))
                || $type_constraint->is_a_type_of('ArrayRef'))
            ) {
            Moose->throw_error("Option $name has 'cmd_split' but has no ArrayRef type constraint");
        }
    }

    # Check for uniqness
    my @names = $self->cmd_name_possible;
    if (scalar(uniq(@names)) != scalar(@names)) {
        Moose->throw_error("Option $name has duplicate names/aliases");
    }

    return;
}

sub cmd_type_constraint_description {
    my ($self,$type_constraint,$singular) = @_;

    $type_constraint //= $self->type_constraint;
    $singular //= 1;

    if ($type_constraint->isa('Moose::Meta::TypeConstraint::Enum')) {
        return 'one of these values: '.join(', ',@{$type_constraint->values});
    } elsif ($type_constraint->isa('Moose::Meta::TypeConstraint::Parameterized')) {
        my $from = $type_constraint->parameterized_from;
        if ($from->is_a_type_of('ArrayRef')) {
            return $self->cmd_type_constraint_description($type_constraint->type_parameter);
        } elsif ($from->is_a_type_of('HashRef')) {
            return 'key-value pairs of '.$self->cmd_type_constraint_description($type_constraint->type_parameter,0);
        }
    # TODO union
    } elsif ($type_constraint->equals('Int')) {
        return $singular ? 'an integer':'integers'; # LOCALIZE
    } elsif ($type_constraint->equals('Num')) {
        return $singular ? 'a number':'numbers'; # LOCALIZE
    } elsif ($type_constraint->equals('Str')) {
        return $singular ? 'a string':'strings';
    } elsif ($type_constraint->equals('HashRef')) {
        return 'key-value pairs'; # LOCALIZE
    }

    if ($type_constraint->has_parent) {
        return $self->cmd_type_constraint_description($type_constraint->parent);
    }

    return;
}

sub cmd_type_constraint_check {
    my ($self,$value) = @_;

    return
        unless ($self->has_type_constraint);
    my $type_constraint = $self->type_constraint;

    if ($type_constraint->has_coercion) {
        $value = $type_constraint->coerce($value)
    }

    # Check type constraints
    unless ($type_constraint->check($value)) {
        if (ref($value) eq 'ARRAY') {
            $value = join(', ',grep { defined } @$value);
        } elsif (ref($value) eq 'HASH') {
            $value = join(', ',map { $_.'='.$value->{$_} } keys %$value)
        }

        # We have a custom message
        if ($type_constraint->has_message) {
            return $type_constraint->get_message($value);
        # No message
        } else {
            my $message_human = $self->cmd_type_constraint_description($type_constraint);
            if (defined $message_human) {
                return "Value must be ". $message_human ." (not '$value')";
            } else {
                return $type_constraint->get_message($value);
            }
        }
    }

    return;
}

sub cmd_usage_description {
    my ($self) = @_;

    my $description = ($self->has_documentation) ? $self->documentation : '';
    my @tags = $self->cmd_tags_list();
    if (scalar @tags) {
        $description .= ' '
            if $description;
        $description .= '['.join('; ',@tags).']';
    }
    return $description
}

sub cmd_usage_name {
    my ($self) = @_;

    if ($self->cmd_type eq 'parameter') {
        return $self->cmd_name_primary;
    } else {
        return join(' ',
            map { (length($_) == 1) ? "-$_":"--$_" }
            $self->cmd_name_possible
        );
    }
}

sub cmd_name_primary {
    my ($self) = @_;

    if ($self->has_cmd_flag) {
        return $self->cmd_flag;
    } else {
        return $self->name;
    }
}

sub cmd_name_list {
    my ($self) = @_;

    my @names = ($self->cmd_name_primary);

    if ($self->has_cmd_aliases) {
        push(@names, @{$self->cmd_aliases});
    }

    return @names;
}

sub cmd_name_possible {
    my ($self) = @_;

    if ($self->cmd_type eq 'parameter') {
        return $self->cmd_name_primary;
    }

    my @names = $self->cmd_name_list();

    # TODO check boolean type constraint
    if ($self->has_cmd_negate) {
        push(@names, @{$self->cmd_negate});
    }

    return @names;
}

sub cmd_tags_list {
    my ($self) = @_;

    my @tags;

    if ($self->is_required
        && ! $self->is_lazy_build
        && ! $self->has_default) {
        push(@tags,'Required')
    }

    if ($self->has_default && ! $self->is_default_a_coderef) {
        if ($self->has_type_constraint
            && $self->type_constraint->is_a_type_of('Bool')) {
#            if ($attribute->default) {
#                push(@tags,'Default:Enabled');
#            } else {
#                push(@tags,'Default:Disabled');
#            }
        } else {
            push(@tags,'Default:"'.$self->default.'"');
        }
    }

    if ($self->has_cmd_split) {
        my $split = $self->cmd_split;
        if (ref($split) eq 'Regexp') {
            $split = "$split";
            $split =~ s/^\(\?\^\w*:(.+)\)$/$1/x;
        }
        push(@tags,'Multiple','Split by "'.$split.'"');
    }

    if ($self->has_type_constraint) {
        my $type_constraint = $self->type_constraint;
        if ($type_constraint->is_a_type_of('ArrayRef')) {
            if (! $self->has_cmd_split) {
                push(@tags,'Multiple');
            }
        } elsif ($type_constraint->is_a_type_of('HashRef')) {
            push(@tags,'Key-Value');
        }
        unless ($self->should_coerce) {
            if ($type_constraint->is_a_type_of('Int')) {
                push(@tags,'Integer');
            } elsif ($type_constraint->is_a_type_of('Num')) {
                push(@tags ,'Number');
            } elsif ($type_constraint->is_a_type_of('Bool')) {
                push(@tags ,'Flag');
            } elsif ($type_constraint->isa('Moose::Meta::TypeConstraint::Enum')) {
                push(@tags ,'Possible values: '.join(', ',@{$type_constraint->values}));
            }
        }
    }

    if ($self->can('has_cmd_env')
        && $self->has_cmd_env) {
        push(@tags,'Env: '.$self->cmd_env)
    }

    if ($self->can('cmd_tags')
        && $self->can('cmd_tags')
        && $self->has_cmd_tags) {
        push(@tags,@{$self->cmd_tags});
    }

    return @tags;
}

{
    package Moose::Meta::Attribute::Custom::Trait::AppOption;

    use strict;
    use warnings;

    sub register_implementation { return 'MooseX::App::Meta::Role::Attribute::Option' }
}

1;

=pod

=encoding utf8

=head1 NAME

MooseX::App::Meta::Role::Attribute::Option - Meta attribute role for options

=head1 DESCRIPTION

This meta attribute role will automatically be applied to all attributes
that should be used as options.

=head1 ACCESSORS

In your app and command classes you can
use the following attributes in option or parameter definitions.

 option 'myoption' => (
     is                 => 'rw',
     isa                => 'ArrayRef[Str]',
     documentation      => 'My special option',
     cmd_flag           => 'myopt',
     cmd_aliases        => [qw(mopt localopt)],
     cmd_tags           => [qw(Important!)],
     cmd_env            => 'MY_OPTION',
     cmd_position       => 1,
     cmd_split          => qr/,/,
     cmd_negate         => 'notoption'
 );

=head2 cmd_flag

Use this name instead of the attribute name as the option name

=head2 cmd_type

Option to mark if this attribute should be used as an option or parameter value.

Allowed values are:

=over

=item * option - Command line option

=item * proto - Command line option that should be processed prior to other
options (eg. a config-file option that sets other attribues) Usually only
used for plugin developmemt

=item * parameter - Positional parameter command line value

=back

=head2 cmd_env

Environment variable name (only uppercase letters, numeric and underscores
allowed). If variable was not specified otherwise the value will be
taken from %ENV.

=head2 cmd_aliases

Arrayref of alternative option names

=head2 cmd_tags

Extra option tags displayed in the usage information (in brackets)

=head2 cmd_position

Override the order of the parameters in the usage message.

=head2 cmd_split

Splits multiple values at the given separator string or regular expression.
Only works in conjunction with an 'ArrayRef[*]' type constraint.
ie. '--myattr value1,value2' with cmd_split set to ',' would produce an
arrayref with to elements.

=head2 cmd_count

Similar to the Getopt::Long '+' modifier, cmd_count turns the attribute into
a counter. Every occurrence of the attribute in @ARGV (without any value)
would increment the resulting value by one

=head2 cmd_negate

Sets names for the negated variant of a boolean field. Only works in conjunction
with a 'Bool' type constraint.

=head1 METHODS

These methods are only of interest to plugin authors.

=head2 cmd_check

Runs sanity checks on options and parameters. Will usually only be executed if
either HARNESS_ACTIVE or APP_DEVELOPER environment are set.

=head2 cmd_name_possible

 my @names = $attribute->cmd_name_possible();

Returns a list of all possible option names.

=head2 cmd_name_list

 my @names = $attribute->cmd_name_list();

Similar to cmd_name_possible this method returns a list of option names,
except for names set via cmd_negate.

=head2 cmd_name_primary

 my $name = $attribute->cmd_name_primary();

Returns the primary option name

=head2 cmd_usage_name

 my $name = $attribute->cmd_usage_name();

Returns the name as used by the usage text

=head2 cmd_usage_description

 my $name = $attribute->cmd_usage_description();

Returns the description as used by the usage text

=head2 cmd_tags_list

 my @tags = $attribute->cmd_tags_list();

Returns a list of tags

=head2 cmd_type_constraint_check

 $attribute->cmd_type_constraint_check($value)

Checks the type constraint. Returns an error message if the check fails

=head2 cmd_type_constraint_description

 $attribute->cmd_type_constraint_description($type_constraint,$singular)

Creates a description of the selected type constraint.

=cut

