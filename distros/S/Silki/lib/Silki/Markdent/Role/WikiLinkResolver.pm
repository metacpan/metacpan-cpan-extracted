package Silki::Markdent::Role::WikiLinkResolver;
{
  $Silki::Markdent::Role::WikiLinkResolver::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Digest::SHA qw( sha1_hex );
use List::AllUtils qw( all );
use Silki::I18N qw( loc );
use Silki::Markdent::Event::Placeholder;
use Silki::Types qw( HashRef Str );

use Moose::Role;
use MooseX::Params::Validate qw( validated_list );

requires qw( _replace_placeholder );

has _wiki => (
    is       => 'ro',
    isa      => 'Silki::Schema::Wiki',
    required => 1,
    init_arg => 'wiki',
);

has _page => (
    is       => 'ro',
    isa      => 'Silki::Schema::Page',
    init_arg => 'page',
);

has _cached_wikis => (
    is       => 'ro',
    isa      => HashRef ['Silki::Schema::Wiki'],
    default  => sub { {} },
    init_arg => undef,
);

has _page_links => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => HashRef [HashRef],
    init_arg => undef,
    default  => sub { {} },
    handles  => {
        _save_page_link => 'set',
    },
);

around handle_event => sub {
    my $orig  = shift;
    my $self  = shift;
    my $event = shift;

    if ( $event->isa('Silki::Markdent::Event::WikiLink') ) {
        $self->wiki_link( $event->kv_pairs_for_attributes() );
    }
    elsif ( $event->isa('Markdent::Event::EndDocument') ) {
        $self->$orig($event);
        $self->_replace_all_placeholders();
    }
    elsif ($orig) {
        $self->$orig($event);
    }
};

sub wiki_link {
    my $self = shift;
    my ( $link_text, $display_text ) = validated_list(
        \@_,
        link_text    => { isa => Str },
        display_text => { isa => Str, optional => 1 },
    );

    my ( $wiki, $page_title )
        = $self->_wiki_and_page_title_from_link_text($link_text);

    my $id = sha1_hex( ( $wiki ? $wiki->wiki_id() : -1 ), lc $page_title );

    $self->_save_page_link(
        $id => {
            wiki         => $wiki,
            page_title   => $page_title,
            display_text => $display_text,
            link_text    => $link_text,
        }
    );

    $self->handle_event(
        Silki::Markdent::Event::Placeholder->new( id => $id ) );

    return;
}

sub _wiki_and_page_title_from_link_text {
    my $self      = shift;
    my $link_text = shift;

    my $wiki       = $self->_wiki();
    my $page_title = $link_text;

    if ( $link_text =~ m{^([^/]+)/([^/]+)$} ) {
        $wiki       = $self->_wiki_from_string($1);
        $page_title = $2;
    }

    $page_title =~ s/^\s+|\s+$//g;

    return ( $wiki, $page_title );
}

sub _wiki_from_string {
    my $self   = shift;
    my $string = shift;

    my $wiki_cache = $self->_cached_wikis();

    $string =~ s/^\s+|\s+$//g;

    if ( exists $wiki_cache->{$string} ) {
        return $wiki_cache->{$string};
    }
    else {
        my $wiki = Silki::Schema::Wiki->new( title => $string )
            || Silki::Schema::Wiki->new( short_name => $string );

        if ($wiki) {
            $wiki_cache->{ $wiki->title() }
                = $wiki_cache->{ $wiki->short_name() } = $wiki;
        }
        else {
            $wiki_cache->{$string} = undef;
        }

        return $wiki;
    }
}

sub _replace_all_placeholders {
    my $self = shift;
    my $html = shift;

    $self->_replace_bad_wiki_links();

    $self->_replace_good_wiki_links();

    $self->_replace_nonexistent_page_links();

    return;
}

sub _replace_bad_wiki_links {
    my $self = shift;

    my $links = $self->_page_links();

    for my $id (
        grep { !$links->{$_}{wiki} }
        keys %{$links}
        ) {

        my $link = delete $links->{$id};

        $self->_replace_placeholder(
            $id => {
                text => loc(
                    '(link to a non-existent wiki in a page link - %1)',
                    $link->{link_text}
                )
            },
        );
    }
}

sub _replace_good_wiki_links {
    my $self = shift;

    my $links = $self->_page_links();


    my %titles;
    for my $link ( values %{$links} ) {
        push @{ $titles{ $link->{wiki}->wiki_id() } }, $link->{page_title};
    }

    return unless keys %titles;

    my $pages = Silki::Schema::Page->PagesByWikiAndTitle( \%titles );

    while ( my $page = $pages->next() ) {
        my $id = sha1_hex( $page->wiki_id(), lc $page->title() );

        my $link = delete $links->{$id};

        $link->{display_text} //= $self->_display_text_for_page(
            $link->{wiki},
            $page->title(),
        );

        $self->_replace_placeholder(
            $id => {
                page  => $page,
                title => $page->title(),
                text  => $link->{display_text},
                wiki  => $link->{wiki},
            }
        );
    }
}

sub _replace_nonexistent_page_links {
    my $self = shift;

    my $links = $self->_page_links();

    for my $id ( keys %{$links} ) {

        my $text;

        if ( $links->{$id}{display_text} ) {
            $text = $links->{$id}{display_text};
        }
        else {
            $text = $links->{$id}{page_title};

            my $wiki = $links->{$id}{wiki};

            $text .= ' (' . $wiki->title() . ')'
                unless $wiki->wiki_id() == $self->_wiki()->wiki_id();
        }

        $self->_replace_placeholder(
            $id => {
                page  => undef,
                title => $links->{$id}{page_title},
                text  => $text,
                wiki  => $links->{$id}{wiki},
            }
        );
    }
}

sub _display_text_for_page {
    my $self       = shift;
    my $wiki       = shift;
    my $page_title = shift;

    my $text = $page_title;

    $text .= ' (' . $wiki->title() . ')'
        unless $wiki->wiki_id() == $self->_wiki()->wiki_id();

    return $text;
}

sub _resolve_file_link {
    my $self         = shift;
    my $link_text    = shift;
    my $display_text = shift;

    my $wiki = $self->_wiki();

    return unless $link_text =~ m{^(?:([^/]+)/)?(?:([^/]+)/)?([^/]+)$};

    my $filename = $3;

    my $wiki_name;
    my $page_name;

    if ( all {defined} $1, $2, $3 ) {
        $wiki_name = $1;
        $page_name = $2;
    }
    elsif ( all {defined} $1, $3 ) {
        $page_name = $1;
    }

    if ( defined $wiki_name ) {
        $wiki = Silki::Schema::Wiki->new( title => $wiki_name )
            || Silki::Schema::Wiki->new( short_name => $wiki_name );

        return {
            text => loc(
                '(link to a non-existent wiki in a file link - %1)',
                $link_text
            ),
            }
            unless $wiki;
    }

    my $page = $self->_page();

    if ( defined $page_name ) {
        $page = Silki::Schema::Page->new(
            title   => $page_name,
            wiki_id => $wiki->wiki_id(),
        );

        return {
            text => loc(
                '(link to a non-existent page in a file link - %1)',
                $link_text
            ),
            }
            unless $page;
    }

    my $file = Silki::Schema::File->new(
        page_id  => $page->page_id(),
        filename => $filename,
    );

    unless ( defined $display_text ) {
        $display_text = $self->_link_text_for_file(
            $wiki,
            $file,
            $link_text,
        );
    }

    return {
        file => $file,
        text => $display_text,
        wiki => $wiki,
    };
}

sub _link_text_for_file {
    my $self      = shift;
    my $wiki      = shift;
    my $file      = shift;
    my $link_text = shift;

    return loc( '(link to a non-existent file - %1)', $link_text )
        unless $file;

    my $text = $file->filename();

    $text .= ' (' . $wiki->title() . ')'
        unless $wiki->wiki_id() == $self->_wiki()->wiki_id();

    return $text;
}

# These classes may in turn load other classes which use this role, so they
# need to be loaded after the role is defined.
require Silki::Schema::File;
require Silki::Schema::Page;
require Silki::Schema::Wiki;

1;

# ABSTRACT: A role which resolves page/file/image links from wikitext

__END__
=pod

=head1 NAME

Silki::Markdent::Role::WikiLinkResolver - A role which resolves page/file/image links from wikitext

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

