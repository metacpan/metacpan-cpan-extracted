package MockVT;
use strict;
use warnings;
use parent 'Term::VT102';
use NetHack::Menu;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{return_rows} = [];
    $self->{checked_rows} = [];
    return $self;
}

sub checked_rows {
    my $self = shift;
    return @{ $self->{checked_rows} }
}

sub return_rows {
    my $self = shift;
    push @{ $self->{return_rows} }, @_;
}

sub next_return_row {
    my $self = shift;
    return shift @{ $self->{return_rows} };
}

sub rows { 24 }

sub row_plaintext {
    my $self = shift;
    push @{ $self->{checked_rows} }, shift;
    return '' if $self->{checked_rows}[-1] == 0;
    $self->next_return_row;
}

sub checked_ok {
    my $self = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::is_deeply([splice @{ $self->{checked_rows} }], @_);
}

1;

