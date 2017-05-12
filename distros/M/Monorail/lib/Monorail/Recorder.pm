package Monorail::Recorder;
$Monorail::Recorder::VERSION = '0.4';
use Moose;
use DBIx::Class::Schema;
use SQL::Translator;
use Monorail::SQLTrans::Diff;

our $TableName = 'monorail_deployed_migrations';

has dbix => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has version_resultset => (
    is       => 'ro',
    isa      => 'DBIx::Class::ResultSet',
    lazy     => 1,
    builder  => '_build_version_resultset'
);

has version_resultset_name => (
    is      => 'ro',
    isa     => 'Str',
    default => '__monorail_migrations'
);


has _table_is_present => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has protodbix => (
    is      => 'ro',
    isa     => 'DBIx::Class::Schema',
    lazy    => 1,
    builder => '_build_protodbix',
);


sub is_applied {
    my ($self, $name) = @_;

    $self->_ensure_our_table;

    if ($self->version_resultset->single({name => $name})) {
        return 1;
    }
    else {
        return;
    }
}

sub mark_as_applied {
    my ($self, $name) = @_;

    $self->_ensure_our_table;

    $self->version_resultset->create({
        name => $name
    });
}


sub _build_version_resultset {
    my ($self) = @_;

    return $self->protodbix->resultset($self->version_resultset_name);
}

sub _ensure_our_table {
    my ($self) = @_;

    return if $self->_table_is_present;

    $self->protodbix->txn_do(sub {
        $self->protodbix->storage->ensure_connected;
        $self->protodbix->svp_begin;

        my $has_table = eval { $self->version_resultset->first; 1 };

        $self->protodbix->svp_rollback;

        if (!$has_table) {
            $self->protodbix->deploy;
        }
    });

    $self->_table_is_present(1);
}


sub _build_protodbix {
    my ($self) = @_;

    my $dbix = DBIx::Class::Schema->connect(sub { $self->dbix->storage->dbh });

    require Monorail::Recorder::monorail_resultset;

    $dbix->register_class($self->version_resultset_name => 'Monorail::Recorder::monorail_resultset');

    return $dbix;
}


__PACKAGE__->meta->make_immutable;


1;
__END__
