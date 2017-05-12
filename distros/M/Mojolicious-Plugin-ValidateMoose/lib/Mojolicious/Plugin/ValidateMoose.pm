package Mojolicious::Plugin::ValidateMoose;

=head1 NAME

Mojolicious::Plugin::ValidateMoose - Can validate using Moose objects

=head1 VERSION

0.02

=head1 DESCRIPTION

This module is handy if you want to validate POST/GET parameters
using L<Moose> classes.

=head1 SYNOPSIS

    package MyApp;
    use Mojo::Base 'Mojolicious';
    sub startup {
        my $self = shift;

        $self->plugin('Mojolicious::Plugin::ValidateMoose');

        # ...
    }

    package MyApp::Root;
    use Mojo::Base 'Mojolicious::Controller';
    sub foo {
        my $self = shift;

        if($self->req->method eq 'POST') {
            if(my $obj = $self->validate_moose('My::Moose::Class')) {
                # input validate, and $obj created from My::Moose::Class
                # with the params set as attributes
            }
        }
    }

=cut

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = eval '0.02';

=head1 HELPERS

=head2 validate_moose

    $obj = $controller->validate_moose($moose_class, \%args);
    $obj = $controller->validate_moose($moose_obj, \%args);

Will either update an existing or create a new L<Moose> object, if all
the attributes gets validated. If any of the attributes is not updated
with the right value from C<param()>, this method will set
C<invalid_form_elements> in the stash to a datastructure like this:

    {
        $param_name_a => 'required', # fixed
        $param_name_b => 'moose exception message', # custom
    }

Example moose exception message:

    Validation failed for 'Int' with value "asd"

The method will return empty list if it fail to validate the input.

=cut

sub validate_moose {
    my($c, $class, $args) = @_;
    my $obj = ref $class ? $class : undef;
    my $meta = $class->meta;
    my(%constructor_args, %invalid);

    ATTRIBUTE:
    for my $attr (__get_attributes($meta, $args)) {
        my $name = $attr->name;
        my $type = $attr->type_constraint;
        my $value = $c->param($name);

        if(!defined $value) {
            if(!$obj and $attr->is_required) {
                $invalid{$name} = 'required';
            }
        }
        elsif(length $value == 0 and $attr->is_required) {
            $invalid{$name} = 'required';
        }
        elsif($type and not $type->check($value)) {
            eval {
                $constructor_args{$name} = $type->assert_coerce($value);
                1;
            } or do {
                $invalid{$name} = $type->get_message($value);
            }
        }
        elsif(!$obj or $attr->get_write_method) {
            $constructor_args{$name} = $value;
        }
    }

    if(%invalid) {
        $c->stash(invalid_form_elements => \%invalid);
        return;
    }
    elsif($obj) {
        for my $name (keys %constructor_args) {
            $obj->$name($constructor_args{$name});
        }
    }
    else {
        $obj = $class->new(%constructor_args);
    }

    return $obj;
}

sub __get_attributes {
    my($meta, $args) = @_;
    return map { $meta->get_attribute($_) } @{ $args->{'attributes'} } if($args->{'attributes'});
    return $meta->get_all_attributes;
}

=head1 METHODS

=head2 register

Will register the methods undef L</HELPERS> as L<Mojolicious> helpers.

=cut

sub register {
    my($self, $app, $config) = @_;

    $app->helper(validate_moose => \&validate_moose);
}

=head1 COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen - jhthorsen at cpan.org

=cut

1;
