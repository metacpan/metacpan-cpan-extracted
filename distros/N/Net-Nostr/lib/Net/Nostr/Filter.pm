package Net::Nostr::Filter;

use strictures 2;

use Carp qw(croak);

my @SCALAR_FIELDS  = qw(since until limit search);
my @LIST_FIELDS    = qw(ids authors kinds);
my %HEX64_REQUIRED = map { $_ => 1 } qw(ids authors e p);

sub _validate_hex64 {
    my ($field, $values) = @_;
    for my $v (@$values) {
        croak "$field: '$v' is not 64-char lowercase hex"
            unless $v =~ /^[0-9a-f]{64}$/;
    }
}

sub _validate_kinds {
    my ($values) = @_;
    for my $v (@$values) {
        croak "kinds: '$v' is not a valid kind (integer 0-65535)"
            unless defined $v && $v =~ /^\d+$/ && $v >= 0 && $v <= 65535;
    }
}

sub _validate_non_negative_int {
    my ($field, $value) = @_;
    croak "$field must be a non-negative integer"
        unless defined $value && $value =~ /^\d+$/;
}

use Class::Tiny qw(since until limit search _tag_filters);

# Read-only accessors for list fields that return shallow copies.
for my $field (@LIST_FIELDS) {
    no strict 'refs';
    *$field = sub {
        my $self = shift;
        croak "$field is read-only" if @_;
        return defined $self->{$field} ? [@{$self->{$field}}] : undef;
    };
}

sub new {
    my $class = shift;
    my %args = @_;
    {
        my %known = map { $_ => 1 } (@SCALAR_FIELDS, @LIST_FIELDS);
        my @unknown = grep { !$known{$_} && !/^#[a-zA-Z]$/ } keys %args;
        croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    }
    my $self = bless {}, $class;

    for my $f (@SCALAR_FIELDS) {
        if (exists $args{$f}) {
            _validate_non_negative_int($f, $args{$f})
                if $f eq 'since' || $f eq 'until' || $f eq 'limit';
            croak "search must be a string" if $f eq 'search' && ref($args{$f});
            $self->$f($args{$f});
            # Pre-parse and lowercase search terms for O(1) matching
            if ($f eq 'search' && defined $args{$f} && length $args{$f}) {
                my $parsed = $self->parse_search_extensions($args{$f});
                $self->{_search_terms} = [map { lc($_) } @{$parsed->{terms}}];
            }
        }
    }
    for my $f (@LIST_FIELDS) {
        if (exists $args{$f}) {
            croak "$f must be a non-empty array"
                unless ref($args{$f}) eq 'ARRAY' && @{$args{$f}};
            _validate_hex64($f, $args{$f}) if $HEX64_REQUIRED{$f};
            _validate_kinds($args{$f}) if $f eq 'kinds';
            $self->{$f} = [@{$args{$f}}];
            # Pre-build hash set for O(1) matching
            $self->{"_${f}_set"} = { map { $_ => 1 } @{$args{$f}} };
        }
    }

    # extract #<letter> tag filters
    my %tf;
    for my $k (keys %args) {
        if ($k =~ /^#([a-zA-Z])$/) {
            croak "$k must be a non-empty array"
                unless ref($args{$k}) eq 'ARRAY' && @{$args{$k}};
            _validate_hex64("#$1", $args{$k}) if $HEX64_REQUIRED{$1};
            $tf{$1} = [@{$args{$k}}];
        }
    }
    $self->_tag_filters(\%tf) if %tf;

    return $self;
}

sub tag_filter {
    my ($self, $letter) = @_;
    my $tf = $self->_tag_filters;
    return ($tf && $tf->{$letter}) ? [@{$tf->{$letter}}] : undef;
}

sub matches {
    my ($self, $event) = @_;

    if ($self->{_ids_set}) {
        return 0 unless $self->{_ids_set}{$event->id};
    }

    if ($self->{_authors_set}) {
        return 0 unless $self->{_authors_set}{$event->pubkey};
    }

    if ($self->{_kinds_set}) {
        return 0 unless $self->{_kinds_set}{$event->kind};
    }

    if (defined $self->{since}) {
        return 0 unless $event->created_at >= $self->{since};
    }

    if (defined $self->{until}) {
        return 0 unless $event->created_at <= $self->{until};
    }

    if ($self->{_search_terms} && @{$self->{_search_terms}}) {
        my $content = lc($event->content // '');
        for my $term (@{$self->{_search_terms}}) {
            return 0 unless index($content, $term) >= 0;
        }
    }

    if ($self->{_tag_filters}) {
        for my $letter (keys %{ $self->{_tag_filters} }) {
            my $filter_values = $self->{_tag_filters}{$letter};
            # Build hash set of event's tag values for this letter
            my %event_vals;
            for my $tag (@{ $event->_tags }) {
                $event_vals{$tag->[1]} = 1 if $tag->[0] eq $letter;
            }
            my $found = 0;
            for my $fv (@$filter_values) {
                if ($event_vals{$fv}) {
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

sub parse_search_extensions {
    my ($class, $search_str) = @_;
    my (@terms, %extensions);
    return { terms => \@terms, extensions => \%extensions }
        unless defined $search_str && length $search_str;

    for my $word (split /\s+/, $search_str) {
        next unless length $word;
        if ($word =~ /^([a-zA-Z_]+):(.+)$/) {
            $extensions{$1} = $2;
        } else {
            push @terms, $word;
        }
    }
    return { terms => \@terms, extensions => \%extensions };
}

sub to_hash {
    my ($self) = @_;
    my %h;

    for my $f (@LIST_FIELDS) {
        $h{$f} = [@{$self->{$f}}] if defined $self->{$f};
    }
    for my $f (@SCALAR_FIELDS) {
        my $val = $self->$f;
        $h{$f} = $val if defined $val;
    }

    if ($self->_tag_filters) {
        for my $letter (keys %{ $self->_tag_filters }) {
            $h{"#$letter"} = [@{$self->_tag_filters->{$letter}}];
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

Implements Nostr event filtering as defined by NIP-01, with NIP-50 search
support. All conditions within a single filter are AND-ed together. Multiple
filters in a subscription are OR-ed (use C<matches_any>).

=head1 CONSTRUCTOR

=head2 new

    my $filter = Net::Nostr::Filter->new(
        ids     => ['a' x 64],
        authors => ['b' x 64],
        kinds   => [1, 2],
        since   => 1673361254,
        until   => 1673361999,
        limit   => 100,
        search  => 'best nostr apps',
        '#e'    => ['c' x 64],
        '#p'    => ['d' x 64],
        '#t'    => ['nostr'],
    );

All fields are optional. C<ids>, C<authors>, C<#e>, and C<#p> values must
be 64-character lowercase hex strings. C<kinds> values must be integers
between 0 and 65535. C<since>, C<until>, and C<limit> must be non-negative
integers. C<search> must be a plain string (not a reference). Croaks on
invalid values or unknown arguments.

The C<search> field (NIP-50) is a human-readable query string. It may
contain C<key:value> extension pairs (e.g. C<language:en>). See
L</parse_search_extensions>.

=head1 METHODS

=head2 matches

    my $bool = $filter->matches($event);

Returns true if the event matches all conditions in this filter.
When C<search> is set, performs case-insensitive matching of all search terms
against the event's C<content> field. Extension pairs (C<key:value>) in the
search string are ignored for client-side matching.

    my $filter = Net::Nostr::Filter->new(kinds => [1], since => 1000);
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => '',
        created_at => 2000, tags => [],
    );
    say $filter->matches($event);  # 1

    # NIP-50: search matching
    my $search_filter = Net::Nostr::Filter->new(search => 'nostr apps');
    my $note = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => 'best nostr apps for daily use',
        created_at => 1000, tags => [],
    );
    say $search_filter->matches($note);  # 1

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

Event id prefixes to match. Events whose id starts with any of these
hex strings are included.

=head2 authors

    my $authors = $filter->authors;  # arrayref or undef

Pubkey prefixes to match. Events whose pubkey starts with any of these
hex strings are included.

=head2 kinds

    my $kinds = $filter->kinds;  # arrayref or undef

Event kinds to match. Events with any of these kinds are included.

=head2 since

    my $since = $filter->since;  # Unix timestamp or undef

Lower bound (inclusive) on C<created_at>.

=head2 until

    my $until = $filter->until;  # Unix timestamp or undef

Upper bound (inclusive) on C<created_at>.

=head2 limit

    my $limit = $filter->limit;  # integer or undef

Maximum number of events to return. Applied after sorting by C<created_at>
descending.

=head2 search

    my $search = $filter->search;  # string or undef

NIP-50 search query string. See L</parse_search_extensions> for parsing
extension pairs from the search string.

=head2 parse_search_extensions

    my $result = Net::Nostr::Filter->parse_search_extensions(
        'best nostr apps language:en nsfw:false'
    );
    # $result->{terms}      = ['best', 'nostr', 'apps']
    # $result->{extensions} = { language => 'en', nsfw => 'false' }

Class method. Parses a NIP-50 search string and separates plain search terms
from C<key:value> extension pairs. Returns a hashref with C<terms> (arrayref)
and C<extensions> (hashref).

Supported extensions defined by NIP-50: C<include:spam>, C<domain:E<lt>domainE<gt>>,
C<language:E<lt>codeE<gt>>, C<sentiment:E<lt>valueE<gt>>, C<nsfw:E<lt>boolE<gt>>.

=head1 SEE ALSO

L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md>,
L<NIP-50|https://github.com/nostr-protocol/nips/blob/master/50.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
