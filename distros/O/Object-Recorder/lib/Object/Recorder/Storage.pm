package Object::Recorder::Storage;
use warnings;
use strict;

=head1 NAME

Object::Recorder::Storage - Serializable data structure for Object::Recorder

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module makes it possible to record method calls issued to a set of objects
inti a serializable container which can later be replayed, perfoming the actual
method calls.

=head1 CLASS METHODS

=cut

=head2 new ($object_class, $constructor, @args)

Builds a new storage object.

=cut

sub new {
    my $class = shift;
    my ($object_class, $constructor, @args) = @_;

    bless { 
        calls        => [], 
        object_class => $object_class,
        constructor  => $constructor,
        args         => \@args
    }, $class;
}

=head2 AUTOLOAD

Arbitrary method calls are stored using AUTOLOAD. It will return another 
L<Object::Recorder::Storage> instance so that method calls on return values 
from another recorded method calls will also be properly recorded.

=cut

our $AUTOLOAD;

sub AUTOLOAD {
    my ($self, @args) = @_;
    my ($method) = ($AUTOLOAD =~ /::([^:]+?)$/);

    return if $method eq 'DESTROY';
    
    # only handle methods which return just one value
    my $return = (ref $self)->new;
    
    push @{$self->{calls}}, {
        method => $method,
        args   => [ @args ],
        retval => $return
    };
    
    return $return;
}

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2007 Nilson Santos Figueiredo Junior.
Copyright (C) 2007 Picturetrail, Inc.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
