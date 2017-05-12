package PICA::Modification::Queue;
{
  $PICA::Modification::Queue::VERSION = '0.16';
}
#ABSTRACT: Queued list of modification requests of PICA+ records

use strict;
use warnings;
use v5.10;

use Carp;
use Scalar::Util qw(reftype);

sub new {
    my $class = shift;
    my $name  = shift || 'hash';
    
    if ('HASH' ~~ reftype($name)) {
        my $args = $name;
        $name = delete $name->{type};
        return $class->new( $name, %$args );
    }

    $class = $class . '::' . ucfirst($name);

    my $file = $class;
    $file =~ s!::!/!g;
    require "$file.pm"; ## no critic

    $class->new( @_ );
}

1;



__END__
=pod

=head1 NAME

PICA::Modification::Queue - Queued list of modification requests of PICA+ records

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    # create a PICA::Modification::Queue::Hash
    my $q = PICA::Modification::Queue->new('Hash'); 

    # create a different kind of queue (all equivalent)
    $q = PICA::Modification::Queue->new('foo', bar => 'doz'); 
    $q = PICA::Modification::Queue->new({type => 'foo', bar => 'doz' }); 
    $q = PICA::Modification::Queue::Foo->new( bar => 'doz' ); 

    # operations on queues:
    
    my $id  = $q->insert( $modification );
    my $mod = $q->get( $id );
    $id     = $q->update( $id => $modification );
    $id     = $q->delete( $id );

    my @mods = $q->list( $key => $value ... );

=head1 DESCRIPTION

PICA::Modification::Queue implements a collection of modifications
(L<PICA::Modification>) or requests (L<PICA::Modification::Request>) on PICA+
records together with the CRUDL operations get, insert, update, delete, and
list. A queue may support insertion of modifications which then are stored as
modification requests.

The default implementation is a in-memory (non-persistent) hash
(L<PICA::Modification::Queue::Hash>). Additional types of queues can be
implemented in the C<PICA::Modification::Queue::> module namespace.

To test additional implementations of queues, the unit testing package 
L<PICA::Modification::TestQueue> should be used.

=head1 METHODS

=head2 new ( $name [, %options ] )

Creates a new queue. Options are passed to the queue's constructor.

=head2 request ( $modification )

Must return the id only on success.

=head2 get ( $id )

Returns a stored modification or undef.

=head2 update ( $id => $modification_or_modification_request )

Must return the id only on success.

=head2 delete ( $id )

Must return the id only on success.

=head2 list ( %parameters )

List all or a selection of queued modifications. Parameters can be used for
selection.  Special parameters are: C<page>, C<limit>, and C<sort>.

=encoding utf-8

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

