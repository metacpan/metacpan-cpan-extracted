package Silki::Controller::Wiki;
{
  $Silki::Controller::Wiki::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;
use autodie;

use DateTime::Format::W3CDTF 0.05;
use Email::Address;
use File::Basename qw( dirname );
use File::MimeInfo qw( mimetype );
use Path::Class qw( dir file );
use Silki::Config;
use Silki::Formatter::HTMLToWiki;
use Silki::I18N qw( loc );
use Silki::Schema::Page;
use Silki::Schema::Process;
use Silki::Schema::Role;
use Silki::Schema::Wiki;
use Silki::Util qw( detach_and_run string_is_empty );
use XML::Atom::SimpleFeed;

use Moose;

BEGIN { extends 'Silki::Controller::Base' }

with qw(
    Silki::Role::Controller::PagePreview
    Silki::Role::Controller::Pager
    Silki::Role::Controller::RevisionsAtomFeed
    Silki::Role::Controller::User
    Silki::Role::Controller::WikitextHandler
);

sub _set_wiki : Chained('/') : PathPart('wiki') : CaptureArgs(1) {
    my $self      = shift;
    my $c         = shift;
    my $wiki_name = shift;

    my $wiki = Silki::Schema::Wiki->new( short_name => $wiki_name );

    $c->redirect_and_detach( $c->domain()->uri( with_host => 1 ) )
        unless $wiki;

    $self->_require_permission_for_wiki( $c, $wiki, 'Read' );

    my $front_page = Silki::Schema::Page->new(
        title   => $wiki->front_page_title(),
        wiki_id => $wiki->wiki_id(),
    );

    $c->add_tab($_)
        for (
        {
            uri     => $wiki->uri(),
            label   => $wiki->title(),
            tooltip => loc( '%1 dashboard', $wiki->title() ),
            id      => 'dashboard',
        }, {
            uri     => $front_page->uri(),
            label   => loc('Front Page'),
            tooltip => loc( '%1 Front Page', $wiki->title() ),
            id      => 'front-page',
        }, {
            uri     => $wiki->uri( view => 'recent' ),
            label   => loc('Recent Changes'),
            tooltip => loc('Recent activity in this wiki'),
            id      => 'recent-changes',
        },
        );

    $c->stash()->{wiki} = $wiki;
}

sub wiki : Chained('_set_wiki') : PathPart('') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub wiki_GET_html {
    my $self = shift;
    my $c    = shift;

    my $uri = $c->stash()->{wiki}->uri( view => 'dashboard' );

    $c->redirect_and_detach($uri);
}

sub delete_confirmation : Chained('_set_wiki') : PathPart('delete_confirmation') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    $c->stash()->{template} = '/wiki/delete-confirmation';
}

sub export : Chained('_set_wiki') : PathPart('export') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    $self->_require_permission_for_wiki( $c, $wiki, 'Manage' );

    my $process = Silki::Schema::Process->insert( wiki_id => $wiki->wiki_id() );

    my $dir = Silki::Config->temp_dir()->subdir( 'wiki-' . $wiki->wiki_id() );
    $dir->mkpath( 0, 0700 );
    my $file = $dir->file( $wiki->short_name() . '.tar.gz' );

    detach_and_run(
        'silki-export',
        '--wiki',    $wiki->short_name(),
        '--file',    $file,
        '--process', $process->process_id(),
    );

    $c->stash()->{download_uri} = $wiki->uri( view => 'tempfile/' . $file->basename() );
    $c->stash()->{process} = $process;

    $c->stash()->{template} = '/wiki/export';
}

sub tempfile : Chained('_set_wiki') : PathPart('tempfile') : Args(1) {
    my $self     = shift;
    my $c        = shift;
    my $filename = shift;

    my $wiki = $c->stash()->{wiki};

    $self->_require_permission_for_wiki( $c, $wiki, 'Manage' );

    my $file = Silki::Config->temp_dir()->subdir( 'wiki-' . $wiki->wiki_id() )
        ->file($filename);

    unless ( -f $file ) {
        $c->response()->status(404);
        $c->detach();
    }

    my $basename = $file->basename();

    $c->response()->status(200);
    $c->response()->content_type( mimetype( $file->stringify() ) );
    $c->response()
        ->header(
        'Content-Disposition' => qq{attachment; filename="$basename"} );
    $c->response()->content_length( -s $file );
    $c->response()->header( 'X-Sendfile' => $file );

    $c->detach();
}

sub wiki_DELETE {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    my $wiki = $c->stash()->{wiki};

    my $msg = loc( 'Deleted the wiki %1', $wiki->title() );

    my $domain = $wiki->domain();

    $wiki->delete( user => $c->user() );

    $c->session_object()->add_message($msg);

    $c->redirect_and_detach( $domain->uri( with_host => 1 ) );
}

sub dashboard : Chained('_set_wiki') : PathPart('dashboard') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $c->tab_by_id('dashboard')->set_is_selected(1);

    my $wiki = $c->stash()->{wiki};

    $c->stash()->{changes} = $wiki->revisions( limit => 10 );

    $c->stash()->{views} = $wiki->recently_viewed_pages( limit => 10 );

    $c->stash()->{tags} = $wiki->popular_tags( limit => 10 );

    $c->stash()->{users} = $wiki->active_users( limit => 10 );

    $c->stash()->{template} = '/wiki/dashboard';
}

sub recent : Chained('_set_wiki') : PathPart('recent') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $c->tab_by_id('recent-changes')->set_is_selected(1);

    my $wiki = $c->stash()->{wiki};

    my ( $limit, $offset )
        = $self->_make_pager( $c, $wiki->revision_count() );

    $c->stash()->{pages} = $wiki->revisions(
        limit  => $limit,
        offset => $offset,
    );

    $c->stash()->{template} = '/wiki/recent';
}

sub recent_atom : Chained('_set_wiki') : PathPart('recent.atom') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    my $revisions = $wiki->revisions( limit => 50 );

    $self->_output_atom_feed_for_revisions(
        $c,
        $revisions,
        loc( 'Recent Changes in %1', $wiki->title() ),
        $wiki->uri( view => 'recent',      with_host => 1 ),
        $wiki->uri( view => 'recent.atom', with_host => 1 ),
    );
}

sub attachments : Chained('_set_wiki') : PathPart('attachments') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $count = $c->stash()->{wiki}->file_count();

    my ( $limit, $offset ) = $self->_make_pager( $c, $count );

    $c->stash()->{file_count} = $count;
    $c->stash()->{files}      = $c->stash()->{wiki}->files(
        limit  => $limit,
        offset => $offset,
    );

    $c->stash()->{template} = '/wiki/attachments';
}

sub file_collection : Chained('_set_wiki') : PathPart('files') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub file_collection_POST {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Upload' );

    my $upload = $c->request()->upload('file');

    $self->_handle_upload(
        $c,
        $upload,
        $c->stash()->{wiki}->uri( view => 'attachments' ),
    );

    $c->session_object()->add_message( loc('The file has been uploaded.' ) );
    $c->redirect_and_detach( $c->stash()->{wiki}->uri( view => 'attachments' ) );
}

sub orphans : Chained('_set_wiki') : PathPart('orphans') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    my $count = $wiki->orphaned_page_count();

    my ( $limit, $offset ) = $self->_make_pager( $c, $count );

    $c->stash()->{orphan_count} = $count;
    $c->stash()->{orphans}      = $wiki->orphaned_pages(
        limit  => $limit,
        offset => $offset,
    );

    $c->stash()->{template} = '/wiki/orphans';
}

sub wanted : Chained('_set_wiki') : PathPart('wanted') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    my $count = $wiki->wanted_page_count();

    my ( $limit, $offset ) = $self->_make_pager( $c, $count );

    $c->stash()->{wanted_count} = $count;
    $c->stash()->{wanted}       = $wiki->wanted_pages(
        limit  => $limit,
        offset => $offset,
    );

    $c->stash()->{template} = '/wiki/wanted';
}

sub users : Chained('_set_wiki') : PathPart('users') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    my $count = $wiki->member_count();

    my ( $limit, $offset ) = $self->_make_pager( $c, $count );

    $c->stash()->{users} = $wiki->members(
        limit  => $limit,
        offset => $offset,
    );

    $c->stash()->{template} = '/wiki/users';
}

sub settings : Chained('_set_wiki') : PathPart('settings') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Manage' );

    $c->stash()->{template} = '/wiki/settings';
}

sub permissions_form : Chained('_set_wiki') : PathPart('permissions_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Manage' );

    $c->stash()->{template} = '/wiki/permissions-form';
}

sub permissions : Chained('_set_wiki') : PathPart('permissions') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub permissions_PUT {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    $self->_require_permission_for_wiki( $c, $wiki, 'Manage' );

    my $perms = $c->request()->params()->{permissions};

    $wiki->set_permissions($perms);

    my $perm_loc = loc($perms);
    $c->session_object()->add_message( loc('Permissions for this wiki have been set to %1', $perm_loc ) );

    $c->redirect_and_detach( $wiki->uri( view => 'permissions_form' ) );
}

sub members_form : Chained('_set_wiki') : PathPart('members_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Manage' );

    $c->stash()->{members} = $c->stash()->{wiki}->members();

    $c->stash()->{template} = '/wiki/members-form';
}

sub members : Chained('_set_wiki') : PathPart('members') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub members_PUT {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    $self->_require_permission_for_wiki( $c, $wiki, 'Manage' );

    $self->_process_existing_member_changes($c);
    $self->_process_new_members($c);

    $c->redirect_and_detach( $wiki->uri( view => 'members_form' ) );
}

sub _process_existing_member_changes {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    for my $user_id ( $c->request()->param('members') ) {
        next if $user_id == $c->user()->user_id();

        my $role_id = $c->request()->params()->{ 'role_for_' . $user_id };

        my $user = Silki::Schema::User->new( user_id => $user_id );
        if ( !$role_id ) {
            $wiki->remove_user( user => $user );
            $c->session_object()
                ->add_message(
                loc( '%1 was removed as a wiki member.', $user->best_name() )
                );
        }
        else {
            my $role = Silki::Schema::Role->new( role_id => $role_id );
            my $current_role = $user->role_in_wiki($wiki);
            next if $role->role_id() == $current_role->role_id();

            $wiki->add_user( user => $user, role => $role );
            if ( $role->name eq 'Admin' ) {
                $c->session_object()->add_message(
                    loc(
                        '%1 is now an admin for this wiki.',
                        $user->best_name()
                    )
                );
            }
            else {
                $c->session_object()->add_message(
                    loc(
                        '%1 is no longer an admin for this wiki.',
                        $user->best_name()
                    )
                );
            }
        }
    }
}

sub _process_new_members {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    my $params = $c->request()->params();

    for my $address ( Email::Address->parse( $params->{new_members} ) ) {
        my %message
            = string_is_empty( $params->{message} )
            ? ()
            : ( message => $params->{message} );

        my $user = Silki::Schema::User->new( email_address => $address->address() );
        if ($user) {
            if ( $user->is_wiki_member($wiki) ) {
                $c->session_object()->add_message(
                    loc(
                        '%1 is already a member of this wiki.',
                        $user->best_name()
                    )
                );
                next;
            }

            if ( $user->requires_activation() ) {
                $c->session_object()->add_message(
                    loc(
                        'An unactived account for %1 already exists. Once the account is activated, this user will be able to access this wiki.',
                        $user->best_name()
                    )
                );
            }
            else {
                $c->session_object()->add_message(
                    loc(
                        '%1 is now a member of this wiki.',
                        $user->best_name()
                    )
                );
            }

            $user->send_invitation_email(
                wiki   => $wiki,
                sender => $c->user(),
                domain => $c->domain(),
                %message,
            );
        }
        else {
            $user = Silki::Schema::User->insert(
                requires_activation => 1,
                email_address       => $address->address(),
                (
                    $address->phrase()
                    ? ( display_name => $address->phrase() )
                    : ()
                ),
                user => $c->user(),
            );

            $user->send_activation_email(
                wiki   => $wiki,
                sender => $c->user(),
                domain => $c->domain(),
                %message,
            );

            $c->session_object()->add_message(
                loc(
                    'A user account for %1 has been created, and this person has been invited to join this wiki.',
                    $address->address()
                )
            );
        }

        $wiki->add_user(
            user => $user,
            role => Silki::Schema::Role->Member(),
        );
    }
}

sub new_page_form : Chained('_set_wiki') : PathPart('new_page_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Edit' );

    $c->stash()->{title}   = $c->request()->params()->{title};
    $c->stash()->{preview} = q{<br />};

    $c->stash()->{template} = '/wiki/new-page-form';
}

sub new_page_html : Chained('_set_wiki') : PathPart('html') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_send_preview_html($c);
}

sub page_collection : Chained('_set_wiki') : PathPart('pages') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub page_collection_POST {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Edit' );

    my $wiki = $c->stash()->{wiki};

    my $wikitext = eval { $self->_wikitext_from_form( $c, $wiki ) };

    if ( my $e = $@ ) {
        $c->redirect_with_error(
            errors    => $e,
            uri       => $wiki->uri( view => 'new_page_form' ),
            form_data => $c->request()->params(),
        );
    }

    my $page = Silki::Schema::Page->insert_with_content(
        title   => $c->request()->params()->{title},
        content => $wikitext,
        wiki_id => $wiki->wiki_id(),
        user_id => $c->user()->user_id(),
    );

    $c->redirect_and_detach( $page->uri() );
}

sub _set_user : Chained('_set_wiki') : PathPart('user') : CaptureArgs(1) {
}

sub _make_user_uri {
    my $self = shift;
    my $c    = shift;
    my $user = shift;
    my $view = shift || undef;

    my $real_view = 'user/' . $user->user_id();
    $real_view .= q{/} . $view if defined $view;

    return $c->stash()->{wiki}->uri( view => $real_view );
}

sub search : Chained('_set_wiki') : PathPart('search') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub search_GET_html {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    my $search = $c->request()->params()->{search};

    $c->redirect_and_detach( $wiki->uri() )
        if string_is_empty($search);

    $search =~ s/^\s+|\s+$//g;

    ( my $pg_query = $search ) =~ s/\s+/ & /g;

    $c->stash()->{search_results} = $wiki->text_search( query => $pg_query );
    $c->stash()->{search} = $search;

    $c->stash()->{template} = '/wiki/search-results';
}

sub tag_collection : Chained('_set_wiki') : PathPart('tags') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub tag_collection_GET_html {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    $c->stash()->{tag_count} = $wiki->tag_count();
    $c->stash()->{tags} = $wiki->popular_tags()
        if $c->stash()->{tag_count};

    $c->stash()->{template} = '/wiki/tags';
}

sub tag : Chained('_set_wiki') : PathPart('tag') : Args(1) : ActionClass('+Silki::Action::REST') {
}

sub tag_GET_html {
    my $self = shift;
    my $c    = shift;
    my $tag  = shift;

    my $wiki = $c->stash()->{wiki};

    $c->stash()->{tag} = $tag;
    $c->stash()->{page_count} = $wiki->pages_tagged_count( tag => $tag );
    $c->stash()->{pages} = $wiki->pages_tagged( tag => $tag )
        if $c->stash()->{page_count};

    $c->stash()->{template} = '/wiki/tag';
}

sub new_wiki_form : Path('/wikis/new_wiki_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    $c->stash()->{template} = '/wiki/new-wiki-form';
}

sub import_wiki_form : Path('/wikis/import_wiki_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    $c->stash()->{template} = '/wiki/import-wiki-form';
}

sub wiki_collection : Path('/wikis') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub wiki_collection_GET_html {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    my ( $limit, $offset ) = $self->_make_pager( $c, Silki::Schema::Wiki->Count() );

    $c->stash()->{wikis} = Silki::Schema::Wiki->All(
        limit  => $limit,
        offset => $offset,
    );

    $c->stash()->{template} = '/wiki/wikis';
}

sub wiki_collection_POST {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    if ( $c->request()->params()->{tarball} ) {
        $self->_import_wiki($c);
    }
    else {
        $self->_create_wiki($c);
    }
}

sub _import_wiki {
    my $self = shift;
    my $c    = shift;

    # We can't insert with _no_ values, so this is a hack to make the insert
    # work.
    my $process = Silki::Schema::Process->insert( status => q{} );

    my $file = file( $c->request()->upload('tarball')->tempname() );
    my $tarball = Silki::Config->instance()->temp_dir()->file( $file->basename );

    rename $file => $tarball;

    detach_and_run(
        'silki-import',
        '--process', $process->process_id(),
        '--domain',  $c->domain()->web_hostname(),
        '--tarball', $tarball,
    );


    $c->stash()->{process} = $process;

    $c->stash()->{template} = '/wiki/import';
}

sub _create_wiki {
    my $self = shift;
    my $c    = shift;

    my %form_data = $c->request()->wiki_params();
    my $perms = $c->request()->params()->{permissions};

    my $wiki;

    eval {
        Silki::Schema->RunInTransaction(
            sub {
                $wiki = Silki::Schema::Wiki->insert(
                    %form_data,
                    user => $c->user(),
                );

                $wiki->set_permissions($perms);

                $wiki->add_user(
                    user => $c->user(),
                    role => Silki::Schema::Role->Admin(),
                );
            }
        );
    };

    if ( my $e = $@ ) {
        $c->redirect_with_error(
            error => $e,
            uri   => $c->domain()->application_uri( path => 'new_wiki_form' ),
            form_data => { %form_data, permissions => $perms },
        );
    }

    $c->redirect_and_detach( $wiki->uri() );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Controller class for wikis

__END__
=pod

=head1 NAME

Silki::Controller::Wiki - Controller class for wikis

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

