package Monorail::SQLTrans::ProducerProxy;
$Monorail::SQLTrans::ProducerProxy::VERSION = '0.4';
use Moose;
use Module::Runtime qw(require_module);
use namespace::autoclean;

has db_type => (
    is      => 'ro',
    isa     => 'Str',
    default => 'PostgreSQL'
);

has producer_class => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_producer_class',
);


my %overrides = (
    PostgreSQL => 'Monorail::SQLTrans::Producer::PostgreSQL',
);

sub _build_producer_class {
    my ($self) = @_;

    my $class = $overrides{$self->db_type} || 'SQL::Translator::Producer::' . $self->db_type;

    require_module($class);

    return $class;
}

my @methods = qw/
    add_field create_table drop_field drop_table alter_field
    alter_create_constraint alter_drop_constraint alter_create_index rename_table
    create_view drop_view alter_view
/;

foreach my $meth (@methods) {
    __PACKAGE__->meta->add_method(
        $meth => sub {
            my $self = shift;
            my $implementation = $self->producer_class->can($meth)
                                || die sprintf("%s can't %s\n", $self->producer_class, $meth);
            return $implementation->(@_);
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
