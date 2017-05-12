package NetHack::ItemPool::Tracker;
{
  $NetHack::ItemPool::Tracker::VERSION = '0.21';
}
use Moose;
use Set::Object;
use NetHack::Item::Spoiler;
with 'NetHack::ItemPool::Role::HasPool';

use Module::Pluggable (
    search_path => __PACKAGE__,
    require     => 1,
    sub_name    => 'tracker_types',
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has subtype => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_subtype',
);

has appearance => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '+pool' => (
    required => 1,
    handles  => [qw/trackers/],
);

has possibilities => (
    isa      => 'Set::Object',
    required => 1,
    handles  => {
        _possibilities       => 'members',
        rule_out             => 'remove',
        includes_possibility => 'includes',
    },
);

has _all_possibilities => (
    is       => 'ro',
    init_arg => 'all_possibilities',
    isa      => 'Set::Object',
    required => 1,
);

sub BUILD {
    my $self = shift;

    my $class = __PACKAGE__ . '::' . ucfirst($self->type);
    Class::MOP::load_class($class);
    $class->meta->rebless_instance($self);
}

around BUILDARGS => sub {
    my $orig = shift;
    my $args = $orig->(@_);

    $args->{all_possibilities} = Set::Object->new(@{ $args->{all_possibilities} });
    $args->{possibilities} = Set::Object->new(@{ $args->{all_possibilities} });

    return $args;
};

sub possibilities {
    my @possibilities = shift->_possibilities;
    return @possibilities if !wantarray;
    return sort @possibilities;
}

sub identify_as {
    my $self     = shift;
    my $identity = shift;

    confess "$identity is not a possibility for " . $self->appearance
        unless $self->includes_possibility($identity);

    $self->rule_out(grep { $_ ne $identity } $self->possibilities);
}

sub rule_out_all_but {
    my $self = shift;
    my %include = map { $_ => 1 } @_;

    for ($self->possibilities) {
        $self->rule_out($_) unless $include{$_};
    }
}

around rule_out => sub {
    my $orig = shift;
    my $self = shift;

    for my $possibility (@_) {
        next if $self->_all_possibilities->includes($possibility);
        confess "$possibility is not included in " . $self->appearance . "'s set of all possibilities.";
    }

    $self->$orig(@_);

    for my $possibility (@_) {
        $self->trackers->ruled_out($self => $possibility);
    }

    if ($self->possibilities == 1) {
        $self->trackers->identified($self => $self->possibilities);
    }
    elsif ($self->possibilities == 0) {
        confess "Ruled out all possibilities for " . $self->appearance . "!";
    }
};

sub priceid_useful {
    my $self = shift;
    my %seen_prices;

    for my $possibility ($self->possibilities) {
        my $spoiler = NetHack::Item::Spoiler->spoiler_for($possibility);
        my $price = $spoiler->{price} || 0;

        $seen_prices{ $price }++;

        if (keys %seen_prices >= 2) {
            return 1;
        }
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
no Moose;

# need to delay this until after this class is already immutable, or else the
# subclasses get broken constructors
__PACKAGE__->tracker_types; # load all

1;

