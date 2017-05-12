package t::Class::Extended;

use OO::InsideOut qw(id register);

use base qw(
        t::Class::Simple
        t::Class::MixedIn
    );

our %Register = register \our %Surname;

sub surname { 
    my $id = id shift;

    scalar @_
        and $Surname{ $id } = shift;

    return $Surname{ $id };
}

sub fullname {
    my $self = shift;
    return join( ' ', $self->name, $self->middlename, $self->surname );
}

1;
