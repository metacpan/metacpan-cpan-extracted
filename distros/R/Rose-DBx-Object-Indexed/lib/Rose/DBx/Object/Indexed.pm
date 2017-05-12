package Rose::DBx::Object::Indexed;

use warnings;
use strict;
use base qw( Rose::DB::Object );
use Carp;
use Class::C3;
use Rose::DBx::Object::Indexed::Indexer;

use Rose::Object::MakeMethods::Generic (
    boolean                 => [ 'index_eligible' => { default => 0 }, ],
    'scalar --get_set_init' => 'indexer',
    'scalar --get_set_init' => 'indexer_class',
);

our $VERSION = '0.009';

=head1 NAME

Rose::DBx::Object::Indexed - full-text search for RDBO classes

=head1 SYNOPSIS

 package MyRDBO;
 use strict;
 use base qw( Rose::DBx::Object::Indexed );
 
 sub index_eligible { 1 }
 
 1;

=head1 DESCRIPTION

Rose::DBx::Object::Indexed is a base class like Rose::DB::Object,
with the added feature that your objects are added to a full-text index
every time they are saved.

The idea is that you can provide full-text search for your database simply
by subclassing Rose::DBx::Object::Indexed instead of Rose::DB::Object
directly.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 init_index_eligible

Boolean indicating whether this class should be indexed on insert,
update and delete.

The default is false (off), which means that even though you may
subclass Rose::DBx::Object::Indexed, you must still turn the flag
on by setting index_eligible() to true in the specific subclasses
you want included in the index. This allows you to have a common base
class that inherits from Rose::DBx::Object::Indexed and then selectively
index various subclasses of your common base class.

=cut

sub init_index_eligible {0}

=head2 init_indexer_class 

Returns the name of the indexer class. 
The default is 'Rose::DBx::Object::Indexed::Indexer'.

=cut

sub init_indexer_class {'Rose::DBx::Object::Indexed::Indexer'}

=head2 init_indexer( I<args> )

Returns a new instance of indexer_class(). I<args> are passed through to
the indexer_class new() method.

=cut

sub init_indexer {
    my $self = shift;

    # call as class or object method just for kinder api
    $self = $self->new unless ref($self);

    $self->indexer_class->new(@_);
}

=head2 insert

Calls through to next::method and then indexes the object if index_eligible() is true.

=cut

sub insert {
    my $self = shift;
    my $ret  = $self->next::method(@_);
    if ( $ret and $self->index_eligible ) {
        $self->write_index('insert');
    }
    return $ret;
}

=head2 update

Calls through to next::method and then indexes the object if index_eligible() is true.

=cut

sub update {
    my $self = shift;
    my $ret  = $self->next::method(@_);
    if ( $ret and $self->index_eligible ) {
        $self->write_index('update');
    }
    return $ret;
}

=head2 delete

Calls through to next::method and then indexes the object if index_eligible() is true.

=cut

sub delete {
    my $self = shift;
    my $ret  = $self->next::method(@_);
    if ( $ret and $self->index_eligible ) {
        $self->write_index('delete');
    }
    return $ret;
}

=head2 write_index( I<mode> )

Passes the object ($self) on to the indexer method I<mode>. This method
is called internally by insert(), update() and delete().

=cut

sub write_index {
    my $self = shift;
    my $mode = shift || 'insert';
    $self->indexer->$mode($self);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-dbx-object-indexed@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

