package NetHack::ItemPool;
{
  $NetHack::ItemPool::VERSION = '0.21';
}
use Moose;

use NetHack::Item;
use NetHack::Inventory;
use NetHack::ItemPool::Trackers;

use constant item_class      => 'NetHack::Item';
use constant inventory_class => 'NetHack::Inventory';
use constant trackers_class  => 'NetHack::ItemPool::Trackers';

has fruit_name => (
    is      => 'ro',
    isa     => 'Str',
    default => 'slime mold',
);

has fruit_plural => (
    is      => 'ro',
    isa     => 'Str',
    default => 'slime molds',
);

has artifacts => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has inventory => (
    is      => 'ro',
    isa     => 'NetHack::Inventory',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->inventory_class->new(
            pool => $self,
        )
    },
);

has trackers => (
    is      => 'ro',
    isa     => 'NetHack::ItemPool::Trackers',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->trackers_class->new(
            pool => $self,
        )
    },
    handles => [qw/tracker_for possible_appearances_of/],
);

sub _create_item {
    my $self = shift;

    unshift @_, 'raw' if @_ == 1;
    return $self->item_class->new(@_, pool => $self);
}

sub new_item {
    my $self = shift;

    my $item = $self->_create_item(@_);

    if ($item->is_artifact) {
        if (my $existing_arti = $self->get_artifact($item->artifact)) {
            $existing_arti->incorporate_stats_from($item);
            $item = $existing_arti;
        }
        else {
            $self->incorporate_artifact($item);
        }
    }

    if ($item->has_appearance && (my $tracker = $self->tracker_for($item))) {
        $item->_set_tracker($tracker);
    }

    return $item;
}

sub get_artifact {
    my $self = shift;
    my $name = shift;

    return $self->artifacts->{$name};
}

sub incorporate_artifact {
    my $self = shift;
    my $item = shift;

    return if $self->artifacts->{ $item->artifact };
    $self->artifacts->{ $item->artifact } = $item;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

NetHack::ItemPool - represents a universe of NetHack items

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    use NetHack::ItemPool;
    my $pool = NetHack::ItemPool->new;
    my $excalibur = $pool->new_item("the +3 Excalibur (weapon in hand)");
    is($pool->inventory->weapon, $excalibur);

=head1 DESCRIPTION

Objects of this class represent a universe of NetHack items. For example, each
instance of this class gets exactly one Magicbane, because each NetHack game
gets exactly one Magicbane.

An ItemPool also manages inventory (L<NetHack::Inventory>) and
equipment (L<NetHack::Inventory::Equipment>) for you.

More documentation to come. For now, the best resource is this module's test
suite.

=cut
