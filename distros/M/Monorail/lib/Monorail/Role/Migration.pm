package Monorail::Role::Migration;
$Monorail::Role::Migration::VERSION = '0.4';
use Moose::Role;
use Module::Find;

usesub Monorail::Change;

requires qw/dependencies upgrade_steps downgrade_steps/;

has dbix     => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);


=head1 NAME

Monorail::Role::Migration

=head1 VERSION

version 0.4

=head1 DESCRIPTION

This role specifies the requirements for a monorail migration.  A monorail
migratation needs to define three methods.

=over 4

=item dependencies

This method returns an array reference containing the names of all the
migrations that need to run before this migration can be run.  Usually this is
not an extensive list, only a list of migrations needed to walk the entire tree
of existing migrations.

=item upgrade_steps

Returns an array reference of monorail change objects.  The migration is the sum
of these changes.

=item downgrade_steps

Returns an array reference of monorail change object.  These changes are the
logical inverse of the upgrade_steps

=back

This results in a migration script that looks something like:

    use Moose;
    with 'Monorail::Role::Migration';

    sub dependencies { return [qw/other migrations/]}

    sub upgrade_steps {
        return [
            Monorail::Change::AddField->new(...)
        ]
    }

    sub downgrade_steps {
        return [
            Monorail::Change::DropField->new(...)
        ]
    }

=cut

sub upgrade {
    my ($self, $db_type) = @_;

    my $dbix      = $self->dbix;
    my $txn_guard = $dbix->txn_scope_guard;

    my @changes = @{$self->upgrade_steps};

    foreach my $change (@changes) {
        $change->db_type($db_type);

        $change->transform_database($dbix);
    }

    $txn_guard->commit;
}

sub downgrade {
    my ($self, $db_type) = @_;

    my $dbix      = $self->dbix;
    my $txn_guard = $dbix->txn_scope_guard;

    my @changes = @{$self->downgrade_steps};
    foreach my $change (@changes) {
        $change->db_type($db_type);

        $change->transform_database($dbix)
    }

    $txn_guard->commit;
}

1;
