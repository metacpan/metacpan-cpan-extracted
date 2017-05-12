package ProjectX::Direct;

use Moose;
use Project::Environment;

=head2 env



=cut

has env => (
    is      => 'ro',
    isa     => 'Project::Environment',
    lazy    => 1,
    builder => '_build_env',
);

sub _build_env {
    my $self = shift;

    return Project::Environment->new(environment_filename => 'environment');
}

1;
