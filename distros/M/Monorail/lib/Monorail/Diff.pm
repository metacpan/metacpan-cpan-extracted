package Monorail::Diff;
$Monorail::Diff::VERSION = '0.4';
use Moose;
use namespace::autoclean;
use Clone qw(clone);
use Monorail::SQLTrans::Diff;

has source_schema => (
    is       => 'ro',
    isa      => 'SQL::Translator::Schema',
    required => 1,
);

has target_schema => (
    is       => 'ro',
    isa      => 'SQL::Translator::Schema',
    required => 1,
);

has upgrade_changes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_upgrade_changes',
);

has downgrade_changes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_downgrade_changes',
);

has forward_diff => (
    is      => 'ro',
    isa     => 'Monorail::SQLTrans::Diff',
    lazy    => 1,
    builder => '_build_forward_diff'
);

has reversed_diff => (
    is      => 'ro',
    isa     => 'Monorail::SQLTrans::Diff',
    lazy    => 1,
    builder => '_build_reversed_diff'
);

has output_db => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Monorail',
);

sub has_changes {
    my ($self) = @_;

    return scalar @{$self->upgrade_changes};
}

sub _build_upgrade_changes {
    my ($self) = @_;

    my @changes = $self->forward_diff->produce_diff_sql;
    @changes    = $self->_munge_changes_strings(@changes);

    return \@changes;
}

sub _build_downgrade_changes {
    my ($self) = @_;

    #use Data::Dumper;
    #die Dumper($self->reversed_diff);

    my @changes = $self->reversed_diff->produce_diff_sql;
    @changes    = $self->_munge_changes_strings(@changes);

    return \@changes;
}

sub _munge_changes_strings {
    my ($self, @changes) = @_;

    @changes = grep { m/^Monorail::/ } @changes;
    for (@changes) {
        s/;\s+$//s;
        s/^/        /mg;
    }

    return @changes;
}

sub _build_forward_diff {
    my ($self) = @_;

    my $src = clone($self->source_schema);
    my $tar = clone($self->target_schema);

    $self->_strip_irrelevent_rename_mappings($src, $tar);

    return Monorail::SQLTrans::Diff->new({
        output_db              => $self->output_db,
        source_schema          => $src,
        target_schema          => $tar,
    })->compute_differences;
}

sub _build_reversed_diff {
    my ($self) = @_;

    my $src = clone($self->source_schema);
    my $tar = clone($self->target_schema);

    $self->_strip_irrelevent_rename_mappings($src, $tar);
    $self->_add_reversed_rename_mappings($src, $tar);

    return Monorail::SQLTrans::Diff->new({
        output_db     => $self->output_db,
        # note these are reversed
        source_schema => $tar,
        target_schema => $src,
    })->compute_differences;
}


sub _add_reversed_rename_mappings {
    my ($self, $from, $to) = @_;

    foreach my $table ($to->get_tables) {
        if (my $old_name = $table->extra('renamed_from')) {
            my $old_table = $from->get_table($old_name);
            $old_table->extra(renamed_from => $table->name);

            foreach my $field ($table->get_fields) {
                if (my $old_field_name = $field->extra('renamed_from')) {
                    my $old_field = $old_table->get_field($old_field_name);
                    $old_field->extra(renamed_from => $field->name);
                }
            }

        }
    }
}

{
    my $do_strip = sub {
        my ($from, $to) = @_;

        my %to_tables = map { $_->name => $_ } $to->get_tables;

        foreach my $table ($from->get_tables) {
            if (my $old_name = $table->extra('renamed_from')) {
                if (!$to_tables{$old_name}) {
                    $table->remove_extra('renamed_from');
                }
            }

            FIELD: foreach my $field ($table->get_fields) {
                my $renamed_from = $field->extra('renamed_from');

                next unless $renamed_from;

                my $other_table = $to_tables{$table->extra('renamed_from') || $table->name} || next FIELD;
                if (!$other_table->get_field($renamed_from)) {
                    $field->remove_extra('renamed_from');
                }
            }
        }
    };

    sub _strip_irrelevent_rename_mappings {
        my ($self, $from_schema, $to_schema) = @_;

        $do_strip->($from_schema, $to_schema);
        $do_strip->($to_schema,   $from_schema);
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
