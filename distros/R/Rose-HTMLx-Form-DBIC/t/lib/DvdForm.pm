package DvdForm;
use base Rose::HTML::Form;

#use lib '../Rose-HTMLx-Form-Field-DateTimeSelect/lib/';
#use Rose::HTMLx::Form::Field::DateTimeSelect;
use UserForm;

sub build_form {
    my($self) = shift;
#    my $datetime_field = Rose::HTMLx::Form::Field::DateTimeSelect->new( name => 'creation_date', label => 'aaaaaaaaaa', );

    $self->add_fields (
        name  => { type => 'text',  size => 100, required => 1, },
        tags  => { type => 'selectbox',  multiple => 1, },
        owner => { type => 'selectbox',   },
#        creation_date => $datetime_field,
    );
    $self->add_forms ( current_borrower => UserForm->new );
}

1;

