package
    T::HTTPTiny; # hide from PAUSE

use v5.10;
use strict;
use warnings;

use parent 'Pinto::Remote::SelfContained::Httptiny';

use Class::Method::Modifiers qw(around fresh);
use T::Handle;

use namespace::clean;

our $VERSION = '1.000';

sub new {
    my $class = shift;
    my $responses = shift;
    my $self = $class->SUPER::new(@_);
    exists $self->{$_} and die "'$_' already set in HTTP::Tiny instance"
        for qw(requests responses);
    $self->{requests} = [];
    $self->{responses} = $responses;
    return $self;
}

# Use "fresh" to ensure the method doesn't exist in the parent
fresh requests  => sub { $_[0]{requests} };
fresh responses => sub { $_[0]{responses} };

# Use "around" to ensure the method *does* exist in the parent
around can_ssl => sub { 1 };
around _open_handle => sub {
    my (undef, $self, $request, $scheme, $host, $port, $peer) = @_;

    push @{ $self->requests }, { %$request };
    my $buffer = shift(@{ $self->responses }) // '';
    return T::Handle->new(buffer => $buffer, request => $self->requests->[-1]);
};

1;
