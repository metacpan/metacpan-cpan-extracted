package MouseX::Foreign::Meta::Role::Method::Destructor;
use Mouse::Role;

around _generate_destructor => sub {
    my($next, undef, $meta) = @_;

    my $foreign_superclass = $meta->foreign_superclass;

    my $super_destroy;
    if(!$foreign_superclass->can('DEMOLISHALL')){
        $super_destroy = $foreign_superclass->can('DESTROY');
    }

    return sub {
        my($self) = @_;
        $self->DEMOLISHALL();

        if(defined $super_destroy) {
            $self->$super_destroy();
        }
        return;
    };
};

no Mouse::Role;
1;
__END__

=head1 NAME

MouseX::Foreign::Meta::Role::Method::Destructor - The MouseX::Foreign meta method destructor role

=head1 VERSION

This document describes MouseX::Foreign version 1.000.

=head1 DESCRIPTION

This is the meta method destructor role for MouseX::Foreign.

=head1 SEE ALSO

L<MouseX::Foreign>

=cut
