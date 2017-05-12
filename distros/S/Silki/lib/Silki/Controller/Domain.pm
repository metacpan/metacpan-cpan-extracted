package Silki::Controller::Domain;
{
  $Silki::Controller::Domain::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::I18N qw( loc );
use Silki::Schema::Domain;

use Moose;

BEGIN { extends 'Silki::Controller::Base' }

with qw(
    Silki::Role::Controller::Pager
);

sub _set_domain : Chained('/') : PathPart('domain') : CaptureArgs(1) {
    my $self      = shift;
    my $c         = shift;
    my $domain_id = shift;

    my $domain = Silki::Schema::Domain->new( domain_id => $domain_id );

    $c->redirect_and_detach( $c->domain()->uri( with_host => 1 ) )
        unless $domain;

    $c->stash()->{domain} = $domain;
}

sub edit_form : Chained('_set_domain') : PathPart('edit_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    $c->stash()->{template} = '/domain/edit-form';
}

sub domain : Chained('_set_domain') : PathPart('') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub domain_PUT {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    my %form_data = $c->request()->domain_params();

    my $domain = $c->stash()->{domain};

    eval { $domain->update(%form_data) };

    if ( my $e = $@ ) {
        $c->redirect_with_error(
            error     => $e,
            uri       => $domain->entity_uri( view => 'edit_form' ),
            form_data => \%form_data,
        );
    }

    $c->session_object()
        ->add_message(
        loc( 'The %1 domain has been updated.', $domain->web_hostname() ) );

    $c->redirect_and_detach( $c->domain()->application_uri( path => '/domains' ) );
}

sub new_domain_form : Path('/new_domain_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    $c->stash()->{template} = '/domain/new-domain-form';
}

sub domain_collection : Path('/domains') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub domain_collection_GET_html {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    my ( $limit, $offset ) = $self->_make_pager( $c, Silki::Schema::Domain->Count() );

    $c->stash()->{domains} = Silki::Schema::Domain->All(
        limit  => $limit,
        offset => $offset,
    );

    $c->stash()->{template} = '/domain/domains';
}

sub domain_collection_POST {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    my %form_data = $c->request()->domain_params();

    my $domain = eval { Silki::Schema::Domain->insert(%form_data) };

    if ( my $e = $@ ) {
        $c->redirect_with_error(
            error => $e,
            uri => $c->domain()->application_uri( path => 'new_domain_form' ),
            form_data => \%form_data,
        );
    }

    $c->redirect_and_detach( $domain->uri( with_host => 1 ) );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Controller class for domains

__END__
=pod

=head1 NAME

Silki::Controller::Domain - Controller class for domains

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

