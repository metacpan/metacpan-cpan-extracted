package Net::Nostr::Wiki;

use strictures 2;
use feature 'unicode_strings';

use Carp qw(croak);
use Net::Nostr::Event;

use constant WIKI_RELAY_LIST_KIND => 10102;

use Class::Tiny qw(
    identifier
    title
    summary
    fork_a
    fork_e
    defer_a
    defer_e
    target
    target_relay
    destination
    source
    source_relay
    base_version
    base_relay
);

my %KINDS = (
    30818 => 'article',
    818   => 'merge_request',
    30819 => 'redirect',
);

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub normalize_dtag {
    my ($class, $str) = @_;

    $str = lc($str);

    # Whitespace to dash
    $str =~ s/\s+/-/g;

    # Remove punctuation and symbols (keep letters, numbers, dashes)
    $str =~ s/[^\p{Letter}\p{Number}\-]//g;

    # Collapse consecutive dashes
    $str =~ s/-{2,}/-/g;

    # Remove leading/trailing dashes
    $str =~ s/^-//;
    $str =~ s/-$//;

    return $str;
}

sub article {
    my ($class, %args) = @_;

    my $pubkey     = delete $args{pubkey}
        // croak "article requires 'pubkey'";
    my $identifier = delete $args{identifier}
        // croak "article requires 'identifier'";
    my $content = delete $args{content}
        // croak "article requires 'content'";
    my $title   = delete $args{title};
    my $summary = delete $args{summary};
    my $fork_a  = delete $args{fork_a};
    my $fork_e  = delete $args{fork_e};
    my $defer_a = delete $args{defer_a};
    my $defer_e = delete $args{defer_e};

    $identifier = $class->normalize_dtag($identifier);

    my @tags;
    push @tags, ['d', $identifier];
    push @tags, ['title', $title]     if defined $title;
    push @tags, ['summary', $summary] if defined $summary;

    if ($fork_a) {
        push @tags, ['a', @$fork_a, 'fork'];
    }
    if ($fork_e) {
        push @tags, ['e', @$fork_e, 'fork'];
    }
    if ($defer_a) {
        push @tags, ['a', @$defer_a, 'defer'];
    }
    if ($defer_e) {
        push @tags, ['e', @$defer_e, 'defer'];
    }

    return Net::Nostr::Event->new(
        %args,
        pubkey  => $pubkey,
        kind    => 30818,
        content => $content,
        tags    => \@tags,
    );
}

sub merge_request {
    my ($class, %args) = @_;

    my $pubkey      = delete $args{pubkey}
        // croak "merge_request requires 'pubkey'";
    my $target      = delete $args{target}
        // croak "merge_request requires 'target'";
    my $source      = delete $args{source}
        // croak "merge_request requires 'source'";
    my $destination = delete $args{destination}
        // croak "merge_request requires 'destination'";

    my $target_relay  = delete $args{target_relay};
    my $base_version  = delete $args{base_version};
    my $base_relay    = delete $args{base_relay};
    my $source_relay  = delete $args{source_relay};
    my $content       = delete $args{content} // '';

    my @tags;

    # a tag: target article
    my @a_tag = ('a', $target);
    push @a_tag, $target_relay if defined $target_relay;
    push @tags, \@a_tag;

    # e tag: base version (optional, no marker)
    if (defined $base_version) {
        my @e_tag = ('e', $base_version);
        push @e_tag, $base_relay if defined $base_relay;
        push @tags, \@e_tag;
    }

    # p tag: destination pubkey
    push @tags, ['p', $destination];

    # e tag: source with "source" marker
    my @source_tag = ('e', $source);
    push @source_tag, ($source_relay // '');
    push @source_tag, 'source';
    push @tags, \@source_tag;

    return Net::Nostr::Event->new(
        %args,
        pubkey  => $pubkey,
        kind    => 818,
        content => $content,
        tags    => \@tags,
    );
}

sub redirect {
    my ($class, %args) = @_;

    my $pubkey     = delete $args{pubkey}
        // croak "redirect requires 'pubkey'";
    my $identifier = delete $args{identifier}
        // croak "redirect requires 'identifier'";
    my $target     = delete $args{target}
        // croak "redirect requires 'target'";
    my $target_relay = delete $args{target_relay};

    $identifier = $class->normalize_dtag($identifier);

    my @tags;
    push @tags, ['d', $identifier];

    my @a_tag = ('a', $target);
    push @a_tag, $target_relay if defined $target_relay;
    push @tags, \@a_tag;

    return Net::Nostr::Event->new(
        %args,
        pubkey  => $pubkey,
        kind    => 30819,
        content => '',
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    return undef unless exists $KINDS{$kind};

    my %attrs;

    if ($kind == 30818) {
        for my $tag (@{$event->tags}) {
            my $t = $tag->[0];
            if    ($t eq 'd')       { $attrs{identifier} = $tag->[1] }
            elsif ($t eq 'title')   { $attrs{title} = $tag->[1] }
            elsif ($t eq 'summary') { $attrs{summary} = $tag->[1] }
            elsif ($t eq 'a') {
                my $marker = $tag->[-1];
                if ($marker eq 'fork') {
                    $attrs{fork_a} = [@{$tag}[1 .. $#$tag - 1]];
                } elsif ($marker eq 'defer') {
                    $attrs{defer_a} = [@{$tag}[1 .. $#$tag - 1]];
                }
            }
            elsif ($t eq 'e') {
                my $marker = $tag->[-1];
                if ($marker eq 'fork') {
                    $attrs{fork_e} = [@{$tag}[1 .. $#$tag - 1]];
                } elsif ($marker eq 'defer') {
                    $attrs{defer_e} = [@{$tag}[1 .. $#$tag - 1]];
                }
            }
        }
    }
    elsif ($kind == 818) {
        for my $tag (@{$event->tags}) {
            my $t = $tag->[0];
            if ($t eq 'a') {
                $attrs{target}       = $tag->[1];
                $attrs{target_relay} = $tag->[2] if defined $tag->[2];
            }
            elsif ($t eq 'e') {
                if (defined $tag->[3] && $tag->[3] eq 'source') {
                    $attrs{source}       = $tag->[1];
                    $attrs{source_relay} = $tag->[2]
                        if defined $tag->[2] && $tag->[2] ne '';
                } else {
                    $attrs{base_version} = $tag->[1];
                    $attrs{base_relay}   = $tag->[2]
                        if defined $tag->[2] && $tag->[2] ne '';
                }
            }
            elsif ($t eq 'p') {
                $attrs{destination} = $tag->[1];
            }
        }
    }
    elsif ($kind == 30819) {
        for my $tag (@{$event->tags}) {
            my $t = $tag->[0];
            if    ($t eq 'd') { $attrs{identifier} = $tag->[1] }
            elsif ($t eq 'a') {
                $attrs{target}       = $tag->[1];
                $attrs{target_relay} = $tag->[2] if defined $tag->[2];
            }
        }
    }

    return $class->new(%attrs);
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    croak "wiki event MUST be kind 30818, 818, or 30819"
        unless exists $KINDS{$kind};

    my (%has, $has_source_e);
    for my $tag (@{$event->tags}) {
        $has{$tag->[0]} = 1;
        $has_source_e = 1
            if $tag->[0] eq 'e' && defined $tag->[3] && $tag->[3] eq 'source';
    }

    if ($kind == 30818) {
        croak "wiki article MUST have a 'd' tag" unless $has{d};
    }

    if ($kind == 818) {
        croak "merge request MUST have an 'a' tag"              unless $has{a};
        croak "merge request MUST have a 'p' tag"               unless $has{p};
        croak "merge request MUST have an 'e' tag with 'source' marker"
            unless $has_source_e;
    }

    if ($kind == 30819) {
        croak "wiki redirect MUST have a 'd' tag" unless $has{d};
        croak "wiki redirect MUST have an 'a' tag" unless $has{a};
    }

    return 1;
}

sub resolve_wikilinks {
    my ($class, $content) = @_;

    # Extract defined references: [label]: target
    my %defined;
    while ($content =~ /^\[([^\]]+)\]:\s*(\S+)/mg) {
        $defined{$1} = $2;
    }

    # Replace [text][Label] style (explicit reference) where Label is not defined
    $content =~ s{
        \[([^\]]+)\]\[([^\]]+)\]
    }{
        if (exists $defined{$2}) {
            "[$1][$2]"  # keep as-is
        } else {
            my $norm = $class->normalize_dtag($2);
            "[$1](nostr:30818:$norm)"
        }
    }gex;

    # Replace [text][] style (implicit reference) where text is not defined
    $content =~ s{
        \[([^\]]+)\]\[\]
    }{
        if (exists $defined{$1}) {
            "[$1][]"  # keep as-is
        } else {
            my $norm = $class->normalize_dtag($1);
            "[$1](nostr:30818:$norm)"
        }
    }gex;

    return $content;
}

1;

__END__


=head1 NAME

Net::Nostr::Wiki - NIP-54 Wiki

=head1 SYNOPSIS

    use Net::Nostr::Wiki;

    # Wiki article (kind 30818)
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $hex_pubkey,
        identifier => 'Wiki Article',
        title      => 'Wiki Article',
        content    => 'A wiki is a hypertext publication.',
    );

    # Merge request (kind 818)
    my $event = Net::Nostr::Wiki->merge_request(
        pubkey       => $hex_pubkey,
        target       => "30818:$dest_pk:bitcoin",
        target_relay => 'wss://relay.com',
        source       => $source_event_id,
        source_relay => 'wss://relay.com',
        destination  => $dest_pk,
        content      => 'Added block size info',
    );

    # Wiki redirect (kind 30819)
    my $event = Net::Nostr::Wiki->redirect(
        pubkey       => $hex_pubkey,
        identifier   => 'btc',
        target       => "30818:$pk:bitcoin",
        target_relay => 'wss://relay.com',
    );

    # Normalize a d tag
    my $dtag = Net::Nostr::Wiki->normalize_dtag('Wiki Article');
    # "wiki-article"

    # Parse any wiki event
    my $parsed = Net::Nostr::Wiki->from_event($event);

    # Validate
    Net::Nostr::Wiki->validate($event);

    # Resolve wikilinks in Djot content
    my $resolved = Net::Nostr::Wiki->resolve_wikilinks('[cryptocurrency][]');

=head1 DESCRIPTION

Implements NIP-54 (Wiki). Three event kinds are used:

=over 4

=item * B<Wiki Article> (kind 30818) - An addressable event for
encyclopedia entries. Articles are identified by lowercase, normalized
C<d> tags. Content should be Djot with NIP-21 links and wikilinks.
Multiple people may write articles about the same subject.

=item * B<Merge Request> (kind 818) - A regular event requesting a
merge from a forked article into the source. Directed to a pubkey,
references the original article and the modified version. The
destination pubkey can accept or reject via NIP-25 reactions.

=item * B<Wiki Redirect> (kind 30819) - An addressable event that
redirects one article name to another. Useful for disambiguation
and alternative names.

=back

Articles support fork and defer markers on C<a> and C<e> tags.
Fork markers indicate the article was derived from another version.
Defer markers indicate the author considers another entry as a better
version of their own.

=head1 CONSTANTS

=head2 WIKI_RELAY_LIST_KIND

    use Net::Nostr::Wiki;
    my $kind = Net::Nostr::Wiki::WIKI_RELAY_LIST_KIND;  # 10102

NIP-51 list kind for wiki-specific relay lists. Clients can create
kind 10102 lists to indicate preferred relays for wiki content.

=head1 CONSTRUCTOR

=head2 new

    my $w = Net::Nostr::Wiki->new(
        identifier => 'bitcoin',
        title      => 'Bitcoin',
    );

Creates a new C<Net::Nostr::Wiki> object. Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 article

    my $event = Net::Nostr::Wiki->article(
        pubkey     => $hex_pubkey,       # required
        identifier => $name,             # required (d tag, auto-normalized)
        content    => $djot_content,     # required
        title      => $display_title,    # optional
        summary    => $description,      # optional
        fork_a     => [$coord, $relay],  # optional (a tag with fork marker)
        fork_e     => [$id, $relay],     # optional (e tag with fork marker)
        defer_a    => [$coord, $relay],  # optional (a tag with defer marker)
        defer_e    => [$id, $relay],     # optional (e tag with defer marker)
    );

Creates a kind 30818 wiki article L<Net::Nostr::Event>. The C<identifier>
is automatically normalized per the NIP-54 d tag normalization rules.

=head2 merge_request

    my $event = Net::Nostr::Wiki->merge_request(
        pubkey       => $hex_pubkey,       # required
        target       => $article_coord,    # required (a tag)
        target_relay => $relay_url,        # optional
        source       => $event_id,         # required (e tag with source marker)
        source_relay => $relay_url,        # optional
        destination  => $dest_pubkey,      # required (p tag)
        base_version => $event_id,         # optional (e tag, version base)
        base_relay   => $relay_url,        # optional
        content      => $explanation,      # optional, defaults to ''
    );

Creates a kind 818 merge request L<Net::Nostr::Event>. The C<source>
event ID MUST be of a kind 30818 event.

=head2 redirect

    my $event = Net::Nostr::Wiki->redirect(
        pubkey       => $hex_pubkey,       # required
        identifier   => $source_name,      # required (d tag, auto-normalized)
        target       => $article_coord,    # required (a tag)
        target_relay => $relay_url,        # optional
    );

Creates a kind 30819 wiki redirect L<Net::Nostr::Event>. The C<identifier>
is automatically normalized. Content is always empty.

=head2 normalize_dtag

    my $normalized = Net::Nostr::Wiki->normalize_dtag('Wiki Article');
    # "wiki-article"

Normalizes a string per NIP-54 rules:

=over 4

=item * Lowercase all letters

=item * Whitespace converted to C<->

=item * Punctuation and symbols removed

=item * Consecutive C<-> collapsed

=item * Leading/trailing C<-> removed

=item * Non-ASCII letters preserved as UTF-8

=item * Numbers preserved

=back

=head2 from_event

    my $w = Net::Nostr::Wiki->from_event($event);

Parses a kind 30818, 818, or 30819 event into a C<Net::Nostr::Wiki>
object. Returns C<undef> for unrecognized kinds.

=head2 validate

    Net::Nostr::Wiki->validate($event);

Validates a NIP-54 event. Croaks if:

=over

=item * Kind is not 30818, 818, or 30819

=item * Kind 30818 missing C<d> tag

=item * Kind 818 missing C<a>, C<p>, or C<e> tag with C<source> marker

=item * Kind 30819 missing C<d> or C<a> tag

=back

Returns 1 on success.

=head2 resolve_wikilinks

    my $resolved = Net::Nostr::Wiki->resolve_wikilinks($djot_content);

Resolves reference-style links in Djot content to wiki article links.
Links with defined references (C<[label]: target> at end of content)
are preserved. Undefined reference-style links become wikilinks using
C<nostr:30818:normalized-name> URIs.

Handles both implicit (C<[text][]>) and explicit (C<[text][Label]>)
reference-style links.

=head1 ACCESSORS

=head2 identifier

The normalized C<d> tag value (kinds 30818, 30819).

=head2 title

Display title from C<title> tag (kind 30818).

=head2 summary

Description from C<summary> tag (kind 30818).

=head2 fork_a

Arrayref C<[$coord, $relay]> from C<a> tag with C<fork> marker.

=head2 fork_e

Arrayref C<[$id, $relay]> from C<e> tag with C<fork> marker.

=head2 defer_a

Arrayref C<[$coord, $relay]> from C<a> tag with C<defer> marker.

=head2 defer_e

Arrayref C<[$id, $relay]> from C<e> tag with C<defer> marker.

=head2 target

The article coordinate from C<a> tag (kinds 818, 30819).

=head2 target_relay

Relay hint from C<a> tag (kinds 818, 30819).

=head2 destination

Destination pubkey from C<p> tag (kind 818).

=head2 source

Source event ID from C<e> tag with C<source> marker (kind 818).

=head2 source_relay

Relay from C<e> tag with C<source> marker (kind 818).

=head2 base_version

Base version event ID from C<e> tag without marker (kind 818).

=head2 base_relay

Relay from base version C<e> tag (kind 818).

=head1 SEE ALSO

L<NIP-54|https://github.com/nostr-protocol/nips/blob/master/54.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
