package Pegex::vCard::Data;

use Pegex::Base;
extends 'Pegex::Tree';

has data => {};

sub final {
    my ($self, $got) = @_;
    return $self->data;
}

sub got_info_line {
    my ($self, $got) = @_;
    my ($key, $value) = @$got;
    my @keys = grep { $_ !~ /=/ } split ';', $key;
    my $values = [ split ';', $value ];
    $values = $values->[0] if @$values == 1;
    my $insert = $self->data;
    while (@keys > 1) {
        $insert = $insert->{shift @keys} = {};
    }
    $insert = $insert->{shift @keys} = $values;
}

1;
