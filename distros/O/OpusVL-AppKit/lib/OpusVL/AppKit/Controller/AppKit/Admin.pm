package OpusVL::AppKit::Controller::AppKit::Admin;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';


sub auto
    : Action
    : AppKitFeature('Role Administration,User Administration,Password Change')
{
    my ( $self, $c ) = @_;

    # add to the bread crumb..
    push ( @{ $c->stash->{breadcrumbs} }, { name => 'Settings', url => $c->uri_for( $c->controller('AppKit::Admin')->action_for('index') ) } );
}


sub index
    : Path
    : Args(0)
    : AppKitFeature('Role Administration,User Administration,Password Change')
{
    my ( $self, $c ) = @_;

}

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Controller::AppKit::Admin

=head1 VERSION

version 2.29

=head2 auto

=head2 index

    Default action for this controller.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
