package Monorail::MigrationScript::Set;
$Monorail::MigrationScript::Set::VERSION = '0.4';
use Moose;
use Path::Class;
use namespace::autoclean;
use Monorail::MigrationScript;
use Graph;

has basedir => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has files => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => '_build_filelist'
);

has migrations => (
    is      => 'ro',
    isa     => 'HashRef[Monorail::MigrationScript]',
    lazy    => 1,
    builder => '_build_migrations'
);

has dbix => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has graph => (
    is      => 'ro',
    isa     => 'Graph',
    lazy    => 1,
    builder => '_build_graph'
);


__PACKAGE__->meta->make_immutable;

sub get {
    my ($self, $name) = @_;

    return $self->migrations->{$name};
}

sub in_topological_order {
    my ($self) = @_;

    return map { $self->migrations->{$_} } $self->graph->topological_sort;
}

sub current_dependencies {
    my ($self) = @_;

    my @deps = $self->graph->sink_vertices;

    if (!@deps) {
        # we might be in the special case of building the second migration...
        @deps = $self->graph->isolated_vertices
    }

    return map { $self->migrations->{$_} } @deps;
}


sub next_auto_name {
    my ($self) = @_;

    my $base    = $self->basedir;
    my @numbers = sort { $b <=> $a }
                  map  { m/(\d+)_auto\.pl/ }
                  glob("$base/*_auto.pl");

    my $max = $numbers[0] || 0;

    return sprintf("%04d_auto", $max + 1);
}


sub _build_graph {
    my ($self) = @_;

    my $graph = Graph->new(directed => 1);

    foreach my $migration (values %{$self->migrations}) {
        # add the migration as a vertex to handle the case of a single migration.
        # if we don't make the vertex, we'll have an empty graph because this
        # migration has no deps and the loop below doesn't run.
        $graph->add_vertex($migration->name);

        foreach my $dep (@{$migration->dependencies}) {
            #warn sprintf("Making edge: %s --> %s\n", $dep, $migration->name);
            $graph->add_edge($dep, $migration->name)
        }
    }

    return $graph;
}


sub _build_filelist {
    my ($self) = @_;


    my $dir = dir($self->basedir);

    my @scripts;
    while (my $file = $dir->next) {
        next unless -f $file && $file =~ m/\.pl$/;
        push(@scripts, $file->stringify);
    }

    return \@scripts;
}

sub _build_migrations {
    my ($self) = @_;

    my %migrations;
    foreach my $file (@{$self->files}) {
        my $migration = Monorail::MigrationScript->new(
            filename => $file,
            dbix     => $self->dbix,
        );

        $migrations{$migration->name} = $migration;
    }

    return \%migrations;
}

1;
__END__
