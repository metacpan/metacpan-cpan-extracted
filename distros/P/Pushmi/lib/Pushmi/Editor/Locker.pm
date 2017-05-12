package Pushmi::Editor::Locker;
use strict;
use base 'SVK::Editor::ByPass';

__PACKAGE__->mk_accessors(qw(on_close_edit));

sub close_edit {
    my $self = shift;
    $self->on_close_edit->();
    $self->SUPER::close_edit(@_);
}

1;

