package Net::Nostr::Mention;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Bech32 qw(
    encode_npub encode_note
    encode_nprofile encode_nevent encode_naddr
    decode_bech32_entity
);
use Exporter 'import';

our @EXPORT_OK = qw(
    extract_mentions
    replace_mentions
    mention_pubkey
    mention_event
    mention_addr
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

# Match nostr: followed by bech32 characters (alphanumeric except 1bio)
# NIP-19 bech32 uses qpzry9x8gf2tvdw0s3jn54khce6mua7l plus separator '1'
my $NOSTR_RE = qr/nostr:([a-z]+1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]{6,})/i;

sub extract_mentions {
    my ($content) = @_;
    return () unless defined $content && length $content;

    my @mentions;
    while ($content =~ /$NOSTR_RE/g) {
        my $bech32 = $1;
        my $uri = $&;
        my $end = pos($content);
        my $start = $end - length($uri);

        my $decoded = eval { decode_bech32_entity($bech32) };
        next unless $decoded;

        # Skip nsec per NIP-21
        next if $decoded->{type} eq 'nsec';

        push @mentions, {
            type  => $decoded->{type},
            data  => $decoded->{data},
            uri   => $uri,
            start => $start,
            end   => $end,
        };
    }

    return @mentions;
}

sub replace_mentions {
    my ($content, $callback) = @_;
    croak "callback must be a code reference" unless ref $callback eq 'CODE';
    return $content unless defined $content && length $content;

    my @mentions = extract_mentions($content);
    return $content unless @mentions;

    # Build result from back to front to preserve offsets
    for my $m (reverse @mentions) {
        my $replacement = $callback->($m);
        substr($content, $m->{start}, $m->{end} - $m->{start}, $replacement);
    }

    return $content;
}

sub mention_pubkey {
    my ($pubkey, %opts) = @_;
    croak "pubkey must be 64-char lowercase hex" unless defined $pubkey && $pubkey =~ $HEX64;

    if ($opts{relays} && @{$opts{relays}}) {
        return 'nostr:' . encode_nprofile(pubkey => $pubkey, relays => $opts{relays});
    }
    return 'nostr:' . encode_npub($pubkey);
}

sub mention_event {
    my ($id, %opts) = @_;
    croak "event id must be 64-char lowercase hex" unless defined $id && $id =~ $HEX64;

    if ($opts{relays} || $opts{author} || defined $opts{kind}) {
        return 'nostr:' . encode_nevent(
            id     => $id,
            (relays => $opts{relays}) x !!$opts{relays},
            (author => $opts{author}) x !!$opts{author},
            (defined $opts{kind} ? (kind => $opts{kind}) : ()),
        );
    }
    return 'nostr:' . encode_note($id);
}

sub mention_addr {
    my (%opts) = @_;
    croak "mention_addr requires 'identifier'" unless defined $opts{identifier};
    croak "mention_addr requires 'pubkey'" unless defined $opts{pubkey};
    croak "mention_addr requires 'kind'" unless defined $opts{kind};

    return 'nostr:' . encode_naddr(
        identifier => $opts{identifier},
        pubkey     => $opts{pubkey},
        kind       => $opts{kind},
        ($opts{relays} ? (relays => $opts{relays}) : ()),
    );
}

1;

__END__

=head1 NAME

Net::Nostr::Mention - NIP-27 text note references

=head1 SYNOPSIS

    use Net::Nostr::Mention qw(
        extract_mentions replace_mentions
        mention_pubkey mention_event mention_addr
    );

    my $pk = '7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e';
    my $id = 'aaf9dd42b3de2a1a2f95e50fdbbef66e1afb165152a581a3ee75ac39a0559cd2';

    # Create mentions for use in event content
    my $m1 = mention_pubkey($pk);
    # nostr:npub1...

    my $m2 = mention_pubkey($pk, relays => ['wss://relay.com']);
    # nostr:nprofile1...

    my $m3 = mention_event($id);
    # nostr:note1...

    my $m4 = mention_event($id, author => $pk, kind => 1);
    # nostr:nevent1...

    my $m5 = mention_addr(
        identifier => 'my-article', pubkey => $pk, kind => 30023,
    );
    # nostr:naddr1...

    # Extract all mentions from content
    my $content = "hello $m1 see also $m3";
    my @mentions = extract_mentions($content);
    # @mentions = ({ type => 'npub', data => $pk, uri => 'nostr:npub1...', ... },
    #              { type => 'note', data => $id, uri => 'nostr:note1...', ... })

    # Replace mentions with display text
    my $display = replace_mentions($content, sub {
        my ($mention) = @_;
        return '@someone' if $mention->{type} eq 'npub';
        return '[event]'  if $mention->{type} eq 'note';
        return $mention->{uri};  # keep as-is
    });
    # 'hello @someone see also [event]'

=head1 DESCRIPTION

Implements NIP-27 text note references. This NIP standardizes inline
references to other events and profiles within event content using
C<nostr:> URIs (NIP-21) containing NIP-19 bech32-encoded entities.

When creating events, use L</mention_pubkey>, L</mention_event>, and
L</mention_addr> to produce properly formatted C<nostr:> URIs to embed
in content.

When displaying events, use L</extract_mentions> to find all references
in content, and L</replace_mentions> to substitute them with display
text such as profile names or event previews.

Including C<p>, C<e>, or C<q> tags for mentioned entities is optional
per NIP-27. Clients should add tags when they want the mentioned profile
to be notified or the referenced event to recognize the mention as a
reply.

=head1 FUNCTIONS

All functions are exportable. None are exported by default.

=head2 extract_mentions

    my @mentions = extract_mentions($content);

Finds all C<nostr:> URIs in the given content string. Returns a list of
hashrefs, one per mention, in order of appearance. Each hashref contains:

=over 4

=item C<type> - entity type: C<npub>, C<note>, C<nprofile>, C<nevent>, or C<naddr>

=item C<data> - decoded data: hex string for bare types (C<npub>, C<note>),
hashref for TLV types (C<nprofile>, C<nevent>, C<naddr>)

=item C<uri> - the full C<nostr:...> string as it appeared in content

=item C<start> - byte offset of the start of the URI in content

=item C<end> - byte offset of the end of the URI in content

=back

C<nsec> URIs are silently skipped (they must not appear in C<nostr:> URIs
per NIP-21). Invalid bech32 strings are silently skipped.

    use Net::Nostr::Bech32 qw(encode_npub);
    my $npub = encode_npub('aa' x 32);
    my $content = "hello nostr:$npub world";
    my @m = extract_mentions($content);
    say $m[0]{type};   # 'npub'
    say $m[0]{start};  # 6
    say substr($content, $m[0]{start}, $m[0]{end} - $m[0]{start});
    # nostr:npub1...
    say $m[0]{data};   # 'aa' x 32

=head2 replace_mentions

    my $display = replace_mentions($content, \&callback);

Replaces each C<nostr:> mention in content with the return value of the
callback. The callback receives a mention hashref (same structure as
L</extract_mentions>) and should return a replacement string.

    use Net::Nostr::Bech32 qw(encode_npub encode_note);
    my $npub = encode_npub('aa' x 32);
    my $note = encode_note('bb' x 32);
    my $content = "by nostr:$npub see nostr:$note";
    my $display = replace_mentions($content, sub {
        my ($m) = @_;
        return '@' . substr($m->{data}, 0, 8) . '...' if $m->{type} eq 'npub';
        return '[event]' if $m->{type} eq 'note' || $m->{type} eq 'nevent';
        return $m->{uri};
    });
    # 'by @aaaaaaaa... see [event]'

=head2 mention_pubkey

    my $uri = mention_pubkey($hex_pubkey);
    my $uri = mention_pubkey($hex_pubkey, relays => ['wss://relay.com']);

Creates a C<nostr:> URI for a public key. Returns C<nostr:npub1...> when
no options are given, or C<nostr:nprofile1...> when relay hints are provided.

    my $pk = 'aa' x 32;
    my $content = "hello " . mention_pubkey($pk) . " how are you?";
    # 'hello nostr:npub1... how are you?'

=head2 mention_event

    my $uri = mention_event($hex_event_id);
    my $uri = mention_event($hex_event_id, relays => \@r, author => $pk, kind => $k);

Creates a C<nostr:> URI for an event. Returns C<nostr:note1...> when no
options are given, or C<nostr:nevent1...> when any of C<relays>, C<author>,
or C<kind> are provided.

    my $pk = 'aa' x 32;
    my $id = 'bb' x 32;
    my $content = "see " . mention_event($id, author => $pk, kind => 1);
    # 'see nostr:nevent1...'

=head2 mention_addr

    my $uri = mention_addr(
        identifier => $d_tag,
        pubkey     => $hex_pubkey,
        kind       => $kind,
        relays     => \@relays,   # optional
    );

Creates a C<nostr:naddr1...> URI for an addressable event. C<identifier>,
C<pubkey>, and C<kind> are required. C<relays> is optional.

    my $pk = 'aa' x 32;
    my $content = "read " . mention_addr(
        identifier => 'my-article', pubkey => $pk, kind => 30023,
    );
    # 'read nostr:naddr1...'

=head1 SEE ALSO

L<NIP-27|https://github.com/nostr-protocol/nips/blob/master/27.md>,
L<NIP-21|https://github.com/nostr-protocol/nips/blob/master/21.md>,
L<Net::Nostr>, L<Net::Nostr::Bech32>

=cut
