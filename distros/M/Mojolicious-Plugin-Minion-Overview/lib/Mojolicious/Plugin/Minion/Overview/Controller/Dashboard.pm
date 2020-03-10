package Mojolicious::Plugin::Minion::Overview::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller';

=head2 overview

Show dashboard overview

=cut

sub overview {
    my $self = shift;

    my $overview = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->overview;

    return $self->render('minion_overview/dashboard/_overview',
        overview   => $overview,
    );
}

=head2 search

Show dashboard metrics

=cut

sub search {
    my $self = shift;

    my $dashboard = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->dashboard;

    return $self->render('minion_overview/dashboard/search',
        overview    => $dashboard->{ overview },
        workers     => $dashboard->{ workers },
    );
}

=head2 workers

Show dashboard workers

=cut

sub workers {
    my $self = shift;

    my $workers = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->workers;

    return $self->render('minion_overview/dashboard/_workers',
        workers   => $workers,
    );
}

1;
