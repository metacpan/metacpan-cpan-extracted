package UserForm;
use base Rose::HTML::Form;

sub build_form {
    my($self) = shift;

    $self->add_fields (
        name  => { type => 'text',  size => 100, required => 1, },
        password => { type => 'password',  size => 100, required => 1, },
        username  => { type => 'text',  size => 100, required => 1, },
    );
}

1;

