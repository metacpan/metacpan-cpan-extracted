package MooseX::Iterator;

our $VERSION   = '0.11';
our $AUTHORITY = 'cpan:RLB';

use MooseX::Iterator::Array;
use MooseX::Iterator::Hash;
use MooseX::Iterator::Meta::Iterable;

1;

__END__

=pod

=head1 NAME

MooseX::Iterator - Iterate over collections

=head1 SYNOPSIS

Access the Iterator directly:

    use Moose;
    use MooseX::Iterator;

    my $iter = MooseX::Iterator::Array->new( collection => [ 1, 2, 3, 4, 5, 6 ] );

    my $count = 1;
    while ( $iter->has_next ) {
        print $iter->next;
    }

Or use the meta class:

    package TestIterator;

    use Moose;
    use MooseX::Iterator;

    has collection => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { { one => '1', two => '2', three => '3' } },
    );

    has iter => (
        metaclass    => 'Iterable',
        iterate_over => 'collection',
    );

    no Moose;

    package main;
    use Data::Dumper;

    my $test = TestIterator->new;

    my $iter = $test->iter;

    while ( $iter->has_next ) {
        my $next = $iter->next;
        print $next->{'key'}   . "\n";
        print $next->{'value'} . "\n";
    }

=head1 DESCRIPTION

This is an attempt to add smalltalk-like streams to Moose. It currently works with ArrayRefs and HashRefs.


=over

=item next

The next method provides the next item in the colletion.

  For arrays it returns the element of the array
  
  For hashs it returns a pair as a hashref with the keys: key and value

=item has_next

The has_next method is a boolean method that is true if there is another item in the colletion after the current item. and falue if there isn't. 

=item peek

The peek method returns the next item without moving the state of the iterator forward. It returns undef if it is at the end of the collection.

=item reset

Resets the cursor, so you can iterate through the elements again.

=back

=item Subclassing MooseX::Iterator::Meta::Iterable

When subclassing MooseX::Iterator::Meta::Iterable for your own iterators override MooseX::Iterator::Meta::Iterable::_calculate_iterator_class_for_type to
returns the name of the class that iterates over your new collection type. The class must implement the MooseX::Iterator::Role role.

=back

=head1 AUTHOR

Robert Boone E<lt>rlb@cpan.orgE<gt>

And thank you to Steven Little (steven) and Matt Trout (mst) for the help and advice they gave.

=head1 CONTRIBUTORS

Johannes Plunien

=head1 Code Repository

 Git - http://github.com/rlb3/moosex-iterator/tree/master

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
