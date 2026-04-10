package Net::Nostr::Label;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    namespaces
    labels
    targets
);

my %TARGET_TAGS = map { $_ => 1 } qw(e p a r t);

sub new {
    my $class = shift;
    my %args = @_;
    $args{namespaces} //= [];
    $args{labels}     //= [];
    $args{targets}    //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub namespace_tag {
    my ($class, $namespace) = @_;
    return ['L', $namespace];
}

sub label_tag {
    my ($class, $value, $namespace) = @_;
    return defined $namespace
        ? ['l', $value, $namespace]
        : ['l', $value];
}

sub label {
    my ($class, %args) = @_;

    my $pubkey    = $args{pubkey}    // croak "label requires 'pubkey'";
    my $labels    = $args{labels}    // croak "label requires 'labels'";
    my $targets   = $args{targets};
    my $namespace = $args{namespace};

    croak "label requires at least one target tag"
        unless $targets && @$targets;

    my @tags;

    if (defined $namespace) {
        push @tags, ['L', $namespace];
        for my $val (@$labels) {
            push @tags, ['l', $val, $namespace];
        }
    } else {
        for my $val (@$labels) {
            push @tags, ['l', $val];
        }
    }

    push @tags, @$targets;

    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1985,
        content => $args{content} // '',
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;

    my @namespaces;
    my @labels;
    my @targets;

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'L') {
            push @namespaces, $tag->[1];
        } elsif ($tag->[0] eq 'l') {
            my @entry = ($tag->[1]);
            push @entry, $tag->[2] if defined $tag->[2];
            push @labels, \@entry;
        } elsif ($TARGET_TAGS{$tag->[0]}) {
            push @targets, $tag;
        }
    }

    return $class->new(
        namespaces => \@namespaces,
        labels     => \@labels,
        targets    => \@targets,
    );
}

sub labels_for {
    my ($self, $namespace) = @_;
    my @result;
    for my $label (@{$self->labels}) {
        if (defined $label->[1] && $label->[1] eq $namespace) {
            push @result, $label->[0];
        }
    }
    return @result;
}

sub has_label {
    my ($self, $value, $namespace) = @_;
    for my $label (@{$self->labels}) {
        if ($label->[0] eq $value) {
            if (defined $namespace) {
                return 1 if defined $label->[1] && $label->[1] eq $namespace;
            } else {
                return 1;
            }
        }
    }
    return 0;
}

sub validate {
    my ($class, $event) = @_;

    croak "label event must be kind 1985"
        unless $event->kind == 1985;

    my $has_target = 0;
    my %L_namespaces;
    my @l_marks;

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'L') {
            $L_namespaces{$tag->[1]} = 1;
        } elsif ($tag->[0] eq 'l' && defined $tag->[2]) {
            push @l_marks, $tag->[2];
        } elsif ($TARGET_TAGS{$tag->[0]}) {
            $has_target = 1;
        }
    }

    croak "label event MUST include at least one target tag (e, p, a, r, or t)"
        unless $has_target;

    if (%L_namespaces) {
        for my $mark (@l_marks) {
            croak "l tag mark '$mark' does not match any L namespace"
                unless $L_namespaces{$mark};
        }
    }

    return 1;
}

sub label_filter {
    my ($class, %args) = @_;

    my %filter = (kinds => [1985]);

    $filter{'#L'} = [$args{namespace}] if defined $args{namespace};
    $filter{'#l'} = $args{labels}      if $args{labels};
    $filter{authors} = $args{authors}  if $args{authors};

    return \%filter;
}

1;

__END__


=head1 NAME

Net::Nostr::Label - NIP-32 Labeling

=head1 SYNOPSIS

    use Net::Nostr::Label;

    # Create a kind 1985 label event
    my $event = Net::Nostr::Label->label(
        pubkey    => $pubkey,
        namespace => 'com.example.ontology',
        labels    => ['VI-hum'],
        targets   => [['p', $target_pk, $relay]],
        content   => 'Explanation of the label',
    );

    # Build tags for self-reporting on any event
    my $L = Net::Nostr::Label->namespace_tag('ISO-639-1');
    my $l = Net::Nostr::Label->label_tag('en', 'ISO-639-1');

    # Parse labels from an event
    my $info = Net::Nostr::Label->from_event($event);
    my @namespaces = @{$info->namespaces};
    my @labels     = @{$info->labels};
    my @en_labels  = $info->labels_for('ISO-639-1');

    # Check for a specific label
    if ($info->has_label('MIT', 'license')) { ... }

    # Build a subscription filter
    my $filter = Net::Nostr::Label->label_filter(
        namespace => 'license',
        labels    => ['MIT'],
    );

=head1 CONSTRUCTOR

=head2 new

    my $label = Net::Nostr::Label->new(
        namespaces => ['ISO-639-1'],
        labels     => [['en', 'ISO-639-1']],
        targets    => [['e', $event_id, $relay]],
    );

Creates a new label object. C<namespaces>, C<labels>, and C<targets>
all default to C<[]>. Croaks on unknown arguments.

=head1 DESCRIPTION

Implements NIP-32 (Labeling). Provides methods to create kind 1985 label
events, build L/l tags for self-reporting, parse labels from events, and
build subscription filters.

=head2 label

    my $event = Net::Nostr::Label->label(
        pubkey    => $pubkey,
        namespace => 'license',
        labels    => ['MIT'],
        targets   => [['e', $event_id, $relay]],
        content   => 'optional explanation',
    );

Creates a kind 1985 label event. C<namespace> is optional; if omitted, the
C<ugc> namespace is implied and no L tag is emitted. C<targets> must include
at least one C<e>, C<p>, C<a>, C<r>, or C<t> tag.

=head2 namespace_tag

    my $tag = Net::Nostr::Label->namespace_tag('ISO-639-1');
    # ['L', 'ISO-639-1']

Returns an L tag arrayref. Use when building tags for self-reporting on
non-1985 events.

=head2 label_tag

    my $tag = Net::Nostr::Label->label_tag('en', 'ISO-639-1');
    # ['l', 'en', 'ISO-639-1']

    my $tag = Net::Nostr::Label->label_tag('spam');
    # ['l', 'spam']

Returns an l tag arrayref. The namespace mark is optional; if omitted,
C<ugc> is implied.

=head2 from_event

    my $info = Net::Nostr::Label->from_event($event);
    my @ns     = @{$info->namespaces};  # L tag values
    my @labels = @{$info->labels};      # [value, mark?] pairs
    my @targets = @{$info->targets};    # target tags

Parses label information from any event (kind 1985 or self-reported).
Returns a L<Net::Nostr::Label> object with accessors for C<namespaces>,
C<labels>, and C<targets>.

=head2 labels_for

    my @values = $info->labels_for('ISO-639-1');

Returns label values for a specific namespace.

=head2 has_label

    if ($info->has_label('MIT', 'license')) { ... }
    if ($info->has_label('spam')) { ... }

Returns true if the label set contains the given value, optionally within
the specified namespace.

=head2 validate

    Net::Nostr::Label->validate($event);

Validates a kind 1985 label event. Croaks if the event is not kind 1985,
has no target tags, or has l tag marks that don't match any L namespace.

=head2 label_filter

    my $filter = Net::Nostr::Label->label_filter(
        namespace => 'license',
        labels    => ['MIT', 'GPL'],
        authors   => [$pubkey],
    );

Returns a subscription filter hashref for querying label events. All
parameters are optional.

=head1 ACCESSORS

=head2 namespaces

Arrayref of L tag values (namespace strings).

=head2 labels

Arrayref of C<[value, namespace?]> pairs from l tags.

=head2 targets

Arrayref of target tags (C<e>, C<p>, C<a>, C<r>, or C<t> tags).

=head1 SEE ALSO

L<NIP-32|https://github.com/nostr-protocol/nips/blob/master/32.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
