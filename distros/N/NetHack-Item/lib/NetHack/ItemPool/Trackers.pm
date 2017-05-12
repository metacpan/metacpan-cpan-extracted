package NetHack::ItemPool::Trackers;
{
  $NetHack::ItemPool::Trackers::VERSION = '0.21';
}
use Moose;
with 'NetHack::ItemPool::Role::HasPool';

use NetHack::ItemPool::Tracker;
use NetHack::Item::Spoiler;

use constant tracker_class => 'NetHack::ItemPool::Tracker';
use constant spoiler_class => 'NetHack::Item::Spoiler';

has _trackers => (
    traits     => ['Hash'],
    is         => 'ro',
    isa        => 'HashRef[NetHack::ItemPool::Tracker]',
    lazy       => 1,
    builder    => '_build_trackers',
    handles    => {
        trackers    => 'values',
        get_tracker => 'get',
    },
);

has _trackers_by_type => (
    is         => 'ro',
    isa        => 'HashRef[ArrayRef[NetHack::ItemPool::Tracker]]',
    lazy       => 1,
    builder    => '_build_trackers_by_type',
);

has '+pool' => (
    required => 1,
);

sub _appearances_to_possibilities {
    my $self = shift;
    my $mapping = {};

    for my $spoiler ($self->spoiler_class->spoiler_types) {
        my $list = $spoiler->list;
        for my $identity (keys %$list) {
            my $entry = $list->{$identity};

            next if $entry->{artifact};

            my @appearances = grep { defined }
                              $entry->{appearance},
                              @{ $entry->{appearances} || [] };

            for my $appearance (@appearances) {
                push @{ $mapping->{$appearance} }, $identity;
            }
        }
    }

    # now delete the obvious ones, and sort the others
    for my $appearance (keys %$mapping) {
        if (@{ $mapping->{$appearance} } == 1) {
            delete $mapping->{$appearance};
        }
        else {
            @{ $mapping->{$appearance} } = sort @{ $mapping->{$appearance} };
        }
    }

    return $mapping;
}

sub _build_trackers {
    my $self = shift;
    my $trackers = {};

    my $tracker_class = $self->tracker_class;
    my $spoiler_class = $self->spoiler_class;
    my $pool = $self->pool;

    my $possibility_mapping = $self->_appearances_to_possibilities;
    for my $appearance (keys %$possibility_mapping) {
        my $all_possibilities = $possibility_mapping->{$appearance};
        my $type    = $spoiler_class->collapse_value('type', @$all_possibilities);
        my $subtype = $spoiler_class->collapse_value('subtype', @$all_possibilities);

        my $tracker = $tracker_class->new(
            appearance        => $appearance,
            type              => $type,
            all_possibilities => $all_possibilities,
            (defined $subtype ? (subtype => $subtype) : ()),
            pool              => $pool,
        );

        $trackers->{$appearance} = $tracker;
    }

    return $trackers;
}

sub _build_trackers_by_type {
    my $self = shift;
    my %trackers;

    for ($self->trackers) {
        push @{ $trackers{$_->type} }, $_;
    }

    return \%trackers;
}

sub possible_appearances_of {
    my $self     = shift;
    my $identity = shift;

    my $type = $self->spoiler_class->name_to_type($identity);
    confess "Unknown item '$identity'" if !$type;

    my @appearances;

    for my $tracker (@{ $self->_trackers_by_type->{$type} }) {
        push @appearances, $tracker->appearance
            if $tracker->includes_possibility($identity);
    }

    return @appearances;
}

sub tracker_for {
    my $self = shift;
    my $item = shift;

    return if !$item->has_appearance;
    return $self->get_tracker($item->appearance);
}

sub identified {
    my $self     = shift;
    my $tracker  = shift;
    my $identity = shift;

    for my $foo ($self->trackers) {
        next if $tracker == $foo;
        $foo->rule_out($identity) if $foo->includes_possibility($identity);
    }
}

sub ruled_out {}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

