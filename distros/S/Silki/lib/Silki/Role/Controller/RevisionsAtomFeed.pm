package Silki::Role::Controller::RevisionsAtomFeed;
{
  $Silki::Role::Controller::RevisionsAtomFeed::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::I18N qw( loc );

use Moose::Role;

sub _output_atom_feed_for_revisions {
    my $self       = shift;
    my $c          = shift;
    my $revisions  = shift;
    my $feed_title = shift;
    my $alt_uri    = shift;
    my $self_uri   = shift;
    my $page       = shift;

    my @entries;

    my $updated;
    while ( my ( $page, $revision )
        = $page ? ( $page, $revisions->next() ) : $revisions->next() ) {
        last unless $revision;

        $updated ||= $revision->creation_datetime();

        my $entry_title = $page->title() . ' ('
            . loc( 'revision %1', $revision->revision_number() ) . ')';

        my $entry_uri = $revision->uri( with_host => 1 );

        my $content = $revision->content_as_html( user => $c->user() );

        push @entries,
            [
            title   => $entry_title,
            link    => $entry_uri,
            id      => $entry_uri,
            author  => $revision->user()->best_name(),
            updated => DateTime::Format::W3CDTF->format_datetime(
                $revision->creation_datetime()->clone()->set_time_zone('UTC')
            ),
            content => { type => 'html', content => $content },
            ];
    }

    my $feed = XML::Atom::SimpleFeed->new(
        title => $feed_title,
        link  => $alt_uri,
        id    => $alt_uri,
        link  => {
            rel  => 'self',
            href => $self_uri,
        },
        updated => DateTime::Format::W3CDTF->format_datetime(
            $updated->clone()->set_time_zone('UTC')
        ),
    );

    $feed->add_entry( @{$_} ) for @entries;

    $c->response()->content_type('application/atom+xml');

    my $xml = $feed->as_string();
    $c->response()->content_length( length $xml );

    $c->response()->body($xml);

    $c->response()->status(200);

    $c->detach();
}

1;

# ABSTRACT: Generates an atom feed from a set of revisions

__END__
=pod

=head1 NAME

Silki::Role::Controller::RevisionsAtomFeed - Generates an atom feed from a set of revisions

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

