package Silki::Markdent::Handler::HTMLGenerator;
{
  $Silki::Markdent::Handler::HTMLGenerator::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use HTML::Entities qw( encode_entities );
use Markdent::Types qw( HeaderLevel );
use Silki::I18N qw( loc );
use Silki::Schema::Page;
use Silki::Schema::Permission;
use Silki::Types qw( Bool HashRef Int ScalarRef Str );
use Text::TOC::HTML;

use Moose;
use MooseX::Params::Validate qw( validated_list validated_hash );
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

extends 'Markdent::Handler::HTMLStream::Fragment';

with 'Silki::Markdent::Role::WikiLinkResolver';

has _user => (
    is       => 'ro',
    isa      => 'Silki::Schema::User',
    required => 1,
    init_arg => 'user',
);

has _cached_perms => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { {} },
    init_arg => undef,
);

has _include_toc => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'include_toc',
    default  => 0,
);

has _nofollow_external => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'nofollow_external',
    default  => 1,
);

has _for_editor => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'for_editor',
    default  => 0,
);

has '+_output' => (
    builder => '_build_output',
);

has _buffer => (
    is       => 'ro',
    isa      => ScalarRef,
    init_arg => undef,
    lazy     => 1,
    default  => sub { my $buf = q{}; \$buf },
);

has _header_count => (
    traits   => ['Counter'],
    is       => 'ro',
    isa      => Int,
    init_arg => undef,
    default  => 0,
    handles  => { _inc_header_count => 'inc' },
);

sub _build_output {
    my $self = shift;

    open my $fh, '>:utf8', $self->_buffer();

    return $fh;
}

after start_header => sub {
    my $self = shift;
    my ($level) = validated_list(
        \@_,
        level => { isa => HeaderLevel },
    );

    return unless $level <= 4;

    $self->_inc_header_count();
};

sub placeholder {
    my $self = shift;
    my ($id) = validated_list(
        \@_,
        id => { isa => Str },
    );

    $self->_stream()->comment( 'Placeholder: ' . $id );
}

sub _replace_placeholder {
    my $self      = shift;
    my $id        = shift;
    my $link_data = shift;

    my $snippet = $self->_link_to_page($link_data);

    ${ $self->_buffer() } =~ s/<!--\s*Placeholder: \Q$id\E\s*-->\n/$snippet/g;

    return;
}

sub file_link {
    my $self = shift;
    my ( $link, $display_text ) = validated_list(
        \@_,
        link_text    => { isa => Str },
        display_text => { isa => Str, optional => 1 },
    );

    my $link_data = $self->_resolve_file_link( $link, $display_text );

    $self->_link_to_file($link_data);

    return;
}

sub image_link {
    my $self = shift;
    my $link = validated_list(
        \@_,
        link_text => { isa => Str },
    );

    my $link_data = $self->_resolve_file_link($link);

    if (   $link_data->{file}
        && $link_data->{file}->is_browser_displayable_image() ) {

        $self->_link_to_file( $link_data, undef, 'as image' );
    }
    else {
        $self->_link_to_file($link_data);
    }

    return;
}

sub _link_to_file {
    my $self         = shift;
    my $p            = shift;
    my $display_text = shift;
    my $as_image     = shift;

    my $file = $p->{file};

    unless ( defined $file ) {
        $self->_stream()->text( $p->{text} );
        return;
    }

    unless ( $self->_check_for_read_permission( $file->wiki() ) ) {
        $self->_stream()->text( loc('(inaccessible file)') );
        return;
    }

    my $file_uri = $file->uri();

    my $title
        = $file->is_displayable_in_browser()
        ? loc('View this file')
        : loc('Download this file');

    $self->_stream()->tag(
        a => (
            href  => $file_uri,
            title => $title,
        )
    );

    if ($as_image) {
        $self->_stream->tag(
            img => (
                src => $file->uri( view => 'small' ),
                alt => $file->filename(),
            ),
            '/',    # XXX - should fix HTML::Stream to not need this
        );
    }
    else {
        $self->_stream()->text( $p->{text} );
    }

    $self->_stream()->tag('_a');
}

sub auto_link {
    my $self = shift;
    my ($uri) = validated_list(
        \@_,
        uri => { isa => Str, optional => 1 },
    );

    my %tag_attr = ( href => $uri );
    $tag_attr{rel} = 'nofollow'
        if $self->_nofollow_external();

    $self->_stream()->tag( 'a', %tag_attr );
    $self->_stream()->text($uri);
    $self->_stream()->tag('_a');
}

sub start_link {
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        uri            => { isa => Str },
        title          => { isa => Str, optional => 1 },
        id             => { isa => Str, optional => 1 },
        is_implicit_id => { isa => Bool, optional => 1 },
    );

    delete @p{ grep { !defined $p{$_} } keys %p };

    my %tag_attr = ( href => $p{uri} );
    $tag_attr{title} = $p{title}
        if exists $p{title};
    $tag_attr{rel} = 'nofollow'
        if $self->_nofollow_external();

    $self->_stream()->tag( 'a', %tag_attr );
}

sub _link_to_page {
    my $self      = shift;
    my $link_data = shift;

    unless ( $link_data->{page} || $link_data->{wiki} ) {
        return encode_entities( $link_data->{text} );
    }

    my $page = $link_data->{page};

    my $wiki = $link_data->{wiki} || $page->wiki();

    unless ( $self->_check_for_read_permission($wiki) ) {
        return encode_entities( loc('(inaccessible page)') );
    }

    if ( $self->_for_editor() ) {
        $page ||= Silki::Schema::Page->new(
            page_id => 0,
            wiki_id => $link_data->{wiki}->wiki_id(),
            title   => $link_data->{title},
            uri_path =>
                Silki::Schema::Page->TitleToURIPath( $link_data->{title} ),
            _from_query => 1,
        );
    }

    my $uri
        = $page
        ? $page->uri()
        : $link_data->{wiki}->uri(
        view  => 'new_page_form',
        query => { title => $link_data->{title} }
        );

    my $class = $page ? 'existing-page' : 'new-page';

    my $title
        = $page
        ? loc( 'Read %1', $page->title() )
        : loc('This page has not yet been created');

    return sprintf(
        qq{<a href="%s" class="%s" title="%s">%s</a>},
        map { encode_entities($_) } $uri, $class, $title, $link_data->{text}
    );
}

sub _check_for_read_permission {
    my $self = shift;
    my $wiki = shift;

    my $cached_perms = $self->_cached_perms;

    if ( exists $cached_perms->{ $wiki->wiki_id() } ) {
        return $cached_perms->{ $wiki->wiki_id() };
    }

    return $cached_perms->{ $wiki->wiki_id() }
        = $self->_user()->has_permission_in_wiki(
        wiki       => $wiki,
        permission => Silki::Schema::Permission->Read(),
        );
}

sub final_html_output {
    my $self = shift;

    my $html = ${ $self->_buffer() };

    utf8::decode($html);

    return $html unless $self->_header_count() > 2;

    my $toc = Text::TOC::HTML->new(
        filter => sub { $_[0]->tagName() =~ /^h[1-4]$/i } );

    my $fake_file = $self . q{};
    $toc->add_file( file => $fake_file, content => $html );

    return
          q{<div id="table-of-contents">} . "\n"
        . $toc->html_for_toc() . "\n"
        . '</div>' . "\n"
        . $toc->html_for_document($fake_file);
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A subclass of Markdent::Handler::HTMLStream which handles Silki-specific markup

__END__
=pod

=head1 NAME

Silki::Markdent::Handler::HTMLGenerator - A subclass of Markdent::Handler::HTMLStream which handles Silki-specific markup

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

