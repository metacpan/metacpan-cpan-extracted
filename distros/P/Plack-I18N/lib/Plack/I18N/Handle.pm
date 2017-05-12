package Plack::I18N::Handle;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{language} = $params{language};
    $self->{handle}   = $params{handle};

    return $self;
}

sub language { $_[0]->{language} }

sub loc { &maketext }

sub maketext {
    my $self = shift;

    return $self->{handle}->maketext(@_);
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Plack::I18N::Handle - Module

=head1 SYNOPSIS



=head1 DESCRIPTION

Used internally by L<Plack::I18N>.

=head1 METHODS

=head2 C<new>

Creates new object.

=head2 C<language>

Returns current language.

=head2 C<loc>

    $handle->loc('Hello');

Localizes the message according to the current language.

=head2 C<maketext>

Same as C<loc>.

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
