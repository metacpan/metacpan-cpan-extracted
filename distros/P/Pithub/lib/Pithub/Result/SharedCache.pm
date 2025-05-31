package Pithub::Result::SharedCache;
our $AUTHORITY = 'cpan:PLU';

use Moo::Role;

our $VERSION = '0.01043';

# ABSTRACT: A role to share the LRU cache with all Pithub objects

use CHI ();

my $store = {};

my $Shared_Cache = CHI->new(
    datastore => $store,
    driver    => 'RawMemory',
    max_size  => 200,
    size      => 200,
);


sub shared_cache {
    return $Shared_Cache;
}


sub set_shared_cache {
    my ( $self, $cache ) = @_;

    $Shared_Cache = $cache;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Result::SharedCache - A role to share the LRU cache with all Pithub objects

=head1 VERSION

version 0.01043

=head1 DESCRIPTION

A role to share the least recently used cache with all Pithub objects.

=head1 METHODS

=head2 shared_cache

Returns the L<CHI> object shared by all Pithub objects.

=head2 set_shared_cache

Sets the CHI object shared by all Pithub objects.

This should only be necessary for testing or to change the
size of the cache.

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
