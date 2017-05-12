package TestApp::Form::Field::Password;
our $VERSION = '0.2102';


use Moose;
extends 'Spark::Form::Field';

has confirm => (
    isa => 'Maybe[Str]',
    is  => 'ro',
);

sub _validate {
    my ($self) = @_;

    if (length($self->value || '') < 6) {
        $self->error('Password must be at least 6 characters long');
    }
    if ($self->confirm) {
        my $other = $self->form->get($self->confirm);
        if ($other->value ne $self->value) {
            $self->error('passwords must match');
        }
    }
}

sub to_html {
    q{<input type="password">};
}

sub to_xhtml {
    q{<input type="password" />};
}

1;
