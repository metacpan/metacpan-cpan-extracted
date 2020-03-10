package Mojolicious::Plugin::Minion::Overview::Controller::Overview;
use Mojo::Base 'Mojolicious::Controller';

=head2 setDate

Set date for minion overview

=cut

sub setDate {
    my $self = shift;
    
    $self->session({ minion_overview_date => $self->param('date') });

    return $self->redirect_to($self->req->headers->referrer || $self->url_for('minion_overview.dashboard'));
}

1;
