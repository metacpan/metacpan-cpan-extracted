package UserForm2;
use strict;
use base 'Rose::HTML::Form';
use Rose::HTML::Form::Repeatable;
use DvdForm2;

sub build_form {
    my($self) = shift;

    $self->add_fields (
        name  => { type => 'text',  size => 100, required => 1, },
        username => { type => 'text',  size => 100, required => 1, },
        password => { type => 'text',  size => 100, required => 1, },
    );
    $self->add_forms (
        owned_dvds => {
            form => DvdForm2->new,
            repeatable => 1,
        }
    )
}

1;

