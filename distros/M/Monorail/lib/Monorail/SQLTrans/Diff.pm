package Monorail::SQLTrans::Diff;
$Monorail::SQLTrans::Diff::VERSION = '0.4';
use Moose;

extends 'SQL::Translator::Diff';

has procedures_to_create => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);
has procedures_to_drop => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);
has procedures_to_alter => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] }
);
has views_to_create => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);
has views_to_drop => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);
has views_to_alter => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);

after compute_differences => sub {
    my ($self) = @_;

    $self->_compute_procedure_differences();
    $self->_compute_view_differences();
};

sub _compute_procedure_differences {
    my ($self) = @_;

    my $target_schema = $self->target_schema;
    my $source_schema = $self->source_schema;

    my %src_procs_checked = ();
    my @target_procs = sort { $a->name cmp $b->name } $target_schema->get_procedures;
    ## do original/source procs exist in target?
    foreach my $target_proc (@target_procs) {
        my $source_proc = $source_schema->get_procedure($target_proc->name);

        if (!$source_proc) {
            ## function is new
            push(@{$self->procedures_to_create}, $target_proc);
        }
        elsif (!$source_proc->equals($target_proc)) {
            ## the fucntion has changed
            push(@{$self->procedures_to_alter}, $target_proc);
        }
    }

    foreach my $source_proc ($source_schema->get_procedures) {
        my $target_proc = $target_schema->get_procedure($source_proc->name);

        unless ($target_proc) {

            # the function no longer exists
            push(@{$self->procedures_to_drop}, $source_proc);
        }
    }

    return $self;
}

sub _compute_view_differences {
    my ($self) = @_;

    my $target_schema = $self->target_schema;
    my $source_schema = $self->source_schema;

    my %src_procs_checked = ();
    my @target_views = sort { $a->name cmp $b->name } $target_schema->get_views;

    ## do original/source procs exist in target?
    foreach my $target_view (@target_views) {
        my $source_view = $source_schema->get_view($target_view->name);

        if (!$source_view) {
            ## view is new
            push(@{$self->views_to_create}, $target_view);
        }
        elsif (!$source_view->equals($target_view)) {
            ## the view has changed
            push(@{$self->views_to_alter}, $target_view);
        }
    }

    foreach my $source_view ($source_schema->get_views) {
        my $target_view = $target_schema->get_view($source_view->name);

        unless ($target_view) {

            # the view no longer exists
            push(@{$self->views_to_drop}, $source_view);
        }
    }

    return $self;
}

around produce_diff_sql => sub {
    my $orig = shift;
    my $self = shift;

    my @output = $self->$orig();

    my $producer_class = "SQL::Translator::Producer::@{[$self->output_db]}";

    unshift(@output, $self->_procedure_diff_sql($producer_class));
    push(@output, $self->_view_diff_sql($producer_class));

    return @output;
};


sub _procedure_diff_sql {
    my ($self, $producer) = @_;

    my @diff;

    my $create = $producer->can('create_procedure');
    my $alter  = $producer->can('alter_procedure');
    my $drop   = $producer->can('drop_procedure');

    return unless $create && $alter && $drop;

    foreach my $proc (@{$self->procedures_to_create}) {
        push(@diff, $create->($proc));
    }

    foreach my $proc (@{$self->procedures_to_alter}) {
        push(@diff, $alter->($proc));
    }

    foreach my $proc (@{$self->procedures_to_drop}) {
        push(@diff, $drop->($proc));
    }

    return @diff;
}


sub _view_diff_sql {
    my ($self, $producer) = @_;

    my @diff;

    my $create = $producer->can('create_view');
    my $alter  = $producer->can('alter_view');
    my $drop   = $producer->can('drop_view');

    return unless $create && $alter && $drop;

    foreach my $view (@{$self->views_to_create}) {
        push(@diff, $create->($view, { no_comments => 1 }));
    }

    foreach my $view (@{$self->views_to_alter}) {
        push(@diff, $alter->($view));
    }

    foreach my $view (@{$self->views_to_drop}) {
        push(@diff, $drop->($view));
    }

    return @diff;
}


1;
