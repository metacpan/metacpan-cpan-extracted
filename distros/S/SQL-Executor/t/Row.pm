package t::Row;
use strict;
use warnings;

sub new {
    my ($class, $row_href) = @_;
    my $self = $row_href;
    bless $self, $class;
}
sub name { 
    return 'callback';
}
sub id {
    my ($self) = @_;
    return $self->{id};
}
sub value {
    my ($self) = @_;
    return $self->{value};
}


1;
