package Plack::App::EventSource::Connection;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{push_cb}  = $params{push_cb};
    $self->{close_cb} = $params{close_cb};

    return $self;
}

sub push {
    my $self = shift;

    $self->{push_cb}->(@_);
}

sub close {
    my $self = shift;

    $self->{close_cb}->();
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Plack::App::EventSource::Connection - Connection object

=head1 SYNOPSIS

Used internally by L<Plack::App::EventSource>.

=head1 DESCRIPTION

This is a connection object that you get in C<handler_cb> callback.

=head1 METHODS

=head2 C<new>

Creates new object.

=head2 C<close>

Closes connection.

=head2 C<push>

Pushes data to the client. Accepts an array of messages, which themselves can
be strings or hash references.

    $conn->push('message');
    $conn->push('multi', 'line', 'message');
    $conn->push({id => 1, data => 'message with id'});

possible hash fields are C<event>, C<id>, C<data>, and C<retry>.

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
