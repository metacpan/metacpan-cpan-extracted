package Nephia::Request;
use strict;
use warnings;
use parent 'Plack::Request::WithEncoding';

sub uri {
    my $self = shift;

    $self->{uri} ||= $self->SUPER::uri;
    $self->{uri}->clone; # avoid destructive opearation
}

sub base {
    my $self = shift;

    $self->{base} ||= $self->SUPER::base;
    $self->{base}->clone; # avoid destructive operation
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Request - Request Class for Nephia

=head1 DESCRIPTION

A subclass of Plack::Request

=head1 SYNOPSIS

    my $req = Nephia::Request->new( $env );

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

