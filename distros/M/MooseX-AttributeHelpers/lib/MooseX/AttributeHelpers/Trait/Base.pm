package MooseX::AttributeHelpers::Trait::Base;
# ABSTRACT: base role for helpers

use Moose::Role;
use Moose::Util::TypeConstraints;

our $VERSION = '0.25';

requires 'helper_type';

# this is the method map you define ...
has 'provides' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}}
);

has 'curries' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}}
);

# these next two are the possible methods
# you can use in the 'provides' map.

# provide a Class or Role which we can
# collect the method providers from

# requires_attr 'method_provider'

# or you can provide a HASH ref of anon subs
# yourself. This will also collect and store
# the methods from a method_provider as well
has 'method_constructors' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return +{} unless $self->has_method_provider;
        # or grab them from the role/class
        my $method_provider = $self->method_provider->meta;
        return +{
            map {
                $_ => $method_provider->get_method($_)
            }
            grep { $_ ne 'meta' } $method_provider->get_method_list
        };
    },
);

## Methods called prior to instantiation

sub process_options_for_provides {
    my ($self, $options) = @_;

    if (my $type = $self->helper_type) {
        (exists $options->{isa})
            || confess "You must define a type with the $type metaclass";

        my $isa = $options->{isa};

        unless (blessed($isa) && $isa->isa('Moose::Meta::TypeConstraint')) {
            $isa = Moose::Util::TypeConstraints::find_or_create_type_constraint($isa);
        }

        ($isa->is_a_type_of($type))
            || confess "The type constraint for a $type ($options->{isa}) must be a subtype of $type";
    }
}

before '_process_options' => sub {
    my ($self, $name, $options) = @_;
    $self->process_options_for_provides($options, $name);
};

## methods called after instantiation

sub check_provides_values {
    my $self = shift;

    my $method_constructors = $self->method_constructors;

    foreach my $key (keys %{$self->provides}) {
        (exists $method_constructors->{$key})
            || confess "$key is an unsupported method type";
    }

    foreach my $key (keys %{$self->curries}) {
        (exists $method_constructors->{$key})
            || confess "$key is an unsupported method type";
    }
}

sub _curry {
    my $self = shift;
    my $code = shift;

    my @args = @_;
    return sub {
        my $self = shift;
        $code->($self, @args, @_)
    };
}

sub _curry_sub {
    my $self = shift;
    my $body = shift;
    my $code = shift;

    return sub {
        my $self = shift;
        $code->($self, $body, @_)
    };
}

after 'install_accessors' => sub {
    my $attr  = shift;
    my $class = $attr->associated_class;

    # grab the reader and writer methods
    # as well, this will be useful for
    # our method provider constructors
    my $attr_reader = $attr->get_read_method_ref;
    my $attr_writer = $attr->get_write_method_ref;


    # before we install them, lets
    # make sure they are valid
    $attr->check_provides_values;

    my $method_constructors = $attr->method_constructors;

    my $class_name = $class->name;

    while (my ($constructor, $constructed) = each %{$attr->curries}) {
        my $method_code;
        while (my ($curried_name, $curried_arg) = each(%$constructed)) {
            if ($class->has_method($curried_name)) {
                confess
                    "The method ($curried_name) already ".
                    "exists in class (" . $class->name . ")";
            }
            my $body = $method_constructors->{$constructor}->(
                       $attr,
                       $attr_reader,
                       $attr_writer,
            );

            if (ref $curried_arg eq 'ARRAY') {
                $method_code = $attr->_curry($body, @$curried_arg);
            }
            elsif (ref $curried_arg eq 'CODE') {
                $method_code = $attr->_curry_sub($body, $curried_arg);
            }
            else {
                confess "curries parameter must be ref type ARRAY or CODE";
            }

            my $method = MooseX::AttributeHelpers::Meta::Method::Curried->wrap(
                $method_code,
                package_name => $class_name,
                name => $curried_name,
            );

            $attr->associate_method($method);
            $class->add_method($curried_name => $method);
        }
    }

    foreach my $key (keys %{$attr->provides}) {

        my $method_name = $attr->provides->{$key};

        if ($class->has_method($method_name)) {
            confess "The method ($method_name) already exists in class (" . $class->name . ")";
        }

        my $method = MooseX::AttributeHelpers::Meta::Method::Provided->wrap(
            $method_constructors->{$key}->(
                $attr,
                $attr_reader,
                $attr_writer,
            ),
            package_name => $class_name,
            name => $method_name,
        );
        
        $attr->associate_method($method);
        $class->add_method($method_name => $method);
    }
};

after 'remove_accessors' => sub {
    my $attr  = shift;
    my $class = $attr->associated_class;

    # provides accessors
    foreach my $key (keys %{$attr->provides}) {
        my $method_name = $attr->provides->{$key};
        my $method = $class->get_method($method_name);
        $class->remove_method($method_name)
            if blessed($method) &&
               $method->isa('MooseX::AttributeHelpers::Meta::Method::Provided');
    }

    # curries accessors
    foreach my $key (keys %{$attr->curries}) {
        my $method_name = $attr->curries->{$key};
        my $method = $class->get_method($method_name);
        $class->remove_method($method_name)
            if blessed($method) &&
               $method->isa('MooseX::AttributeHelpers::Meta::Method::Provided');
    }
};

no Moose::Role;
no Moose::Util::TypeConstraints;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::Trait::Base - base role for helpers

=head1 VERSION

version 0.25

=head1 METHODS

=head2 check_provides_values

Confirms that provides (and curries) has all valid possibilities in it.

=head2 process_options_for_provides

Ensures that the type constraint (C<isa>) matches the helper type.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-AttributeHelpers>
(or L<bug-MooseX-AttributeHelpers@rt.cpan.org|mailto:bug-MooseX-AttributeHelpers@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

Stevan Little <stevan@iinteractive.com>

Yuval Kogman

Shawn M Moore

Jesse Luehrs

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Stevan Little and Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
