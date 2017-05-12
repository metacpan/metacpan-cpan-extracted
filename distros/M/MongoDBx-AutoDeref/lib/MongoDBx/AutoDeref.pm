package MongoDBx::AutoDeref;
BEGIN {
  $MongoDBx::AutoDeref::VERSION = '1.110560';
}

#ABSTRACT: Automagically dereference MongoDB DBRefs lazily

use warnings;
use strict;
use feature qw/state/;
use Class::Load('load_class');
use MongoDBx::AutoDeref::LookMeUp;



sub import
{
    my ($class) = @_;

    load_class('MongoDB');
    load_class('MongoDB::Cursor');
    load_class('MongoDB::Collection');
    my $cur = 'MongoDB::Cursor'->meta();
    $cur->make_mutable();
    $cur->add_around_method_modifier
    (
        'next',
        sub
        {
            my ($orig, $self, @args) = @_;
            state $lookmeup = MongoDBx::AutoDeref::LookMeUp->new(
                mongo_connection => $self->_connection,
                sieve_type => 'output',
            );

            my $ret = $self->$orig(@args);
            if(defined($ret))
            {
                $lookmeup->sieve($ret);
            }

            return $ret;
        }
    );
    $cur->make_immutable(inline_destructor => 0);

    my $col = 'MongoDB::Collection'->meta();
    $col->make_mutable();
    $col->add_around_method_modifier
    (
        'batch_insert',
        sub
        {
            my ($orig, $self, $object, $options) = @_;
            state $lookmeup = MongoDBx::AutoDeref::LookMeUp->new(
                mongo_connection => $self->_database->_connection,
                sieve_type => 'input',
            );

            $lookmeup->sieve($object);
            return $self->$orig($object, $options);
        }
    );
    $col->add_around_method_modifier
    (
        'update',
        sub
        {
            my ($orig, $self, $query, $object, $options) = @_;
            state $lookmeup = MongoDBx::AutoDeref::LookMeUp->new(
                mongo_connection => $self->_database->_connection,
                sieve_type => 'input',
            );

            $lookmeup->sieve($object);
            return $self->$orig($query, $object, $options);
        }
    );

    $col->make_immutable(inline_destructor => 0);
}

1;



=pod

=head1 NAME

MongoDBx::AutoDeref - Automagically dereference MongoDB DBRefs lazily

=head1 VERSION

version 1.110560

=head1 SYNOPSIS

    use MongoDB; #or omit this
    use MongoDBx::AutoDeref;

    my $connection = MongoDB::Connection->new();
    my $database = $connection->get_database('foo');
    my $collection = $database->get_collection('bar');

    my $doc1 = { baz => 'flarg' };
    my $doc2 = { yarp => 'floop' };

    my $id = $collection->insert($doc1);
    $doc2->{dbref} = {'$db' => 'foo', '$ref' => 'bar', '$id' => $id };
    my $id2 = $collection->insert($doc2);

    my $fetched_doc2 = $collection->find_one({_id => $id2 });
    my $fetched_doc1 = $fetched_doc2->{dbref}->fetch;
    
    # $fetched_doc1 == $doc1

=head1 DESCRIPTION

Using Mongo drivers from other languages and miss driver support for expanding
DBRefs? Then this module is for you. Simple 'use' it to have this ability added
to the core MongoDB driver.

Please read more about DBRefs:
http://www.mongodb.org/display/DOCS/Database+References

If more information is necessary on the guts, please see
L<MongoDBx::AutoDeref::LookMeUp>

=head1 CLASS_METHODS

=head2 import

Upon use (or require+import), this class method will load MongoDB (if it isn't
already loaded), and alter the metaclasses for MongoDB::Cursor and
MongoDB::Collection. Internally, everything is cursor driven so the result
returned is ultimately from the L<MongoDB::Cursor/next> method. So this method
is advised to apply the L<MongoDBx::AutoDeref::LookMeUp> sieve to the returned
result which replaces all DBRefs with L<MongoDBx::AutoDeref::DBRef> objects.
When doing updates and inserts back using MongoDB::Collection, the inflated
objects will be deflated back into DBRefs.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

