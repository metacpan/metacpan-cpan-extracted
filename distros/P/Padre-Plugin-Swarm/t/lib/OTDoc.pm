package t::lib::OTDoc;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $body = shift;
    return bless \$body , $class;
}

sub insert {
    my $self = shift;
    my $pos  = shift;
    my $data = shift;
    substr( $$self, $pos, 0, $data );
}

sub delete {
    my $self = shift;
    my $pos = shift;
    my $data = shift;
    my $deleted = substr( $$self, $pos, length($data) , '' );
    die "Deleting '$data' at $pos did not match; '$deleted'"
        unless $deleted eq $data;
}

sub document_body { $$_[0] };


1;
