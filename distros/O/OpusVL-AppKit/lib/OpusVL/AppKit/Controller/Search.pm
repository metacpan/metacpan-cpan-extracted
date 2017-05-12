package OpusVL::AppKit::Controller::Search;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config(
    appkit_name => 'Search',
);

sub auto 
    : Action 
    : AppKitFeature('Search box')
{
    my ($self, $c) = @_;
    
    push @{$c->stash->{breadcrumbs}},{
        name => 'Search',
        url  => $c->uri_for($c->controller->action_for('index')),
    };
}


sub index :Path 
    : AppKitFeature('Search box')
{
    my ($self, $c) = @_;
    
    $c->_appkit_stash_searches($c->req->param('q'));
    $c->stash->{query} = $c->req->param('q');
}

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Controller::Search

=head1 VERSION

version 2.29

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
