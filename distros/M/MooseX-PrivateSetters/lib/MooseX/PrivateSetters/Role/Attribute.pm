package MooseX::PrivateSetters::Role::Attribute;

use strict;
use warnings;

our $VERSION = '0.08';

use Moose::Role;

before '_process_options' => sub {
    my $class   = shift;
    my $name    = shift;
    my $options = shift;

    if ( exists $options->{is} &&
           ! ( exists $options->{reader} || exists $options->{writer} ) ) {
        if ( $options->{is} eq 'ro' ) {
            $options->{reader} = $name;
            delete $options->{is};
        }
        elsif ( $options->{is} eq 'rw' ) {
            $options->{reader} = $name;
            my $prefix = $name =~ /^_/  ?  '_set'  :  '_set_';
            $options->{writer} = $prefix . $name;

            delete $options->{is};
        }
    }
};

no Moose::Role;

1;

=head1 NAME

MooseX::PrivateSetters::Role::Attribute - Names setters as such, and makes them private

=head1 SYNOPSIS

    Moose::Exporter->setup_import_methods(
        class_metaroles => {
            attribute => ['MooseX::PrivateSetters::Role::Attribute'],
        },
    );

=head1 DESCRIPTION

This role applies a method modifier to the C<_process_options()>
method, and tweaks the writer parameters so that they are private with
an explicit '_set_attr' method. Getters are left unchanged. This role
copes with attributes intended to be private (ie, starts with an
underscore), with no double-underscore in the setter.

For example:

    | Code                      | Reader | Writer      |
    |---------------------------+--------+-------------|
    | has 'baz'  => (is 'rw');  | baz()  | _set_baz()  |
    | has 'baz'  => (is 'ro');  | baz()  |             |
    | has '_baz' => (is 'rw');  | _baz() | _set_baz()  |
    | has '__baz' => (is 'rw'); | _baz() | _set__baz() |

You probably don't want to use this module. You probably should be
looking at L<MooseX::PrivateSetters> instead.

=head1 AUTHOR

brian greenfield C<< <briang@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 brian greenfield

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
