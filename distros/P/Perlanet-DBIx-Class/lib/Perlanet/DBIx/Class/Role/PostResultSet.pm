package Perlanet::DBIx::Class::Role::PostResultSet;
# ABSTRACT: Role for the ResultSet which contains a list of saved posts

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Method::Signatures::Simple;
use namespace::autoclean;

method create_from_perlanet ($post)
{
    $self->create($self->munge_from_perlanet($post));
}

method munge_from_perlanet ($post)
{
    return {
        feed_id   => $post->feed->id,
        author    => $post->_entry->author || $post->feed->title,
        url       => $post->_entry->link,
        title     => $post->_entry->title,
        posted_on => $post->_entry->issued || DateTime->now,
        summary   => $post->_entry->summary->body ||
                     $post->_entry->content->body,
        body      => $post->_entry->content->body,
    }
}

method has_post ($post)
{
    return $self->search( { url => $post->link } )->count > 0;
}

1;

__END__
=pod

=head1 NAME

Perlanet::DBIx::Class::Role::PostResultSet - Role for the ResultSet which contains a list of saved posts

=head1 VERSION

version 0.02

=head1 AUTHOR

  Oliver Charles <oliver@ocharles.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

