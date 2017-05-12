package Perldoc::Server::Controller::View;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::Controller';

=head1 NAME

Perldoc::Server::Controller::View - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path {
    my ( $self, $c, @pod ) = @_;
    
    my $page = join '::',@pod;
    $c->stash->{title}       = $page;
    $c->stash->{path}        = \@pod;
    $c->stash->{pod}         = $c->model('Pod')->pod($page);
    $c->stash->{contentpage} = 1;
    
    # Count the page views in the user's session
    my $uri = join '/','/view',@pod;
    $c->session->{counter}{$uri}{count}++;
    $c->session->{counter}{$uri}{name} = $page;
    
    given ($page) {
        when ($c->model('Pod')->section($_)) {
            my $section = $c->model('Pod')->section($_);
            #$c->log->debug("Found $page in section $section");
            $c->stash->{breadcrumbs} = [
                { url => $c->uri_for('/index',$section), name => $c->model('Section')->name($section) },                
            ];
        }
        when (/^([A-Z])/) {
            $c->stash->{breadcrumbs} = [
                { url => $c->uri_for('/index/modules'), name => 'Modules' },
                { url => $c->uri_for('/index/modules',$1), name => $1 },
            ];
            $c->stash->{source_available} = 1;
        }
        default {
            $c->stash->{breadcrumbs} = [
                { url => $c->uri_for('/index/pragmas'), name => 'Pragmas' },
            ];
        }
    }
    
    $c->forward('View::Pod2HTML');
}


=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
