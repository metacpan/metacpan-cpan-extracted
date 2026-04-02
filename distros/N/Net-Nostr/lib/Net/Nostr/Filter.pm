package Net::Nostr::Filter;

use strictures 2;

use Carp qw(croak);

my @SCALAR_FIELDS  = qw(since until limit);
my @LIST_FIELDS    = qw(ids authors kinds);
my %HEX64_REQUIRED = map { $_ => 1 } qw(ids authors e p);

sub _validate_hex64 {
    my ($field, $values) = @_;
    for my $v (@$values) {
        croak "$field: '$v' is not 64-char lowercase hex"
            unless $v =~ /^[0-9a-f]{64}$/;
    }
}

use Class::Tiny qw(ids authors kinds since until limit _tag_filters);

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {}, $class;

    for my $f (@SCALAR_FIELDS) {
        $self->$f($args{$f}) if exists $args{$f};
    }
    for my $f (@LIST_FIELDS) {
        if (exists $args{$f}) {
            _validate_hex64($f, $args{$f}) if $HEX64_REQUIRED{$f};
            $self->$f($args{$f});
        }
    }

    # extract #<letter> tag filters
    for my $k (keys %args) {
        if ($k =~ /^#([a-zA-Z])$/) {
            _validate_hex64("#$1", $args{$k}) if $HEX64_REQUIRED{$1};
            my $tf = $self->_tag_filters // {};
            $tf->{$1} = $args{$k};
            $self->_tag_filters($tf);
        }
    }

    return $self;
}

sub tag_filter {
    my ($self, $letter) = @_;
    my $tf = $self->_tag_filters;
    return $tf ? $tf->{$letter} : undef;
}

sub matches {
    my ($self, $event) = @_;

    if ($self->ids) {
        my $eid = $event->id;
        return 0 unless grep { $_ eq $eid } @{ $self->ids };
    }

    if ($self->authors) {
        my $pk = $event->pubkey;
        return 0 unless grep { $_ eq $pk } @{ $self->authors };
    }

    if ($self->kinds) {
        my $k = $event->kind;
        return 0 unless grep { $_ == $k } @{ $self->kinds };
    }

    if (defined $self->since) {
        return 0 unless $event->created_at >= $self->since;
    }

    if (defined $self->until) {
        return 0 unless $event->created_at <= $self->until;
    }

    if ($self->_tag_filters) {
        for my $letter (keys %{ $self->_tag_filters }) {
            my $filter_values = $self->_tag_filters->{$letter};
            my @event_tag_values;
            for my $tag (@{ $event->tags }) {
                push @event_tag_values, $tag->[1] if $tag->[0] eq $letter;
            }
            my $found = 0;
            for my $fv (@$filter_values) {
                if (grep { $_ eq $fv } @event_tag_values) {
                    $found = 1;
                    last;
                }
            }
            return 0 unless $found;
        }
    }

    return 1;
}

sub matches_any {
    my ($class, $event, @filters) = @_;
    for my $f (@filters) {
        return 1 if $f->matches($event);
    }
    return 0;
}

sub to_hash {
    my ($self) = @_;
    my %h;

    for my $f (@LIST_FIELDS, @SCALAR_FIELDS) {
        my $val = $self->$f;
        $h{$f} = $val if defined $val;
    }

    if ($self->_tag_filters) {
        for my $letter (keys %{ $self->_tag_filters }) {
            $h{"#$letter"} = $self->_tag_filters->{$letter};
        }
    }

    return \%h;
}

1;

__END__

=head1 NAME

Net::Nostr::Filter - Nostr event filter for subscriptions and queries

=head1 SYNOPSIS

    use Net::Nostr::Filter;

    my $filter = Net::Nostr::Filter->new(
        kinds   => [1],
        authors => ['a' x 64],
        since   => time() - 3600,
        limit   => 50,
    );

    # Check if an event matches
    if ($filter->matches($event)) { ... }

    # Tag filters use #<letter> syntax
    my $filter = Net::Nostr::Filter->new(
        '#t' => ['nostr', 'perl'],
    );

    # Retrieve a tag filter
    my $values = $filter->tag_filter('t');  # ['nostr', 'perl']

    # Multiple filters act as OR conditions
    my $f1 = Net::Nostr::Filter->new(kinds => [1]);
    my $f2 = Net::Nostr::Filter->new(kinds => [0]);
    if (Net::Nostr::Filter->matches_any($event, $f1, $f2)) { ... }

=head1 DESCRIPTION

Implements Nostr event filtering as defined by NIP-01. All conditions within
a single filter are AND-ed together. Multiple filters in a subscription are
OR-ed (use C<matches_any>).

=head1 CONSTRUCTOR

=head2 new

    my $filter = Net::Nostr::Filter->new(
        ids     => ['a' x 64],
        authors => ['b' x 64],
        kinds   => [1, 2],
        since   => 1673361254,
        until   => 1673361999,
        limit   => 100,
        '#e'    => ['c' x 64],
        '#p'    => ['d' x 64],
        '#t'    => ['nostr'],
    );

All fields are optional. C<ids>, C<authors>, C<#e>, and C<#p> values must
be 64-character lowercase hex strings. Croaks on invalid values.

=head1 METHODS

=head2 matches

    my $bool = $filter->matches($event);

Returns true if the event matches all conditions in this filter.

    my $filter = Net::Nostr::Filter->new(kinds => [1], since => 1000);
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => '',
        created_at => 2000, tags => [],
    );
    say $filter->matches($event);  # 1

=head2 matches_any

    my $bool = Net::Nostr::Filter->matches_any($event, @filters);

Class method. Returns true if the event matches any of the given filters
(OR logic).

=head2 tag_filter

    my $values = $filter->tag_filter('t');  # ['nostr'] or undef

Returns the arrayref of values for a tag filter, or C<undef> if that
tag letter was not specified.

=head2 to_hash

    my $hash = $filter->to_hash;
    # { kinds => [1], authors => [...], '#t' => ['nostr'] }

Returns a hashref suitable for JSON encoding in a REQ message. Only
includes fields that were set.

=head2 ids

    my $ids = $filter->ids;  # arrayref or undef

=head2 authors

    my $authors = $filter->authors;  # arrayref or undef

=head2 kinds

    my $kinds = $filter->kinds;  # arrayref or undef

=head2 since

    my $since = $filter->since;  # Unix timestamp or undef

=head2 until

    my $until = $filter->until;  # Unix timestamp or undef

=head2 limit

    my $limit = $filter->limit;  # integer or undef

=head1 SEE ALSO

L<Net::Nostr>, L<Net::Nostr::Event>

=cut
