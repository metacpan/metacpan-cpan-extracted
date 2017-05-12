#
# This file is part of MooseX-Role-AttributeOverride
#
# This software is copyright (c) 2011 by Edward J. Allen III.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package MooseX::Role::AttributeOverride::Meta::Trait::Role;
BEGIN {
  $MooseX::Role::AttributeOverride::Meta::Trait::Role::VERSION = '0.0.9';
}
BEGIN {
  $MooseX::Role::AttributeOverride::Meta::Trait::Role::AUTHORITY = 'cpan:EALLENIII';
}
# ABSTRACT: Support Role for L<MooseX::Role::AttributeOverride|MooseX::Role::AttributeOverride>

use 5.008;
use utf8;

use strict;
use warnings;
use Moose::Role;

has 'attribute_modifiers' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => { add_attribute_modifier => 'push', }
);

sub apply_modifiers_to_class {
    my ( $role, $class ) = @_;
    for ( @{ $role->attribute_modifiers } ) {
        my ( $name, $opts ) = @{$_};
        my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
        for my $attr ( @{$attrs} ) {
            $role->apply_modifier_to_attribute( $class, $attr, $opts );
        }
    }
    return $class;
}

sub apply_modifier_to_attribute {
    my ( $role, $class, $attr, $opts ) = @_;
    my $attr_obj = $class->find_attribute_by_name($attr);
    ## no critic (ProhibitAccessOfPrivateData);
    if ($attr_obj) {
        if ( exists $opts->{override_ignore_missing} ) {
            delete $opts->{override_ignore_missing};
        }
        $class->add_attribute(
            $role->clone_attr_and_inherit_options( $attr_obj, %{$opts} ) );
    }
    else {
        my $error = qq{Can't find attribute $attr required by } . $role->name;
        require Moose;
        if (   ( !exists $opts->{override_ignore_missing} )
            || ( !       $opts->{override_ignore_missing} ) ) {
            Moose->throw_error($error);
        }
        return;
    }
    ## use critic;
    return $attr_obj;
}


# Based on clone_and_inherit_options from Moose::Meta::Attribute.

sub clone_attr_and_inherit_options {
    my ($role, $attr, %options) = @_;

    ## no critic (ProhibitAccessOfPrivateData);

    my @illegal_options = $attr->can('illegal_options_for_inheritance')
        ? $attr->illegal_options_for_inheritance
        : ();

    my @found_illegal_options = grep { exists $options{$_} && exists $attr->{$_} ? $_ : undef } @illegal_options;
    (scalar @found_illegal_options == 0)
        || $attr->throw_error("Illegal inherited options => (" . (join ', ' => @found_illegal_options) . ")", data => \%options);

    if ($attr->can('interpolate_class')) {
        ( $options{metaclass}, my @traits ) = $attr->interpolate_class(\%options);

        my %seen;
        my @all_traits = grep { $seen{$_}++ } @{ $attr->applied_traits || [] }, @traits;
        if (@all_traits) {
            $options{traits} = \@all_traits;
        }
    }

    if ($options{coerce} && (! exists $options{isa})) {
        $options{isa} = $attr->type_constraint;
    }

    if ($attr->can('_process_options')) {
        $options{metaclass}->_process_options( $attr->name, \%options )
    }
    
    ## use critic; 
    return $attr->clone(%options);
}

sub add_modifiers_from_role {
    my ( $role_a, $role_b ) = @_;
    $role_a->add_attribute_modifier( @{ $role_b->attribute_modifiers } );
    return $role_a;
}

around 'composition_class_roles' => sub {
    my ($orig,$self) = @_;
    return ($self->$orig, 'MooseX::Role::AttributeOverride::Meta::Trait::Role::Composite');
};

no Moose::Role;
1; # Magic true value required at end of module


=pod

=for :stopwords Edward Allen <ealleniii_at_cpan_dot_org> J. III

=encoding utf-8

=head1 NAME

MooseX::Role::AttributeOverride::Meta::Trait::Role - Support Role for L<MooseX::Role::AttributeOverride|MooseX::Role::AttributeOverride>

=head1 VERSION

  This document describes v0.0.9 of MooseX::Role::AttributeOverride::Meta::Trait::Role - released June 29, 2011 as part of MooseX-Role-AttributeOverride.

=head1 SYNOPSIS

See L<MooseX::Role::AttributeOverride|MooseX::Role::AttributeOverride>

=head1 DESCRIPTION

Apply this role to L<Moose::Meta::Role|Moose::Meta::Role>.

=head1 METHODS

=head2 composition_class_roles

=head2 add_modifiers_from_role

=head2 apply_modifiers_to_class

=head2 apply_modifier_to_attribute

=head2 attribute_modifiers

=head2 add_attribute_modifier

=head2 clone_attr_and_inherit_options
This is a hacked version of Moose::Meta::Attributes to fix issues with traits
that hack _process_options.

=head1 DIAGNOSTICS

See L<MooseX::Role::AttributeOverride|MooseX::Role::AttributeOverride>

=head1 DEPENDENCIES

See L<MooseX::Role::AttributeOverride|MooseX::Role::AttributeOverride>

=head1 INCOMPATIBILITIES

See L<MooseX::Role::AttributeOverride|MooseX::Role::AttributeOverride>

=head1 BUGS AND LIMITATIONS

See L<MooseX::Role::AttributeOverride|MooseX::Role::AttributeOverride>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::Role::AttributeOverride|MooseX::Role::AttributeOverride>

=back

=head1 AUTHOR

Edward Allen <ealleniii_at_cpan_dot_org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edward J. Allen III.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

