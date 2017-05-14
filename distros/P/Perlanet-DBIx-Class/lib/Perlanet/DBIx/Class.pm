package Perlanet::DBIx::Class;
# ABSTRACT: Aggregate posts in a database using DBIx::Class

use strict;
use warnings FATAL => 'all';

use Moose;
use Method::Signatures::Simple;
use namespace::autoclean;

use Carp;
use Devel::Dwarn;
use DateTime;
use Perlanet::DBIx::Class::Types qw( ResultSet );
use TryCatch;

extends 'Perlanet';

has 'post_resultset' => (
    does     => 'Perlanet::DBIx::Class::Role::PostResultSet',
    is       => 'ro',
    required => 1,
);

has 'feed_resultset' => (
    does     => 'Perlanet::DBIx::Class::Role::FeedResultSet',
    is       => 'ro',
    required => 1,
);

has '+feeds' => (
    lazy    => 1,
    default => sub  {
        my $self = shift;
        $self->feed_resultset->fetch_feeds;
    }
);

around 'select_entries' => sub {
    my $orig = shift;
    my ($self, @feeds) = @_;

    return grep {
        ! $self->post_resultset->has_post($_)
    } $self->$orig(@feeds);
};

override 'render' => sub {
    my ($self, $feed) = @_;

    foreach my $post (@{ $feed->entries }) {
        try {
            # Do that whole insert thing...
            $self->insert_post($post);
        }
        catch {
            Carp::cluck("ERROR: $_\n");
            Carp::cluck("ERROR: Post is:\n" . Dumper($post) . "\n");
            Carp::cluck("ERROR: Link URL is '" . $post->_entry->link . "'\n");
        };
    }
};

method insert_post ($post)
{
    $self->post_resultset->create_from_perlanet($post);
}

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

Perlanet::DBIx::Class - Aggregate posts in a database using DBIx::Class

=head1 VERSION

version 0.02

=head1 AUTHOR

  Oliver Charles <oliver@ocharles.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

