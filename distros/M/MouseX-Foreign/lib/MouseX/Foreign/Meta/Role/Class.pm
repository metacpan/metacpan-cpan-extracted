package MouseX::Foreign::Meta::Role::Class;
use Mouse::Role;
use Mouse::Util::MetaRole;

__PACKAGE__->meta->add_metaclass_accessor('foreign_superclass');

after superclasses => sub {
    my($self, @args) = @_;
    if(@args && !$self->name->isa('Mouse::Object')) {
        push @{$self->{superclasses}}, 'Mouse::Object';
    }
    return;
};

before verify_superclass => sub {
    my($self, $super, $super_meta) = @_;

    if(defined($super_meta) && $super_meta->does(__PACKAGE__)) {
        $self->inherit_from_foreign_class($super);
    }
    return;
};

sub inherit_from_foreign_class { # override
    my($self, $super) = @_;
    if(defined $self->foreign_superclass) {
        $self->throw_error(
            "Multiple inheritance"
            . " from foreign classes ($super, "
            . $self->foreign_superclass
            . ") is forbidden");
    }
    my %traits;
    if($super->can('new')) {
        $traits{constructor} = ['MouseX::Foreign::Meta::Role::Method::Constructor'];
    }
    if($super->can('DESTROY')) {
        $traits{destructor}  = ['MouseX::Foreign::Meta::Role::Method::Destructor'];
    }
    if(%traits) {
        $self->foreign_superclass($super);
        $_[0] = $self = Mouse::Util::MetaRole::apply_metaroles(
            for             => $self,
            class_metaroles => \%traits,
        );

        # FIXME
        $self->add_method(
            new => $self->constructor_class->_generate_constructor($self),
        );
        $self->add_method(
            DESTROY => $self->destructor_class->_generate_destructor($self),
        );
    }
    return;
}

no Mouse::Role;
1;
__END__

=head1 NAME

MouseX::Foreign::Meta::Role::Class - The MouseX::Foreign meta class role

=head1 DESCRIPTION

This is the meta class role for MouseX::Foreign.

=head1 SEE ALSO

L<MouseX::Foreign>

=cut
