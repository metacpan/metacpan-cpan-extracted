package Net::Nostr::Group;

use strictures 2;

use Net::Nostr::_ConstructorArgs ();

use Carp qw(croak);
use Encode ();
use URI::Escape ();
use Scalar::Util qw(blessed);
use Net::Nostr::Bech32 qw(encode_naddr decode_naddr);
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub parse_id {
    my ($class, $str) = @_;
    croak 'group identifier must be a non-empty string'
        unless defined($str) && !ref($str) && length($str);
    my ($base, $query) = split /\?/, $str, 2;
    my $invite;
    if (defined $query) {
        croak 'invalid invite suffix'
            unless $query =~ /\Ainvite=([^&#\s]+)\z/ && $query !~ /%(?![0-9A-Fa-f]{2})/;
        my $encoded = $1;
        $encoded =~ tr/+/ /;
        my $bytes = URI::Escape::uri_unescape($encoded);
        $invite = eval { Encode::decode('UTF-8', $bytes, Encode::FB_CROAK()) };
        croak 'invite must be valid UTF-8' if $@;
        _validate_invite($invite);
    }
    my $data = decode_naddr($base);
    croak "group identifier MUST reference kind 39000 metadata"
        unless $data->{kind} == 39000;
    croak 'group identifier requires a non-empty group id'
        unless $class->validate_group_id($data->{identifier});
    return {
        group_id => $data->{identifier},
        pubkey   => $data->{pubkey},
        kind     => $data->{kind},
        relays   => $data->{relays},
        relay    => $data->{relays}[0],
        (defined($invite) ? (invite => $invite) : ()),
    };
}

sub format_id {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(pubkey group_id relay relays invite);
    croak 'unknown group reference argument' if grep { !$known{$_} } keys %args;
    my $pubkey   = $args{pubkey}   // croak "format_id requires 'pubkey'";
    my $group_id = $args{group_id} // croak "format_id requires 'group_id'";
    croak 'group_id must be a non-empty string' unless $class->validate_group_id($group_id);
    my @relays;
    push @relays, $args{relay} if defined $args{relay};
    if (defined $args{relays}) {
        croak "relays must be an array reference"
            unless ref $args{relays} eq 'ARRAY';
        push @relays, @{$args{relays}};
    }
    my $identifier = encode_naddr(
        identifier => $group_id,
        pubkey     => $pubkey,
        kind       => 39000,
        relays     => \@relays,
    );
    if (exists $args{invite}) {
        _validate_invite($args{invite});
        $identifier .= '?invite=' . URI::Escape::uri_escape_utf8($args{invite});
    }
    return $identifier;
}

sub _validate_invite {
    my ($code) = @_;
    croak 'invite must be a non-empty string without control characters'
        unless defined($code) && !ref($code) && length($code) && $code !~ /[[:cntrl:]]/;
}

sub validate_group_id {
    my ($class, $id) = @_;
    return defined $id && !ref($id) && length($id) ? 1 : 0;
}

sub _validate_and_extract_group {
    my $class = shift;
    my $method = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my $pubkey   = $args{pubkey}   // croak "$method requires 'pubkey'";
    my $group_id = $args{group_id} // croak "$method requires 'group_id'";
    croak "invalid group_id: must be a non-empty string"
        unless $class->validate_group_id($group_id);
    return ($pubkey, $group_id);
}

sub _build_tags_with_h {
    my ($class, $group_id, $previous) = @_;
    my @tags = (['h', $group_id]);
    _validate_previous($previous) if defined $previous;
    if (defined($previous) && @$previous) {
        push @tags, ['previous', @$previous];
    }
    return @tags;
}

sub _validate_previous {
    my ($previous) = @_;
    croak 'previous must be an array of eight-character lowercase hex references'
        unless ref($previous) eq 'ARRAY';
    for my $prefix (@$previous) {
        croak 'previous must contain eight-character lowercase hex references'
            unless defined($prefix) && !ref($prefix) && $prefix =~ /\A[0-9a-f]{8}\z/;
    }
}

# Kind 9000: put-user
sub put_user {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my ($pubkey, $group_id) = $class->_validate_and_extract_group('put_user', %args);
    my $target = $args{target} // croak "put_user requires 'target'";
    croak "target must be 64-char lowercase hex" unless $target =~ $HEX64;
    my $roles  = $args{roles};
    my $reason = $args{reason} // '';

    my @tags = $class->_build_tags_with_h($group_id, $args{previous});
    if ($roles && @$roles) {
        push @tags, ['p', $target, @$roles];
    } else {
        push @tags, ['p', $target];
    }

    delete @args{qw(group_id target roles reason previous)};
    return Net::Nostr::Event->new(%args, kind => 9000, content => $reason, tags => \@tags);
}

# Kind 9001: remove-user
sub remove_user {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my ($pubkey, $group_id) = $class->_validate_and_extract_group('remove_user', %args);
    my $target = $args{target} // croak "remove_user requires 'target'";
    croak "target must be 64-char lowercase hex" unless $target =~ $HEX64;
    my $reason = $args{reason} // '';

    my @tags = $class->_build_tags_with_h($group_id, $args{previous});
    push @tags, ['p', $target];

    delete @args{qw(group_id target reason previous)};
    return Net::Nostr::Event->new(%args, kind => 9001, content => $reason, tags => \@tags);
}

# Kind 9002: edit-metadata
sub _extra_metadata_tags {
    my ($class, $group_id, $args) = @_;
    my @tags;
    if (exists $args->{banner}) {
        croak 'banner must be a string' unless defined($args->{banner}) && !ref($args->{banner});
        push @tags, ['banner', $args->{banner}];
    }
    if (exists $args->{parent}) {
        croak 'parent must be a non-empty group id distinct from this group'
            unless $class->validate_group_id($args->{parent}) && $args->{parent} ne $group_id;
        push @tags, ['parent', $args->{parent}];
    }
    if (exists $args->{children}) {
        croak 'children must be an array of distinct group ids' unless ref($args->{children}) eq 'ARRAY';
        my %seen;
        for my $child (@{$args->{children}}) {
            croak 'child must be a distinct non-empty group id, not this group'
                unless $class->validate_group_id($child) && $child ne $group_id && !$seen{$child}++;
            push @tags, ['child', $child];
        }
    }
    return @tags;
}

sub _metadata_tags {
    my ($class, $group_id, $args, $edit) = @_;
    croak 'group_id must be a non-empty string' unless $class->validate_group_id($group_id);
    my @tags;
    for my $name (qw(name picture about)) {
        next unless exists $args->{$name};
        croak "$name must be a string" unless defined($args->{$name}) && !ref($args->{$name});
        push @tags, [$name, $args->{$name}];
    }
    push @tags, $class->_extra_metadata_tags($group_id, $args);
    my @flags = $edit ? qw(private closed unrestricted open visible public restricted hidden livekit)
        : qw(livekit private restricted hidden closed);
    for my $flag (@flags) {
        next unless exists $args->{$flag};
        croak "$flag must be 0 or 1" unless defined($args->{$flag}) && !ref($args->{$flag})
            && $args->{$flag} =~ /\A[01]\z/;
        push @tags, [$flag] if $args->{$flag};
    }
    for my $pair ([qw(private public)], [qw(closed open)], [qw(hidden visible)], [qw(restricted unrestricted)]) {
        croak "conflicting $pair->[0] and $pair->[1] flags" if $args->{$pair->[0]} && $args->{$pair->[1]};
    }
    if (exists $args->{supported_kinds}) {
        croak 'supported_kinds must be an array reference' unless ref($args->{supported_kinds}) eq 'ARRAY';
        for my $kind (@{$args->{supported_kinds}}) {
            croak 'supported_kinds must contain integers from 0 through 65535'
                unless defined($kind) && !ref($kind) && $kind =~ /\A[0-9]+\z/ && $kind <= 65535;
        }
        push @tags, ['supported_kinds', map { "$_" } @{$args->{supported_kinds}}];
    }
    return @tags;
}

sub edit_metadata {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my ($pubkey, $group_id) = $class->_validate_and_extract_group('edit_metadata', %args);
    my $reason = $args{reason} // '';

    my @tags = $class->_build_tags_with_h($group_id, $args{previous});

    push @tags, $class->_metadata_tags($group_id, \%args, 1);

    delete @args{qw(group_id reason previous name picture about banner parent children
                    private closed unrestricted open visible public restricted hidden livekit supported_kinds)};
    return Net::Nostr::Event->new(%args, kind => 9002, content => $reason, tags => \@tags);
}

# Kind 9005: delete-event
sub delete_event {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my ($pubkey, $group_id) = $class->_validate_and_extract_group('delete_event', %args);
    my $event_id = $args{event_id} // croak "delete_event requires 'event_id'";
    croak "event_id must be 64-char lowercase hex" unless $event_id =~ $HEX64;
    my $reason   = $args{reason} // '';

    my @tags = $class->_build_tags_with_h($group_id, $args{previous});
    push @tags, ['e', $event_id];

    delete @args{qw(group_id event_id reason previous)};
    return Net::Nostr::Event->new(%args, kind => 9005, content => $reason, tags => \@tags);
}

# Kind 9007: create-group
sub create_group {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my ($pubkey, $group_id) = $class->_validate_and_extract_group('create_group', %args);
    my $reason = $args{reason} // '';

    my @tags = $class->_build_tags_with_h($group_id, $args{previous});

    delete @args{qw(group_id reason previous)};
    return Net::Nostr::Event->new(%args, kind => 9007, content => $reason, tags => \@tags);
}

# Kind 9008: delete-group
sub delete_group {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my ($pubkey, $group_id) = $class->_validate_and_extract_group('delete_group', %args);
    my $reason = $args{reason} // '';

    my @tags = $class->_build_tags_with_h($group_id, $args{previous});

    delete @args{qw(group_id reason previous)};
    return Net::Nostr::Event->new(%args, kind => 9008, content => $reason, tags => \@tags);
}

# Kind 9009: create-invite
sub create_invite {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my ($pubkey, $group_id) = $class->_validate_and_extract_group('create_invite', %args);
    my $code   = $args{code} // croak "create_invite requires 'code'";
    my $reason = $args{reason} // '';

    my @tags = $class->_build_tags_with_h($group_id, $args{previous});
    push @tags, ['code', $code];

    delete @args{qw(group_id code reason previous)};
    return Net::Nostr::Event->new(%args, kind => 9009, content => $reason, tags => \@tags);
}

# Kind 9021: join-request
sub join_request {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my ($pubkey, $group_id) = $class->_validate_and_extract_group('join_request', %args);
    my $reason = $args{reason} // '';

    my @tags = $class->_build_tags_with_h($group_id, $args{previous});
    push @tags, ['code', $args{code}] if defined $args{code};

    delete @args{qw(group_id reason previous code)};
    return Net::Nostr::Event->new(%args, kind => 9021, content => $reason, tags => \@tags);
}

# Kind 9022: leave-request
sub leave_request {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my ($pubkey, $group_id) = $class->_validate_and_extract_group('leave_request', %args);
    my $reason = $args{reason} // '';

    my @tags = $class->_build_tags_with_h($group_id, $args{previous});

    delete @args{qw(group_id reason previous)};
    return Net::Nostr::Event->new(%args, kind => 9022, content => $reason, tags => \@tags);
}

# Kind 39000: group metadata (relay-generated, addressable)
sub metadata {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my $pubkey   = $args{pubkey}   // croak "metadata requires 'pubkey'";
    my $group_id = $args{group_id} // croak "metadata requires 'group_id'";

    my @tags = (['d', $group_id]);

    push @tags, $class->_metadata_tags($group_id, \%args, 0);

    delete @args{qw(group_id name picture about banner parent children livekit supported_kinds
                    private restricted hidden closed)};
    return Net::Nostr::Event->new(%args, kind => 39000, content => '', tags => \@tags);
}

# Kind 39001: group admins (relay-generated, addressable)
sub admins {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my $pubkey   = $args{pubkey}   // croak "admins requires 'pubkey'";
    my $group_id = $args{group_id} // croak "admins requires 'group_id'";
    my $members  = $args{members}  // croak "admins requires 'members'";
    my $content  = $args{content}  // '';

    my @tags = (['d', $group_id]);
    for my $member (@$members) {
        croak "member pubkey must be 64-char lowercase hex" unless $member->{pubkey} =~ $HEX64;
        push @tags, ['p', $member->{pubkey}, @{$member->{roles}}];
    }

    delete @args{qw(group_id members content)};
    return Net::Nostr::Event->new(%args, kind => 39001, content => $content, tags => \@tags);
}

# Kind 39002: group members (relay-generated, addressable)
sub members {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my $pubkey   = $args{pubkey}   // croak "members requires 'pubkey'";
    my $group_id = $args{group_id} // croak "members requires 'group_id'";
    my $members  = $args{members}  // croak "members requires 'members'";
    my $content  = $args{content}  // '';

    my @tags = (['d', $group_id]);
    for (@$members) {
        croak "member pubkey must be 64-char lowercase hex" unless $_ =~ $HEX64;
        push @tags, ['p', $_];
    }

    delete @args{qw(group_id members content)};
    return Net::Nostr::Event->new(%args, kind => 39002, content => $content, tags => \@tags);
}

# Kind 39003: group roles (relay-generated, addressable)
sub roles {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my $pubkey   = $args{pubkey}   // croak "roles requires 'pubkey'";
    my $group_id = $args{group_id} // croak "roles requires 'group_id'";
    my $roles    = $args{roles}    // croak "roles requires 'roles'";
    my $content  = $args{content}  // '';

    my @tags = (['d', $group_id]);
    for my $role (@$roles) {
        if (defined $role->{description}) {
            push @tags, ['role', $role->{name}, $role->{description}];
        } else {
            push @tags, ['role', $role->{name}];
        }
    }

    delete @args{qw(group_id roles content)};
    return Net::Nostr::Event->new(%args, kind => 39003, content => $content, tags => \@tags);
}

# Kind 39004: livekit participants (relay-generated, addressable)
sub participants {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my $pubkey       = $args{pubkey}       // croak "participants requires 'pubkey'";
    my $group_id     = $args{group_id}     // croak "participants requires 'group_id'";
    my $participants = $args{participants} // croak "participants requires 'participants'";
    my $content      = $args{content}      // '';
    croak "participants must be an array reference"
        unless ref $participants eq 'ARRAY';

    my @tags = (['d', $group_id]);
    for my $participant (@$participants) {
        croak "participant pubkey must be 64-char lowercase hex"
            unless $participant =~ $HEX64;
        push @tags, ['participant', $participant];
    }

    delete @args{qw(group_id participants content)};
    return Net::Nostr::Event->new(%args, kind => 39004, content => $content, tags => \@tags);
}

# Parsing methods

sub _validate_pins {
    my ($pins) = @_;
    croak 'pins must be an array reference' unless ref($pins) eq 'ARRAY';
    for my $pin (@$pins) {
        croak 'pin must contain a tag name and reference'
            unless ref($pin) eq 'ARRAY' && @$pin == 2 && defined($pin->[0])
                && !ref($pin->[0]) && defined($pin->[1]) && !ref($pin->[1]);
        if ($pin->[0] eq 'e') {
            croak 'pin event id must be 64-char lowercase hex' unless $pin->[1] =~ $HEX64;
        } elsif ($pin->[0] eq 'a') {
            croak 'pin address must identify an addressable event'
                unless $pin->[1] =~ /\A(3[0-9]{4}):([0-9a-f]{64}):(.*)\z/s;
        } else {
            croak 'pin tag must be e or a';
        }
    }
}

sub _pin_event {
    my $class = shift;
    my $kind = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my (undef, $group_id) = $class->_validate_and_extract_group('pin list', %args);
    _validate_pins($args{pins});
    my @tags = ([$kind == 9010 ? 'h' : 'd', $group_id], map { [@$_] } @{$args{pins}});
    if ($kind == 9010 && exists $args{previous}) {
        _validate_previous($args{previous});
        push @tags, ['previous', @{$args{previous}}];
    }
    my $reason = delete $args{reason} // '';
    delete @args{qw(group_id pins previous)};
    return Net::Nostr::Event->new(%args, kind=>$kind, content=>$kind == 9010 ? $reason : '', tags=>\@tags);
}

sub update_pin_list {
    my $class = shift;
    return $class->_pin_event(9010, Net::Nostr::_ConstructorArgs::normalize(@_));
}

sub pinned_events {
    my $class = shift;
    return $class->_pin_event(39005, Net::Nostr::_ConstructorArgs::normalize(@_));
}

sub pins_from_event {
    my ($class, $event) = @_;
    croak 'pin event must be a Net::Nostr::Event' unless blessed($event) && $event->isa('Net::Nostr::Event');
    croak 'pin event must be kind 9010 or 39005' unless $event->kind == 9010 || $event->kind == 39005;
    my $id_tag = $event->kind == 9010 ? 'h' : 'd';
    my (@ids, @pins);
    for my $tag (@{$event->tags}) {
        croak 'pin tag requires a name' unless @$tag && defined($tag->[0]);
        if ($tag->[0] eq $id_tag) {
            croak 'pin group tag must have one value' unless @$tag == 2;
            push @ids, $tag->[1];
        } elsif ($tag->[0] eq 'e' || $tag->[0] eq 'a') {
            push @pins, [@$tag];
        } elsif ($tag->[0] eq 'previous') {
            _validate_previous([@$tag[1 .. $#$tag]]);
        } else {
            croak 'unknown pin tag';
        }
    }
    croak 'pin event requires exactly one non-empty group id'
        unless @ids == 1 && $class->validate_group_id($ids[0]);
    _validate_pins(\@pins);
    return {group_id=>$ids[0], pins=>\@pins};
}

sub metadata_from_event {
    my ($class, $event) = @_;
    croak 'metadata event must be a Net::Nostr::Event' unless blessed($event) && $event->isa('Net::Nostr::Event');
    croak "event must be kind 39000" unless $event->kind == 39000;

    my (%meta, %seen);
    my %flags = map { $_ => 1 } qw(private restricted hidden closed livekit);
    my %values = map { $_ => 1 } qw(d name picture about banner parent);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        croak 'metadata tag requires a name' unless defined $name;
        if ($values{$name}) {
            croak "$name must have one value and occur at most once" unless @$tag == 2 && !$seen{$name}++;
            $meta{$name eq 'd' ? 'group_id' : $name} = $tag->[1];
        } elsif ($name eq 'child') {
            croak 'child tag must have one value' unless @$tag == 2;
            push @{$meta{children}}, $tag->[1];
        } elsif ($name eq 'supported_kinds') {
            croak 'supported_kinds must occur at most once' if $seen{$name}++;
            $meta{supported_kinds} = [@{$tag}[1 .. $#$tag]];
        } elsif ($flags{$name}) {
            croak "$name must be a single-element tag occurring at most once" unless @$tag == 1 && !$seen{$name}++;
            $meta{$name} = 1;
        }
    }

    $class->_metadata_tags($meta{group_id}, \%meta, 0);
    return \%meta;
}

sub admins_from_event {
    my ($class, $event) = @_;
    croak "event must be kind 39001" unless $event->kind == 39001;

    my %result;
    my @admins;

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'd') {
            $result{group_id} = $tag->[1];
        } elsif ($tag->[0] eq 'p') {
            push @admins, {
                pubkey => $tag->[1],
                roles  => [@{$tag}[2 .. $#$tag]],
            };
        }
    }

    $result{admins} = \@admins;
    return \%result;
}

sub members_from_event {
    my ($class, $event) = @_;
    croak "event must be kind 39002" unless $event->kind == 39002;

    my %result;
    my @members;

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'd') {
            $result{group_id} = $tag->[1];
        } elsif ($tag->[0] eq 'p') {
            push @members, $tag->[1];
        }
    }

    $result{members} = \@members;
    return \%result;
}

sub roles_from_event {
    my ($class, $event) = @_;
    croak "event must be kind 39003" unless $event->kind == 39003;

    my %result;
    my @roles;

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'd') {
            $result{group_id} = $tag->[1];
        } elsif ($tag->[0] eq 'role') {
            push @roles, {
                name        => $tag->[1],
                description => $tag->[2],
            };
        }
    }

    $result{roles} = \@roles;
    return \%result;
}

sub participants_from_event {
    my ($class, $event) = @_;
    croak "event must be kind 39004" unless $event->kind == 39004;

    my %result;
    my @participants;

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'd') {
            $result{group_id} = $tag->[1];
        } elsif ($tag->[0] eq 'participant') {
            push @participants, $tag->[1];
        }
    }

    $result{participants} = \@participants;
    return \%result;
}

sub group_id_from_event {
    my ($class, $event) = @_;
    # h tag takes priority (user/mod events); d tag is fallback (metadata events)
    my $d_val;
    for my $tag (@{$event->tags}) {
        return $tag->[1] if $tag->[0] eq 'h';
        $d_val //= $tag->[1] if $tag->[0] eq 'd';
    }
    return $d_val;
}

1;

__END__

=head1 NAME

Net::Nostr::Group - NIP-29 relay-based groups

=head1 SYNOPSIS

    use Net::Nostr::Group;
    use Net::Nostr::Key;

    my $key = Net::Nostr::Key->new;

    # Format and parse a group identifier (naddr for kind 39000 metadata)
    my $group_naddr = Net::Nostr::Group->format_id(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        relay    => 'wss://groups.nostr.com',
    );

    my $parsed = Net::Nostr::Group->parse_id($group_naddr);
    # { group_id => 'pizza', pubkey => $relay_pubkey, kind => 39000, ... }

    # Validate a group_id
    Net::Nostr::Group->validate_group_id('my-group_1');  # 1
    Net::Nostr::Group->validate_group_id('Pizza Fans');   # 1
    Net::Nostr::Group->validate_group_id('');             # 0

    # Join a group (kind 9021)
    my $join = Net::Nostr::Group->join_request(
        pubkey   => $key->pubkey_hex,
        group_id => 'pizza',
        reason   => 'I love pizza',
        code     => 'invite-abc',  # optional invite code
    );
    $key->sign_event($join);
    $client->publish($join);

    # Leave a group (kind 9022)
    my $leave = Net::Nostr::Group->leave_request(
        pubkey   => $key->pubkey_hex,
        group_id => 'pizza',
    );

    # Add a user to a group (kind 9000, admin)
    my $put = Net::Nostr::Group->put_user(
        pubkey   => $key->pubkey_hex,
        group_id => 'pizza',
        target   => $user_pubkey,
        roles    => ['moderator'],
        reason   => 'promoted',
    );

    # Remove a user (kind 9001, admin)
    my $rm = Net::Nostr::Group->remove_user(
        pubkey   => $key->pubkey_hex,
        group_id => 'pizza',
        target   => $user_pubkey,
        reason   => 'spamming',
    );

    # Edit group metadata (kind 9002, admin)
    my $edit = Net::Nostr::Group->edit_metadata(
        pubkey   => $key->pubkey_hex,
        group_id => 'pizza',
        name     => 'Pizza Lovers',
        about    => 'We love pizza',
        private  => 1,
        closed   => 1,
    );

    # Delete an event from the group (kind 9005, admin)
    my $del = Net::Nostr::Group->delete_event(
        pubkey   => $key->pubkey_hex,
        group_id => 'pizza',
        event_id => $spam_event_id,
    );

    # Create a group (kind 9007)
    my $create = Net::Nostr::Group->create_group(
        pubkey   => $key->pubkey_hex,
        group_id => 'new-group',
    );

    # Delete a group (kind 9008)
    my $delete = Net::Nostr::Group->delete_group(
        pubkey   => $key->pubkey_hex,
        group_id => 'old-group',
    );

    # Create an invite code (kind 9009)
    my $invite = Net::Nostr::Group->create_invite(
        pubkey   => $key->pubkey_hex,
        group_id => 'pizza',
        code     => 'secret-code-123',
    );

    # Generate group metadata (kind 39000, relay-generated)
    my $meta = Net::Nostr::Group->metadata(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        name     => 'Pizza Lovers',
        picture  => 'https://pizza.com/pizza.png',
        about    => 'a group for pizza fans',
        private  => 1,
        closed   => 1,
        livekit  => 1,
        supported_kinds => [9, 11],
    );

    # Generate admin list (kind 39001, relay-generated)
    my $admin_event = Net::Nostr::Group->admins(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        members  => [
            { pubkey => $admin_pk, roles => ['admin'] },
            { pubkey => $mod_pk,   roles => ['moderator'] },
        ],
    );

    # Generate member list (kind 39002, relay-generated)
    my $member_event = Net::Nostr::Group->members(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        members  => [$pk1, $pk2, $pk3],
    );

    # Generate roles list (kind 39003, relay-generated)
    my $role_event = Net::Nostr::Group->roles(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        roles    => [
            { name => 'admin', description => 'full control' },
            { name => 'moderator', description => 'can delete messages' },
        ],
    );

    # Generate LiveKit participant list (kind 39004, relay-generated)
    my $participant_event = Net::Nostr::Group->participants(
        pubkey       => $relay_pubkey,
        group_id     => 'pizza',
        participants => [$pk1, $pk2],
    );

    # Parse received events
    my $meta_info    = Net::Nostr::Group->metadata_from_event($event);
    my $admin_info   = Net::Nostr::Group->admins_from_event($event);
    my $member_info  = Net::Nostr::Group->members_from_event($event);
    my $role_info    = Net::Nostr::Group->roles_from_event($event);
    my $part_info    = Net::Nostr::Group->participants_from_event($event);
    my $gid          = Net::Nostr::Group->group_id_from_event($event);

=head1 DESCRIPTION

Implements NIP-29 relay-based groups. Groups have arbitrary non-empty
C<group_id> strings in event C<h> and C<d> tags. Public group identifiers
are C<naddr> references to the group's kind 39000 metadata event. Group
state is managed through moderation events (kinds 9000-9010) and user
events (kinds 9021-9022). Relay-generated group state is published as
addressable events (kinds 39000-39005) signed by the relay.

This module supplies event and identifier helpers. L<Net::Nostr::RelayGroups>
provides an optional relay policy for moderation, subgroup trees, and pins.
L<Net::Nostr::GroupDiscovery> coordinates cached-admin migration and fork
lookups; applications supply its discovery transport and user interaction.

All user and moderation events MUST include an C<h> tag with the group
id. Group metadata events use a C<d> tag instead.

To store a user's list of groups, use a kind 10009 L<Net::Nostr::List>
with C<group> and C<r> tags per NIP-51:

    use Net::Nostr::List;

    my $groups = Net::Nostr::List->new(kind => 10009);
    my $group_id = Net::Nostr::Group->format_id(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        relay    => 'wss://groups.nostr.com',
    );
    $groups->add('group', $group_id, 'wss://groups.nostr.com', 'Pizza Lovers');
    $groups->add('r', 'wss://groups.nostr.com');
    my $event = $groups->to_event(pubkey => $key->pubkey_hex);

=head1 CLASS METHODS

=head2 parse_id

Accepts the optional C<?invite=...> suffix. The result includes C<invite> when
present; pass it as C<code> to L</join_request>. Validates the bech32 metadata
reference, suffix shape, percent encoding, and UTF-8. Empty codes, repeated
invite parameters, fragments, and control characters are rejected. An ordinary
identifier continues to parse without an C<invite> key.

    my $parsed = Net::Nostr::Group->parse_id($naddr);
    # { group_id => 'pizza', pubkey => $relay_pubkey, kind => 39000, ... }

Parses a group identifier C<naddr> that references a kind 39000 metadata
event. Returns the raw C<group_id>, relay pubkey, kind, relay hints, and
the first relay hint as C<relay>. Croaks for legacy host-based identifiers,
invalid bech32 data, empty group IDs, or C<naddr> values that do not reference
kind 39000. The returned reference is structurally validated; it does not
prove that the relay hosts the group.

=head2 format_id

Optional C<invite> accepts a non-empty string without control characters and
appends a percent-encoded UTF-8 query value. The bech32 prefix remains a valid
standalone group reference. Relay hints and the referenced public key retain
the validation performed by L<Net::Nostr::Bech32/encode_naddr>.

    my $id = Net::Nostr::Group->format_id(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        relay    => 'wss://groups.nostr.com',
    );
    # naddr1...

Formats a public group identifier as an C<naddr> referencing the group's
kind 39000 metadata event. C<pubkey> is the relay's self pubkey.
C<relay> or C<relays> may be supplied as relay hints. C<relays> must be
an arrayref. This strict builder rejects empty group IDs and unknown options.

=head2 validate_group_id

    Net::Nostr::Group->validate_group_id('my-group');  # 1
    Net::Nostr::Group->validate_group_id('Pizza Fans'); # 1
    Net::Nostr::Group->validate_group_id('');           # 0

Returns true if the group id is a defined non-empty scalar. Current
NIP-29 does not restrict group ids to a specific character set.

=head2 put_user

    my $event = Net::Nostr::Group->put_user(
        pubkey   => $hex_pubkey,
        group_id => 'pizza',
        target   => $user_pubkey,
        roles    => ['admin', 'moderator'],  # optional
        reason   => 'promoted',              # optional
        previous => ['abcd1234'],            # optional timeline refs
    );

Creates a kind 9000 moderation event to add a user to the group or
update their roles. The C<p> tag contains the target pubkey followed
by any role strings.

=head2 remove_user

    my $event = Net::Nostr::Group->remove_user(
        pubkey   => $hex_pubkey,
        group_id => 'pizza',
        target   => $user_pubkey,
        reason   => 'spamming',  # optional
    );

Creates a kind 9001 moderation event to remove a user from the group.

All user and moderation event builders (C<put_user>, C<remove_user>,
C<edit_metadata>, C<delete_event>, C<create_group>, C<delete_group>,
C<create_invite>, C<join_request>, C<leave_request>) accept an optional
C<previous> parameter for timeline references. When defined it must be an
array of eight-character lowercase hex strings; an empty array adds no tag.
The relay must check that referenced events exist. See C<put_user> for an
example.

=head2 edit_metadata

Also accepts C<banner>, C<parent>, and C<children>. C<banner> is a display
string. C<parent> is a non-empty group ID distinct from this group; omission
requests promotion to a root. C<children> is an array of distinct non-empty
group IDs in display order, excluding this group itself. The builder validates
these structural rules. Relay authorization, existence of the parent, cycles,
and completeness of the child list require the relay's group state.
Also accepts C<livekit> and C<supported_kinds>, as described under L</metadata>.
The Core builder can describe AV support even when the chosen relay does not
provide it; L<Net::Nostr::RelayGroups> rejects AV edits.

    my $event = Net::Nostr::Group->edit_metadata(
        pubkey       => $hex_pubkey,
        group_id     => 'pizza',
        name         => 'Pizza Lovers',       # optional
        picture      => 'https://pic.url',    # optional
        about        => 'description',        # optional
        private      => 1,                    # optional flag
        restricted   => 1,                    # optional flag
        hidden       => 1,                    # optional flag
        closed       => 1,                    # optional flag
        supported_kinds => [9, 11],           # optional text event kinds
    );

Creates a kind 9002 moderation event to update group metadata. Metadata
fields become tags. Supplied flags must be C<0> or C<1>; true flags become
single-element tags. To reverse flags, use C<public>, C<unrestricted>,
C<visible>, or C<open>. Supplying both members of an opposing pair as true
croaks. Display fields must be defined scalar strings. This is a strict
structural builder returning an unsigned event; it does not authorize edits.

=head2 delete_event

    my $event = Net::Nostr::Group->delete_event(
        pubkey   => $hex_pubkey,
        group_id => 'pizza',
        event_id => $event_id_hex,
        reason   => 'spam content',  # optional
    );

Creates a kind 9005 moderation event to delete an event from the group.

=head2 create_group

    my $event = Net::Nostr::Group->create_group(
        pubkey   => $hex_pubkey,
        group_id => 'new-group',
    );

Creates a kind 9007 event requesting the relay to create a new group.

=head2 delete_group

    my $event = Net::Nostr::Group->delete_group(
        pubkey   => $hex_pubkey,
        group_id => 'old-group',
        reason   => 'inactive',  # optional
    );

Creates a kind 9008 event requesting the relay to delete a group.

=head2 create_invite

    my $event = Net::Nostr::Group->create_invite(
        pubkey   => $hex_pubkey,
        group_id => 'pizza',
        code     => 'secret-code-123',
    );

Creates a kind 9009 event with an invite code for the group.

=head2 join_request

    my $event = Net::Nostr::Group->join_request(
        pubkey   => $hex_pubkey,
        group_id => 'pizza',
        reason   => 'I love pizza',   # optional
        code     => 'invite-abc',     # optional invite code
    );

Creates a kind 9021 join request event. The optional C<code> tag can
be used with invite codes created by C<create_invite>.

=head2 leave_request

    my $event = Net::Nostr::Group->leave_request(
        pubkey   => $hex_pubkey,
        group_id => 'pizza',
        reason   => 'moving on',  # optional
    );

Creates a kind 9022 leave request event.

=head2 metadata

Supports the same C<banner>, C<parent>, and ordered C<children> fields and
structural checks as L</edit_metadata>. It builds an unsigned metadata event;
only the hosting relay's key should sign the result.

    my $event = Net::Nostr::Group->metadata(
        pubkey     => $relay_pubkey,
        group_id   => 'pizza',
        name       => 'Pizza Lovers',
        picture    => 'https://pizza.com/pizza.png',
        about      => 'a group for pizza fans',
        private    => 1,    # only members can read
        restricted => 1,    # only members can write
        hidden     => 1,    # hide metadata from non-members
        closed     => 1,    # ignore join requests
        livekit    => 1,    # group supports LiveKit A/V rooms
        supported_kinds => [9, 11], # text event kinds supported by the group
    );

Creates a kind 39000 addressable event describing group metadata.
This event should be signed by the relay's master key. Uses a C<d>
tag (not C<h>) with the group id. C<supported_kinds>, when supplied,
must be an arrayref of integer kinds from 0 through 65535. An empty array
emits an empty tag (no supported text kinds); omission leaves kinds unlimited.
Display fields must be defined scalar strings and flags must be C<0> or C<1>.
Group IDs must be non-empty. This builder checks structure, including subgroup
references, but does not verify relay ownership or other groups' state.

=head2 admins

    my $event = Net::Nostr::Group->admins(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        content  => 'admin list',  # optional
        members  => [
            { pubkey => $pk, roles => ['admin'] },
        ],
    );

Creates a kind 39001 addressable event listing group admins with roles.

=head2 members

    my $event = Net::Nostr::Group->members(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        content  => 'member list',  # optional
        members  => [$pk1, $pk2],
    );

Creates a kind 39002 addressable event listing group members.

=head2 roles

    my $event = Net::Nostr::Group->roles(
        pubkey   => $relay_pubkey,
        group_id => 'pizza',
        content  => 'role definitions',  # optional
        roles    => [
            { name => 'admin', description => 'full control' },
            { name => 'moderator' },
        ],
    );

Creates a kind 39003 addressable event listing supported roles.

=head2 participants

    my $event = Net::Nostr::Group->participants(
        pubkey       => $relay_pubkey,
        group_id     => 'pizza',
        content      => 'participant list',  # optional
        participants => [$pk1, $pk2],
    );

Creates a kind 39004 addressable event listing current LiveKit
participants. C<participants> must be an arrayref. This event should be
signed by the relay's master key.

=head2 update_pin_list

    my $pins = [['e', $event_id], ['a', "30023:$alice_pk:post"]];
    my $update = Net::Nostr::Group->update_pin_list(
        pubkey => $alice_pk, group_id => 'pizza', pins => $pins,
    );
    my $announcement = Net::Nostr::Group->pinned_events(
        pubkey => $relay_pk, group_id => 'pizza', pins => $pins,
    );
    my $decoded = Net::Nostr::Group->pins_from_event($announcement);

Builds an unsigned kind 9010 moderation event. Requires C<pubkey>, C<group_id>,
and C<pins>, an array of two-element tags. Each tag must be C<['e', $id]> with
a 64-character lowercase hex event ID or C<['a', $coordinate]> referencing
an addressable kind (30000 through 39999). The order is preserved; an empty
array clears the pins. Accepts the usual C<reason>, C<previous>, and event
fields. Invalid references, tag shapes, and missing fields croak. Authorization
and a relay's optional pin count limit are enforced by the relay.
C<previous> must be an array of eight-character lowercase hex timeline
references. The relay checks whether those references belong to its history.

=head2 pinned_events

Builds unsigned relay metadata of kind 39005. Requires C<pubkey>, C<group_id>,
and C<pins>, validated exactly as in L</update_pin_list>. Emits a C<d> tag and
the ordered full pin list with empty content. Sign with the hosting relay key.

=head2 pins_from_event

Parses kind 9010 or 39005 into C<{ group_id =E<gt> $id, pins =E<gt> \@tags }>.
Validates the kind, exactly one non-empty C<h> or C<d> group tag as appropriate,
and every pin reference and tag shape. A C<previous> tag is permitted and its
values must be eight-character lowercase hex strings; other
tag names are rejected. Returns copied pin arrays. It does not authenticate
the signature or check group administration; verify the event before trusting
it. Parsing then rebuilding preserves the pin order, including an empty list.

=head2 metadata_from_event

The result includes C<banner>, C<parent>, and ordered C<children> when present.
Requires exactly one non-empty C<d> tag. Recognized display, parent, flag,
and supported-kind tags must have the correct shape and occur at most once.
Self references, duplicate children, and invalid supported kinds croak.
Unknown named tags are ignored. These are structural checks; validating a
complete relay tree requires its other metadata and administrator lists.

    my $meta = Net::Nostr::Group->metadata_from_event($event);
    # { group_id => '...', name => '...', picture => '...',
    #   about => '...', private => 1, closed => 1 }

Parses a kind 39000 event. Returns a hashref with group metadata.
Boolean flags (C<private>, C<restricted>, C<hidden>, C<closed>,
C<livekit>) are set to 1 when present. C<supported_kinds> is returned
as an arrayref when present. Requires a L<Net::Nostr::Event> of kind 39000;
does not authenticate its ID or signature. Authenticate remote metadata before
trusting it. The returned fields require no later structural validation.

=head2 admins_from_event

    my $result = Net::Nostr::Group->admins_from_event($event);
    # { group_id => '...', admins => [{ pubkey => '...', roles => [...] }] }

Parses a kind 39001 event. Returns a hashref with group_id and an
arrayref of admin entries. Croaks if the event is not kind 39001.

    for my $admin (@{$result->{admins}}) {
        say "$admin->{pubkey}: " . join(', ', @{$admin->{roles}});
    }

=head2 members_from_event

    my $result = Net::Nostr::Group->members_from_event($event);
    # { group_id => '...', members => [$pk1, $pk2] }

Parses a kind 39002 event. Returns a hashref with group_id and an
arrayref of member pubkeys. Croaks if the event is not kind 39002.

=head2 roles_from_event

    my $result = Net::Nostr::Group->roles_from_event($event);
    # { group_id => '...', roles => [{ name => '...', description => '...' }] }

Parses a kind 39003 event. Returns a hashref with group_id and an
arrayref of role definitions. Croaks if the event is not kind 39003.

    for my $role (@{$result->{roles}}) {
        say "$role->{name}: $role->{description}";
    }

=head2 participants_from_event

    my $result = Net::Nostr::Group->participants_from_event($event);
    # { group_id => '...', participants => [$pk1, $pk2] }

Parses a kind 39004 event. Returns a hashref with group_id and an
arrayref of participant pubkeys. Croaks if the event is not kind 39004.

=head2 group_id_from_event

    my $gid = Net::Nostr::Group->group_id_from_event($event);

Extracts the group id from an event's C<h> tag (user/moderation events)
or C<d> tag (metadata events). If both tags are present, the C<h> tag
takes priority. Returns C<undef> if neither is found.

    my $gid = Net::Nostr::Group->group_id_from_event($join_event);
    say "Group: $gid";

=head1 SEE ALSO

L<NIP-29|https://github.com/nostr-protocol/nips/blob/master/29.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::List> (kind 10009 group storage)

=cut
