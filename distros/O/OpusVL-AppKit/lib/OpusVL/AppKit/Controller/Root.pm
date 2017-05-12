package OpusVL::AppKit::Controller::Root;


############################################################################################################
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

use File::ShareDir ':ALL';

__PACKAGE__->config->{namespace}    = '';
  
sub auto 
    : Action 
    : AppKitAllAccess
{
    my ( $self, $c ) = @_;
    return 1;
}


sub index 
    :Path 
    :Args(0) 
    : AppKitFeature('Home Page')
{
    my ( $self, $c ) = @_;

    $c->_appkit_stash_portlets;

    $c->stash->{template} = 'index.tt';
    $c->stash->{homepage} = 1;
}


sub default :Path 
{
    my ( $self, $c ) = @_;
    delete $c->stash->{current_view} if defined $c->stash->{current_view}; # ensure default view.
    $c->stash->{template} = '404.tt';
    $c->response->status(404);
    $c->stash->{homepage} = 1;
    $c->detach;
}

sub not_found :Private
{
    my ($self, $c) = @_;
    $c->forward('/default');
}

sub access_denied : Private
{
    my ( $self, $c ) = @_;
    $c->REST_403 if($c->in_REST_action);
    $c->stash->{template} = '403.tt';
    delete $c->stash->{current_view} if defined $c->stash->{current_view}; # ensure default view.
    $c->response->status(403);
    $c->stash->{homepage} = 1;
    $c->detach('View::AppKitTT');
}


sub end : ActionClass('RenderView') 
{
    my ( $self, $c ) = @_;
    unless($c->config->{no_clickjack_protection} || $c->stash->{no_clickjack_protection})
    {
        if($c->config->{clickjack_same_origin})
        {
            $c->response->headers->header( 'X-FRAME-OPTIONS' => 'SAMEORIGIN' );
        }
        else
        {
            $c->response->headers->header( 'X-FRAME-OPTIONS' => 'DENY' );
        }
    }
    $c->response->headers->header('X-XSS-Protection' => '1; mode=block');
    if($c->config->{ssl_only})
    {
        $c->response->headers->header('Strict-Transport-Security' => 'max-age=31536000; includeSubDomains');
    }
    $c->response->headers->header('X-Content-Type-Options' => 'nosniff');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Controller::Root

=head1 VERSION

version 2.29

=head1 DESCRIPTION

    The OpusVL::AppKit is intended to be inherited by another Catalyst App using AppBuilder.

    The current intention is that Apps that use AppKit do not need to have their own Root Controller,
    but use this one. 
    If you app requires its own Root.pm Controller, you should inherite this one    

    This should provide all the base funcationallity required for delivery of standard sites
    developed by the OpusVL team.

=head1 NAME

    OpusVL::AppKit::Controller::Root - Root Controller for OpusVL::AppKit

=head1 METHODS

=head2 auto

=head2 index
    This is intended to be seen as the AppKit home page.

=head2 access_notallowed
    This called by the ACL method when an access control rule is broken. (including not being logged in!)
    Configured in myapp.conf     :
        <OpusVL::AppKit::Plugin::AppKit>
            access_denied   "access_notallowed"
        </OpusVL::AppKit::Plugin::AppKit>

=head2 end
    Attempt to render a view, if needed.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
