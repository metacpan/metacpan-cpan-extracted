package Silki::Controller::Base;
{
  $Silki::Controller::Base::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use autodie;
use Carp qw( croak );
use Silki::Config;
use Silki::I18N qw( loc );
use Silki::JSON;
use Silki::Schema;
use Silki::Schema::File;
use Silki::Web::CSS;
use Silki::Web::Javascript;

use Moose;

BEGIN { extends 'Catalyst::Controller::REST' }

sub begin : Private {
    my $self = shift;
    my $c    = shift;

    Silki::Schema->ClearObjectCaches();

    return unless $c->request()->looks_like_browser();

    my $config = Silki::Config->instance();

    unless ( $config->is_production() || $config->is_profiling() ) {
        $_->new()->create_single_file()
            for qw( Silki::Web::CSS Silki::Web::Javascript );
    }

    my $user = $c->user();
    my @langs = $user->is_system_user() ? () : $user->locale_code();

    Silki::I18N->SetLanguage(@langs);

    return 1;
}

sub end : Private {
    my $self = shift;
    my $c    = shift;

    return $self->next::method($c)
        if $c->stash()->{rest};

    # Catalyst::Plugin::XSendfile seems to be designed to only work with
    # Lighthttpd, and deletes any file over 16kb, which we don't want to do. I
    # should probably patch it at some point.
    if ( my $file = $c->response()->header('X-Sendfile') ) {
        my ($engine) = ( ref $c->engine() ) =~ /^Catalyst::Engine::(.+)$/;

        if ( $engine =~ /^HTTP/ ) {
            if ( -f $file ) {
                open my $fh, '<', $file;
                $c->response()->body($fh);
            }
            else {
                $c->log()
                    ->error(
                    "X-sendfile pointed at nonexistent file - $file\n");
                $c->response()->status(404);
            }
        }

        return;
    }

    if (   ( !$c->response()->status() || $c->response()->status() == 200 )
        && !$c->response()->body()
        && !@{ $c->error() || [] } ) {
        $c->forward( $c->view() );
    }

    return;
}

sub _set_entity {
    my $self   = shift;
    my $c      = shift;
    my $entity = shift;

    $c->response()->content_type('application/json');
    $c->response()->body( Silki::JSON->Encode($entity) );

    return 1;
}

my %MethodPermission = (
    GET    => 'Read',
    POST   => 'Edit',
    PUT    => 'Edit',
    DELETE => 'Delete',
);

sub _require_permission_for_wiki {
    my $self = shift;
    my $c    = shift;
    my $wiki = shift;
    my $perm = shift;

    $perm ||= $MethodPermission{ uc $c->request()->method() };

    croak 'No permission specified in call to _require_permission_for_wiki'
        unless $perm;

    my $user = $c->user();

    return
        if $user->has_permission_in_wiki(
        wiki       => $wiki,
        permission => Silki::Schema::Permission->$perm(),
        );

    my $perms = $wiki->permissions();

    if ( $user->is_guest() ) {
        if ( $perms->{Authenticated}{$perm} ) {
            $c->session_object()->add_message(
                loc(
                    'You must log in to to perform this action in the %1 wiki.',
                    $wiki->title(),
                )
            );
        }
        else {
            $c->session_object()->add_message(
                loc(
                    'You must be a member of the %1 wiki to perform this action.',
                    $wiki->title()
                )
            );
        }

        my $uri = $c->domain()->application_uri(
            path  => '/user/login_form',
            query => { return_to => $c->request()->uri() },
        );

        $c->redirect_and_detach($uri);
    }
    else {
        if ( $user->is_wiki_member($wiki) ) {
            $c->session_object()->add_message(
                loc(
                    'You do not have %1 permissions in this wiki.',
                    lc $perm
                )
            );

        }
        else {
            $c->session_object()->add_message(
                loc(
                    'You must be a member of the %1 wiki to perform this action.',
                    $wiki->title()
                )
            );
        }

        my $role = $user->role_in_wiki($wiki);

        my $uri;
        if ( $perms->{$role}{Read} ) {
            $uri
                = $c->stash()->{page}
                ? $c->stash()->{page}->uri()
                : $wiki->uri();
        }
        else {
            $uri = $c->domain()->uri();
        }

        $c->redirect_and_detach($uri);
    }

}

sub _require_site_admin {
    my $self = shift;
    my $c    = shift;

    return if $c->user()->is_admin();

    $c->redirect_and_detach( $c->domain()->application_uri( path => '/' ) );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Controller base class

__END__
=pod

=head1 NAME

Silki::Controller::Base - Controller base class

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

