package Mojolicious::Plugin::Minion::Overview::Facade;
use Mojo::Base -base;

use Mojolicious::Plugin::Minion::Overview::Backend::mysql;


=head2 load

Load the Minion overview backend

=cut

sub load {
    my ($self, $minion) = @_;
    
    if ($minion->backend->isa('Minion::Backend::mysql')) {
        return Mojolicious::Plugin::Minion::Overview::Backend::mysql->new(db => $minion->backend->mysql->db, minion => $minion);
    }

    die "Backend not yet implemented";
}

1;
