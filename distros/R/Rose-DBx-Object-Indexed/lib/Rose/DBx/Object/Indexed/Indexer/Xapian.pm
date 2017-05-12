package Rose::DBx::Object::Indexed::Indexer::Xapian;

use warnings;
use strict;
use base qw( Rose::DBx::Object::Indexed::Indexer );
use Carp;
use Class::C3;

our $VERSION = '0.009';

=head1 NAME

Rose::DBx::Object::Indexed::Indexer::Xapian - Xapian indexer

=head1 SYNOPSIS

 # from a Rose::DBx::Object::Indexed object
 my $thing = MyThing->new( id => 123 )->load;
 $thing->write_index('insert');
 
 # standalone
 my $indexer = MyThing->init_indexer;
 while (my $thing = $thing_iterator->next) {
    $indexer->insert($thing);
 }

=cut

=head2 init_indexer_class

Returns 'SWISH::Prog::Xapian::Indexer'.

=cut

sub init_indexer_class {'SWISH::Prog::Xapian::Indexer'}

sub __seed_index {
    my $self = shift;

    # no op for now

}

=head2 make_doc( I<rdbo_obj> )

Returns a SWISH::Prog::Doc instance for I<rdbo_obj>.

=cut

sub make_doc {
    my $self = shift;
    my $obj  = shift or croak "RDBO object required";
    my $xml  = $self->to_xml( $self->serialize_object($obj), $obj );
    return SWISH::Prog::Doc->new(
        content => $xml,
        url     => $self->get_primary_key($obj),
        modtime => time(),
        parser  => 'XML*',
        type    => 'application/x-rdbo-indexed',    # TODO ??
        version => 3,                               # SWISH::3 headers
    );
}

=head2 run( I<args> )

Calls the superclass method and then finish() on the swish_indexer().
Note that the explicit call to finish() means that a new indexer
is spawned for each insert(), update() or delete(). If you are trying
to do bulk index updates, avoid this kind of overhead and do not
call run(). Instead, do something like:

 my $swish_indexer = $object->swish_indexer;
 my $indexer       = $object->indexer;
 
 foreach my $obj (@list_of_objects) {
    my $doc = $indexer->make_doc($obj);
    $swish_indexer->process($doc);
 }
 
 $swish_indexer->finish(); # must do this to commit the index transaction.

=cut

sub run {
    my $self = shift;
    $self->next::method(@_);

    # note that this invalidates the indexer,
    # so explicitly destroy it to avoid race conditions.
    $self->swish_indexer->finish();
    $self->swish_indexer(undef);
}

=head2 insert( I<rdbo_obj> )

Calls run() with the appropriate arguments.

=cut

sub insert {
    my $self = shift;
    my $obj = shift or croak "RDBO object required";
    $self->run($obj);    # no action. the default is to 'Index' (add)
}

=head2 update( I<rdbo_obj> )

Calls run() with the appropriate arguments.

=cut

sub update {
    my $self = shift;
    my $obj = shift or croak "RDBO object required";
    $self->run( $obj, 'Update' );
}

=head2 delete( I<rdbo_obj> )

Calls run() with the appropriate arguments.

=cut

sub delete {
    my $self = shift;
    my $obj = shift or croak "RDBO object required";
    $self->run( $obj, 'Remove' );
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

=head1 COPYRIGHT & LICENSE

Copyright 2010 by Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut



