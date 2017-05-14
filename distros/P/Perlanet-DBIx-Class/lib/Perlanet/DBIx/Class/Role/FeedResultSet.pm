package Perlanet::DBIx::Class::Role::FeedResultSet;
# ABSTRACT: Role for the ResultSet which contains a list of feeds to aggregate

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Method::Signatures::Simple;
use namespace::autoclean;

method fetch_feeds {
    return [ map { $self->munge_feed_from_db($_) } $self->all ];
}

method munge_feed_from_db ($feed)
{
    return Perlanet::Feed->new(
        id      => $feed->id,
        url     => $feed->url  || $feed->link,
        website => $feed->link || $feed->url,
        title   => $feed->title,
        author  => $feed->owner,
    )
}

1;

__END__
=pod

=head1 NAME

Perlanet::DBIx::Class::Role::FeedResultSet - Role for the ResultSet which contains a list of feeds to aggregate

=head1 VERSION

version 0.02

=head1 AUTHOR

  Oliver Charles <oliver@ocharles.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

