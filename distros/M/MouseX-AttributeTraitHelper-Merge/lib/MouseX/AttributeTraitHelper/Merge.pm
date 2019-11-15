package MouseX::AttributeTraitHelper::Merge;
use Mouse::Role;
use Mouse::Util;

has TRAIT_MAPPING => (
    is => 'ro',
    isa => 'HashRef[ClassName]',
    default => sub {return {}},
);

around add_attribute => sub {
    my ($orig, $self) = (shift, shift);

    return $self->$orig($_[0]) if Scalar::Util::blessed($_[0]);
    
    my $name = shift;
    my %args = (@_ == 1) ? %{$_[0]} : @_;

    defined($name)
        or $self->throw_error('You must provide a name for the attribute');

    my $traits = delete $args{traits};
    if ($traits) {
        my $role_name;
        if (@$traits == 1) {
            $role_name = $traits->[0];
        }
        else {
            $role_name = join "::" , 'MouseX::AttributeTraitHelper::Merge' , @$traits;
            if (!Mouse::Util::is_class_loaded($role_name)) {
                my $meta = Mouse::Role->init_meta(for_class => $role_name);
                $meta->add_around_method_modifier('does' => sub {
                    my ($orig_meta, $self_meta, $role) = @_;
                    if ($self->TRAIT_MAPPING->{$role}){
                        return 1;
                    }
                    else {
                        return $self->$orig($name)
                    }
                });
                for my $trait (@$traits) {
                    $self->TRAIT_MAPPING->{$trait} = $role_name;
                    Mouse::Util::load_class($trait);
                    for my $trait_attr_name ($trait->meta->get_attribute_list()) {
                        my $trait_attr = $trait->meta->get_attribute($trait_attr_name);
                        $trait_attr_name =~ s/^\+//;
                        my $exist_trait_attr = $meta->get_attribute($trait_attr_name);
                        if ($exist_trait_attr) {
                            @$exist_trait_attr{keys %$trait_attr} = values %$trait_attr;
                        }
                        else {
                            $meta->add_attribute($trait_attr_name => {is => 'ro', %$trait_attr});
                        }
                    }
                }
            }
        }
        $args{traits} = [$role_name];
    }
    return $self->$orig($name, %args);
};

no Mouse::Role;
1;
__END__

=head1 NAME

MouseX::AttributeTraitHelper::Merge - Extend your attribute traits interface for L<Mouse>

=head1 VERSION

This document describes MouseX::AttributeTraitHelper::Merge version 0.90.

=head1 SYNOPSIS

    package ClassWithTrait;
    use Mouse -traits => 'MouseX::AttributeTraitHelper::Merge';
    
    has attrib => (
        is => 'rw',
        isa => 'Int',
        traits => ['Trait1', 'Trait2'],
    );
    
    no Mouse;
    __PACKAGE__->meta->make_immutable();

=head1 DESCRIPTION

If you needs to use many traits for attribute with overlapped field name this solution for you!

This role replace all trait for attribute by one new trait. For example:

You have two traits:

    package Trait1;
    use Mouse::Role;
    
    has 'allow' => (isa => 'Int', default => 123);
    
    no Mouse::Role;
    
    package Trait2;
    use Mouse::Role;
    
    has 'allow' => (isa => 'Str', default => 'qwerty');
    
    no Mouse::Role;

Both add fields to attribute with same name. In this case L<Mouse> throw the exception:
"We have encountered an attribute conflict with 'allow' during composition. This is fatal error and cannot be disambiguated."

Usage of a '+' before role attribute was not supported.

Solution:

    package ClassWithTrait;
    use Mouse -traits => 'MouseX::AttributeTraitHelper::Merge';
    
    has attrib => (
        is => 'rw',
        isa => 'Int',
        traits => ['Trait1', 'Trait2'],
    );
    
    no Mouse;
    __PACKAGE__->meta->make_immutable();

In this case Trait1 and Trait2 merged in MouseX::AttributeTraitHelper::Merge::Trait1::Trait2 and applied to atribute `attrib`.
The last `Trait` in the list is the highest priority and rewrite attribute fields.

In this case attribute `attrib` has field `allow` with type `Str` and dafault value `qwerty`.

But method `does` still work correctly:
`ClassWithTrait->meta->get_attribute('attrib')->does('Trait1')` or `ClassWithTrait->meta->get_attribute('attrib')->does('Trait2')` returns true

The last may confuse the developer because `Trait1` exports the `allow` field of type `Int`, but ultimately `allow` is of type `Str`

=head1 DEPENDENCIES

Perl 5.8.8 or later.

=head1 BUGS

=head1 SEE ALSO

L<Mouse>

L<Mouse::Role>

L<Mouse::Meta::Role>

L<Mouse::Meta::Class>

=head1 AUTHORS

Nikolay Shulyakovskiy (nikolas) E<lt>nikolas(at)cpan.orgE<gt> 

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2019, Nikolay Shulyakovskiy (nikolas)
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.
 
=cut
 
