package Silki::Controller::Page;
{
  $Silki::Controller::Page::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use File::MimeInfo qw( mimetype );
use List::AllUtils qw( all );
use Silki::Config;
use Silki::I18N qw( loc );
use Silki::Formatter::HTMLToWiki;
use Silki::Formatter::WikiToHTML;
use Silki::Schema::Page;
use Silki::Schema::PageRevision;
use Silki::Util qw( string_is_empty );

use Moose;

BEGIN { extends 'Silki::Controller::Base' }

with qw(
    Silki::Role::Controller::PagePreview
    Silki::Role::Controller::Pager
    Silki::Role::Controller::RevisionsAtomFeed
    Silki::Role::Controller::WikitextHandler
);

sub _set_page : Chained('/wiki/_set_wiki') : PathPart('page') : CaptureArgs(1) {
    my $self      = shift;
    my $c         = shift;

    # Catalyst URI-unescapes the path pieces when passing them to controller
    # methods, which is really annoying. Fortunately, the request still has
    # the original form.
    my $page_path = ( split /\//, $c->request()->path_info() )[3];

    if ( Silki::Config->instance()->mod_rewrite_hack() ) {
        $page_path =~ s/_/ /g;
        $page_path = Silki::Schema::Page->TitleToURIPath($page_path);
    }

    my $wiki = $c->stash()->{wiki};

    my $page = Silki::Schema::Page->new(
        uri_path => $page_path,
        wiki_id  => $wiki->wiki_id(),
    );

    $c->redirect_and_detach( $wiki->uri( with_host => 1 ) )
        unless $page;

    if ( $page->title() eq $wiki->front_page_title() ) {
        $c->tab_by_id('front-page')->set_is_selected(1);
    }
    else {
        $c->add_tab(
            {
                uri         => $page->uri(),
                label       => $page->title(),
                tooltip     => loc('View this page'),
                is_selected => 1,
            }
        );
    }

    $c->stash()->{page} = $page;
}

sub page : Chained('_set_page') : PathPart('') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub page_GET_html {
    my $self = shift;
    my $c    = shift;

    my $page     = $c->stash()->{page};
    my $revision = $page->most_recent_revision();

    $page->record_view( $c->user() );

    $c->stash()->{revision}            = $revision;
    $c->stash()->{is_current_revision} = 1;

    $c->stash()->{html} = $revision->content_as_html(
        user        => $c->user(),
        include_toc => 1,
    );

    $c->stash()->{template} = '/page/view';
}

sub page_DELETE {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    $self->_require_permission_for_wiki( $c, $wiki );

    my $page = $c->stash()->{page};

    my $msg = loc( 'Deleted the page %1', $page->title() );

    $page->delete( user => $c->user() );

    $c->session_object()->add_message($msg);

    $c->redirect_and_detach( $wiki->uri( with_host => 1 ) );
}

sub edit_form : Chained('_set_page') : PathPart('edit_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Edit' );

    $c->stash()->{preview}
        = $c->stash()->{page}->most_recent_revision()->content_as_html(
        user        => $c->user(),
        include_toc => 1,
        );

    $c->stash()->{template} = '/page/edit-form';
}

sub rename_form : Chained('_set_page') : PathPart('rename_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Edit' );

    my $page = $c->stash()->{page};

    $c->stash()->{template} = '/page/rename-form';
}

sub page_PUT {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki} );

    my $page = $c->stash()->{page};

    my $params = $c->request()->params();
    my %p
        = map { $_ => $params->{$_} }
        grep { !string_is_empty( $params->{$_} ) }
        qw( is_restoration_of_revision_number comment );

    eval {
        my $wikitext = $self->_wikitext_from_form( $c, $page->wiki() );

        $page->add_revision(
            content => $wikitext,
            user_id => $c->user()->user_id(),
            %p,
        );
    };

    if ( my $e = $@ ) {
        $c->redirect_with_error(
            error     => $e,
            uri       => $page->uri( view => 'edit_form' ),
            form_data => $c->request()->params(),
        );
    }

    $c->redirect_and_detach( $page->uri() );
}

sub page_title : Chained('_set_page') : PathPart('title') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub page_title_PUT {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki} );

    my $page = $c->stash()->{page};

    eval { $page->rename( $c->request()->params()->{title} ) };

    if ( my $e = $@ ) {
        $c->redirect_with_error(
            error     => $e,
            uri       => $page->uri( view => 'rename_form' ),
            form_data => $c->request()->params(),
        );
    }

    $c->redirect_and_detach( $page->uri() );
}

sub page_html : Chained('_set_page') : PathPart('html') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_send_preview_html($c);
}

sub _set_revision : Chained('_set_page') : PathPart('revision') : CaptureArgs(1) {
    my $self            = shift;
    my $c               = shift;
    my $revision_number = shift;

    my $page = $c->stash()->{page};

    my $revision;
    if ( $revision_number =~ /^\d+$/ ) {
        $revision = Silki::Schema::PageRevision->new(
            page_id         => $page->page_id(),
            revision_number => $revision_number,
        );
    }

    unless ($revision) {
        $c->redirect_and_detach( $page->uri( with_host => 1 ) );
    }

    $c->stash()->{page}                = $page;
    $c->stash()->{revision}            = $revision;
    $c->stash()->{is_current_revision} = 0;
}

sub revision : Chained('_set_revision') : PathPart('') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub revision_GET_html {
    my $self = shift;
    my $c    = shift;

    my $revision = $c->stash()->{revision};
    my $page = $revision->page();

    $c->redirect_and_detach( $page->uri( with_host => 1 ) )
        if $revision->revision_number()
            == $page->most_recent_revision()->revision_number();

    $c->stash()->{html} = $revision->content_as_html(
        user        => $c->user(),
        include_toc => 1,
    );

    $c->stash()->{template} = '/page/view';
}

sub revision_DELETE {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Manage' );

    my $revision = $c->stash()->{revision};
    my $num = $revision->revision_number();

    $revision->delete( user => $c->user() );

    $c->session_object()->add_message( loc('Revision %1 has been deleted.', $num ) );
    $c->redirect_and_detach( $c->stash()->{page}->uri() );
}

sub revision_delete_confirmation : Chained('_set_revision') : PathPart('delete_confirmation') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Manage' );

    $c->stash()->{template} = '/page/revision-delete-confirmation';
}

sub history : Chained('_set_page') : PathPart('history') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $page = $c->stash()->{page};

    my ( $limit, $offset ) = $self->_make_pager(
        $c,
        $page->most_recent_revision()->revision_number(),
    );

    $c->stash()->{revisions} = $page->revisions(
        limit  => $limit,
        offset => $offset,
    );

    $c->stash()->{template} = '/page/history';
}

sub history_atom : Chained('_set_page') : PathPart('history.atom') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $page = $c->stash()->{page};

    my $revisions = $page->revisions( limit => 50 );

    $self->_output_atom_feed_for_revisions(
        $c,
        $revisions,
        loc( 'History for %1', $page->title() ),
        $page->uri( view => 'history',      with_host => 1 ),
        $page->uri( view => 'history.atom', with_host => 1 ),
        $page,
    );
}

sub diff : Chained('_set_page') : PathPart('diff') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $page = $c->stash()->{page};

    my @nums = ( $c->request()->params()->{revision1},
        $c->request()->params()->{revision2} );

    unless ( ( @nums == 2 ) && all { defined && /^\d+$/ } @nums ) {
        $c->redirect_and_detach( $page->uri( with_host => 1 ) );
    }

    my @revisions
        = map {
        Silki::Schema::PageRevision->new(
            page_id         => $page->page_id(),
            revision_number => $_
            )
        }
        sort @nums;

    $c->stash()->{rev1} = $revisions[0];
    $c->stash()->{rev2} = $revisions[1];
    $c->stash()->{diff} = Silki::Schema::PageRevision->Diff(
        rev1 => $revisions[0],
        rev2 => $revisions[1],
    );

    $c->stash()->{formatter} = Silki::Formatter::WikiToHTML->new(
        user => $c->user(),
        page => $c->stash()->{page},
        wiki => $c->stash()->{wiki},
    );

    $c->stash()->{template} = '/page/diff';
}

sub attachments : Chained('_set_page') : PathPart('attachments') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $c->stash()->{file_count} = $c->stash()->{page}->file_count();
    $c->stash()->{files} = $c->stash()->{page}->files();

    $c->stash()->{template} = '/page/attachments';
}

sub file_collection : Chained('_set_page') : PathPart('files') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub file_collection_POST {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Upload' );

    my $upload = $c->request()->upload('file');

    $self->_handle_upload(
        $c,
        $upload,
        $c->stash()->{page}->uri( view => 'attachments' ),
    );

    $c->session_object()->add_message( loc('The file has been uploaded, and this page now links to the file.' ) );
    $c->redirect_and_detach( $c->stash()->{page}->uri( view => 'attachments' ) );
}

sub _handle_upload {
    my $self     = shift;
    my $c        = shift;
    my $upload   = shift;
    my $on_error = shift;

    unless ($upload) {
        $c->redirect_with_error(
            error => loc('You did not select a file to upload.'),
            uri   => $on_error,
        );
    }

    if ( $upload->size() > Silki::Config->instance()->max_upload_size() ) {
        $c->redirect_with_error(
            error => loc('The file you uploaded was too large.'),
            uri   => $on_error,
        );
    }

    if ( $upload->size() == 0 ) {
        $c->redirect_with_error(
            error => loc('The file you uploaded was empty.'),
            uri   => $on_error,
        );
    }

    # Copied the logic from Catalyst::Request::Upload without the last step of
    # removing most characters.
    my $basename = $upload->filename;
    $basename =~ s|\\|/|g;
    $basename = ( File::Spec::Unix->splitpath($basename) )[2];

    my $file;
    eval {
        Silki::Schema->RunInTransaction(
            sub {
                $file = Silki::Schema::File->insert(
                    filename  => $basename,
                    mime_type => mimetype( $upload->tempname() ),
                    file_size => $upload->size(),
                    contents =>
                        do { my $fh = $upload->fh(); local $/; <$fh> },
                    user_id => $c->user()->user_id(),
                    page_id => $c->stash()->{page}->page_id(),
                );

                $c->stash()->{page}->add_file($file)
                    if $c->stash()->{page};
            }
        );
    };

    if ( my $e = $@ ) {
        $c->redirect_with_error(
            error => $e,
            uri   => $on_error,
        );
    }
}

sub tag_collection : Chained('_set_page') : PathPart('tags') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub tag_collection_GET {
    my $self = shift;
    my $c    = shift;

    $self->_tags_as_entity_response($c);
}

sub tag_collection_POST {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki} );

    my @tag_names = map { s/^\s+|\s+$//; $_ } split /\s*,\s*/,
        ( $c->request()->params()->{tags} || q{} );

    my $page = $c->stash()->{page};

    $page->add_tags( tags => \@tag_names ) if @tag_names;

    $self->_tags_as_entity_response($c);
}

sub tag : Chained('_set_page') : PathPart('tag') : Args(1) : ActionClass('+Silki::Action::REST') {
}

sub tag_DELETE {
    my $self = shift;
    my $c    = shift;
    my $tag  = shift;

    my $page = $c->stash()->{page};

    unless (
        $c->user()->has_permission_in_wiki(
            wiki       => $page->wiki(),
            permission => Silki::Schema::Permission->Edit(),
        )
        ) {
        $c->response->status(404);
        return;
    }

    $page->delete_tag($tag);

    $self->_tags_as_entity_response($c);
}

sub _tags_as_entity_response {
    my $self = shift;
    my $c    = shift;

    my $page = $c->stash()->{page};

    my @tags = map { $_->serialize() } $page->tags()->all();
    $_->{'delete_uri'} = $page->uri( view => 'tag/' . $_->{tag} )
        for @tags;

    my $html = $c->view('Mason')->render(
        $c,
        '/page/tag-list.mas', {
            page     => $page,
            can_edit => 1,
        },
    );

    $self->status_ok(
        $c,
        entity => {
            page_id       => $page->page_id(),
            tags          => \@tags,
            tag_list_html => $html,
        },
    );
}

sub delete_confirmation : Chained('_set_page') : PathPart('delete_confirmation') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Delete' );

    $c->stash()->{template} = '/page/delete-confirmation';
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Controller class for pages

__END__
=pod

=head1 NAME

Silki::Controller::Page - Controller class for pages

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

