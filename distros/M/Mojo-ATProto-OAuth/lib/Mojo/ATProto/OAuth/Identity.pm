package 
    Mojo::ATProto::OAuth::Identity;
use Mojo::Base -base, -signatures;

use Mojo::UserAgent qw//;
use Mojo::URL qw//;
use Mojo::Promise qw//;
use Mojo::IOLoop qw//;
use Mojo::Log qw//;
use Net::DNS::Resolver qw//;
use feature 'try';

use constant DEBUG => $ENV{MOJO_OAUTH_DEBUG} || 0;

our $VERSION = '1.01'; # VERSION

has 'plc_url'               => sub { return 'https://plc.directory' };
has 'dns'                   => sub { Net::DNS::Resolver->new };
has 'log'                   => sub { Mojo::Log->new };
has 'ua'                    => sub($self) {
    my $ua = Mojo::UserAgent->new(request_timeout => 10);
    no strict;
    $ua->transactor->name('Mojo::ATProto::OAuth/' . $VERSION || 'dev');
    use strict;
    return $ua;
};

# --- Handle -> DID resolution ---

# Parses a Net::DNS::Packet answer for a "did=<did>" TXT record. Shared
# by the sync and async DNS lookups - the only difference between them
# is how the answer packet gets obtained, never how it's read.
sub _parse_txt_answer($self, $answer) {
    return undef unless $answer;
    for my $rr ($answer->answer) {
        next unless $rr->type eq 'TXT';
        my $txt = join('', $rr->txtdata);
        return $1 if $txt =~ /^did=(did:[a-z]+:[a-zA-Z0-9._:%-]+)$/;
    }
    return undef;
}

# Validates a well-known response body as a bare DID string - shared by
# the sync and async HTTP well-known lookups.
sub _valid_did_body($self, $body) {
    return undef unless defined $body;
    return undef if length($body) > 2048;
    $body =~ s/^\s+|\s+$//g;
    return undef unless $body =~ /^did:[a-z]+:[a-zA-Z0-9._:%-]+$/;
    return $body;
}

# DNS TXT lookup at _atproto.<handle>, looking for a "did=<did>" record.
# Returns undef (not an error) if nothing is found - a handle without a
# DNS TXT record is expected to fall back to HTTP well-known, not a
# failure in itself.
sub resolve_handle_dns($self, $handle) {
    my $answer = $self->dns->search("_atproto.$handle", 'TXT');
    my $did    = $self->_parse_txt_answer($answer);
    $self->log->debug("Identity: DNS TXT lookup for _atproto.$handle -> " . ($did // 'no record')) if DEBUG;
    return $did;
}

# Async variant of resolve_handle_dns - Net::DNS::Native doesn't handle
# TXT records, so we need to use Net::DNS::Resolver here instead and 
# tie it into IOLoop
sub resolve_handle_dns_p($self, $handle) {
    my $promise = Mojo::Promise->new;
    my $sock    = $self->dns->bgsend("_atproto.$handle", 'TXT');
    return Mojo::Promise->resolve(undef) unless $sock;

    my $reactor = Mojo::IOLoop->singleton->reactor;
    $reactor->io(
        $sock => sub {
            $reactor->remove($sock);
            my $answer = $self->dns->bgread($sock);
            close($sock);
            my $did = $self->_parse_txt_answer($answer);
            $self->log->debug("Identity: DNS TXT lookup (async) for _atproto.$handle -> " . ($did // 'no record')) if DEBUG;
            $promise->resolve($did);
        }
    )->watch($sock, 1, 0);

    return $promise;
}

# HTTP well-known fallback: https://<handle>/.well-known/atproto-did,
# expected body is the bare DID string, nothing else. 2048-byte cap
# matches indigo's own limit - this is untrusted response data.
sub resolve_handle_well_known($self, $handle) {
    $self->log->debug("Identity: HTTP well-known lookup for $handle") if DEBUG;
    my $tx  = $self->ua->get(sprintf('https://%s/.well-known/atproto-did', $handle));
    my $res = $tx->result;
    $self->log->debug('Identity: well-known response status=' . ($res->code // 'connection error')) if DEBUG;
    return undef unless $res->is_success;
    return $self->_valid_did_body($res->body);
}

sub resolve_handle_well_known_p($self, $handle) {
    $self->log->debug("Identity: HTTP well-known lookup (async) for $handle") if DEBUG;
    return $self->ua->get_p(sprintf('https://%s/.well-known/atproto-did', $handle))
        ->then(sub ($tx) {
            my $res = $tx->result;
            $self->log->debug('Identity: well-known response status=' . ($res->code // 'connection error')) if DEBUG;
            return undef unless $res->is_success;
            return $self->_valid_did_body($res->body);
        });
}

sub resolve_handle($self, $handle) {
    $handle = lc($handle);
    $self->log->debug("Identity: resolving handle '$handle' to a DID") if DEBUG;
    try {
        if(my $did = $self->resolve_handle_dns($handle)) {
            $self->log->debug("Identity: '$handle' resolved via DNS -> $did") if DEBUG;
            return $did;
        }
        if(my $did = $self->resolve_handle_well_known($handle)) {
            $self->log->debug("Identity: '$handle' resolved via well-known -> $did") if DEBUG;
            return $did;
        }
        die "could not resolve handle '$handle' to a DID (DNS and HTTP well-known both failed)\n"
    } catch($ex) {
        die "could not resolve handle '$handle' to a DID (exception: $ex)\n";
    }
}

sub resolve_handle_p ($self, $handle) {
    $handle = lc($handle);
    $self->log->debug("Identity: resolving handle '$handle' to a DID (async)") if DEBUG;
    return $self->resolve_handle_dns_p($handle)->then(sub($did) {
        if(defined $did) {
            $self->log->debug("Identity: '$handle' resolved via DNS -> $did") if DEBUG;
            return $did;
        }
        return $self->resolve_handle_well_known_p($handle)->then(sub($did) {
            die "could not resolve handle '$handle' to a DID (DNS and HTTP well-known both failed)\n"
                unless defined $did;
            $self->log->debug("Identity: '$handle' resolved via well-known -> $did") if DEBUG;
            return $did;
        });
    });
}

# --- DID -> DID document resolution ---

sub resolve_did($self, $did) {
    return $self->_resolve_did_plc($did) if $did =~ /^did:plc:/;
    return $self->_resolve_did_web($did) if $did =~ /^did:web:/;
    die "unsupported DID method: $did\n";
}

sub resolve_did_p($self, $did) {
    return $self->_resolve_did_plc_p($did) if $did =~ /^did:plc:/;
    return $self->_resolve_did_web_p($did) if $did =~ /^did:web:/;
    return Mojo::Promise->reject("unsupported DID method: $did\n");
}

sub _resolve_did_plc($self, $did) {
    $self->log->debug("Identity: PLC directory lookup for $did") if DEBUG;
    my $tx  = $self->ua->get(sprintf('%s/%s', $self->plc_url, $did));
    my $res = $tx->result;
    $self->log->debug('Identity: PLC directory response status=' . ($res->code // 'connection error')) if DEBUG;
    die "PLC directory lookup failed for $did: " . ($res->message // 'connection error') . "\n"
        unless $res->is_success;
    return $res->json;
}

sub _resolve_did_plc_p($self, $did) {
    $self->log->debug("Identity: PLC directory lookup (async) for $did") if DEBUG;
    return $self->ua->get_p(sprintf('%s/%s', $self->plc_url, $did))->then(sub($tx) {
        my $res = $tx->result;
        $self->log->debug('Identity: PLC directory response status=' . ($res->code // 'connection error')) if DEBUG;
        die "PLC directory lookup failed for $did: " . ($res->message // 'connection error') . "\n"
            unless $res->is_success;
        return $res->json;
    });
}

sub _resolve_did_web($self, $did) {
    my $hostname = $self->_did_web_hostname($did);
    $self->log->debug("Identity: did:web lookup for $did (host=$hostname)") if DEBUG;
    my $tx        = $self->ua->get(sprintf('https://%s/.well-known/did.json', $hostname));
    my $res       = $tx->result;
    $self->log->debug('Identity: did:web response status=' . ($res->code // 'connection error')) if DEBUG;
    die "did:web lookup failed for $did: " . ($res->message // 'connection error') . "\n"
        unless $res->is_success;
    return $res->json;
}

sub _resolve_did_web_p($self, $did) {
    my $hostname = $self->_did_web_hostname($did);
    $self->log->debug("Identity: did:web lookup (async) for $did (host=$hostname)") if DEBUG;
    return $self->ua->get_p(sprintf('https://%s/.well-known/did.json', $hostname))
        ->then(sub ($tx) {
            my $res = $tx->result;
            $self->log->debug('Identity: did:web response status=' . ($res->code // 'connection error')) if DEBUG;
            die "did:web lookup failed for $did: " . ($res->message // 'connection error') . "\n"
                unless $res->is_success;
            return $res->json;
        });
}

sub _did_web_hostname($self, $did) {
    my ($hostname) = $did =~ /^did:web:(.+)$/;
    die "malformed did:web: $did\n" unless defined $hostname;
    die "did:web identifier not a simple hostname: $hostname\n" if $hostname =~ /:/;
    return $hostname;
}

# --- DID document -> identity hashref ---
# Identity shape:
#   { did, handle, also_known_as => [...],
#     services => { <fragment> => {type, url} },
#     keys     => { <fragment> => {type, public_key_multibase} } }
# `handle` is always undef here - only a caller that has bi-directionally
# verified it (see lookup(), below) should ever set it.
sub _parse_identity($self, $doc) {
    my %services;
    for my $svc (@{$doc->{service} // []}) {
        my ($frag) = ($svc->{id} // '') =~ /#(.+)$/;
        next unless defined $frag;
        next if exists $services{$frag};
        $services{$frag} = {type => $svc->{type}, url => $svc->{serviceEndpoint}};
    }

    my %keys;
    for my $vm (@{$doc->{verificationMethod} // []}) {
        my ($frag) = ($vm->{id} // '') =~ /#(.+)$/;
        next unless defined $frag;
        next if exists $keys{$frag};
        next unless ($vm->{controller} // '') eq ($doc->{id} // '');
        $keys{$frag} = {type => $vm->{type}, public_key_multibase => $vm->{publicKeyMultibase}};
    }

    return {
        did           => $doc->{id},
        handle        => undef,
        also_known_as => $doc->{alsoKnownAs} // [],
        services      => \%services,
        keys          => \%keys,
    };
}

# Extracts an at:// handle URI from also_known_as, if present. Not
# trusted on its own - see lookup()'s bidirectional check.
sub _declared_handle($self, $identity) {
    for my $aka (@{$identity->{also_known_as}}) {
        return lc($1) if $aka =~ m{^at://(.+)$} && length($1);
    }
    return undef;
}

# The PDS service endpoint URL for a resolved identity hashref
sub pds_endpoint($self, $identity) {
    return $identity->{services}->{atproto_pds}->{url};
}

# --- The main entrypoint: bidirectionally-verified lookup ---

# Accepts a handle or a DID, returns a fully verified identity hashref.
sub lookup($self, $identifier) {
    return $self->_lookup_did($identifier) if $identifier =~ /^did:/;
    return $self->_lookup_handle($identifier);
}

# Handle -> DID -> DID doc -> the doc must declare this same handle
# back via alsoKnownAs, or the identity is untrustworthy (someone
# else's DID document could otherwise be presented for any handle).
sub _lookup_handle($self, $handle) {
    $handle = lc($handle);
    my $did      = $self->resolve_handle($handle);
    my $doc      = $self->resolve_did($did);
    my $identity = $self->_parse_identity($doc);
    my $declared = $self->_declared_handle($identity);

    die "could not verify handle/DID match: DID document for $did declares no handle\n"
        unless defined $declared;
    die "handle mismatch: DID document for $did declares '$declared', requested '$handle'\n"
        unless $declared eq $handle;

    $identity->{handle} = $declared;
    $self->log->debug("Identity: lookup('$handle') verified - did=$did") if DEBUG;
    return $identity;
}

# DID -> DID doc -> if a handle is declared, resolve *that* handle
# forward and confirm it points back to the same DID. A DID with no
# declared handle, or one that fails to verify, still resolves - it
# just carries no verified handle (identity->{handle} stays undef),
# same as indigo's handle.invalid convention.
sub _lookup_did($self, $did) {
    my $doc      = $self->resolve_did($did);
    my $identity = $self->_parse_identity($doc);
    my $declared = $self->_declared_handle($identity);

    if (defined $declared) {
        my $resolved_did;
        try {
            $resolved_did = $self->resolve_handle($declared);
        } catch($ex) {
            $self->log->debug('Identity: declared handle resolution exception: ', $ex) if DEBUG;
            $resolved_did = undef; 
        }
        $identity->{handle} = (defined($resolved_did) && $resolved_did eq $did) ? $declared : undef;
        $self->log->debug("Identity: lookup('$did') declared handle '$declared' - "
            . (defined($identity->{handle}) ? 'verified' : 'failed to verify, discarded')) if DEBUG;
    } else {
        $self->log->debug("Identity: lookup('$did') - no declared handle") if DEBUG;
    }

    return $identity;
}

# Async variant of lookup() - reuses the same pure, non-IO parsing/
# verification helpers (_parse_identity, _declared_handle) as the sync
# path; only the transport (resolve_handle_p/resolve_did_p) differs.
sub lookup_p($self, $identifier) {
    return $self->_lookup_did_p($identifier) if $identifier =~ /^did:/;
    return $self->_lookup_handle_p($identifier);
}

sub _lookup_handle_p($self, $handle) {
    $handle = lc($handle);
    return $self->resolve_handle_p($handle)->then(sub ($did) {
        return $self->resolve_did_p($did)->then(sub ($doc) {
            my $identity = $self->_parse_identity($doc);
            my $declared = $self->_declared_handle($identity);

            die "could not verify handle/DID match: DID document for $did declares no handle\n"
                unless defined $declared;
            die "handle mismatch: DID document for $did declares '$declared', requested '$handle'\n"
                unless $declared eq $handle;

            $identity->{handle} = $declared;
            $self->log->debug("Identity: lookup_p('$handle') verified - did=$did") if DEBUG;
            return $identity;
        });
    });
}

sub _lookup_did_p($self, $did) {
    return $self->resolve_did_p($did)->then(sub ($doc) {
        my $identity = $self->_parse_identity($doc);
        my $declared = $self->_declared_handle($identity);
        unless (defined $declared) {
            $self->log->debug("Identity: lookup_p('$did') - no declared handle") if DEBUG;
            return $identity;
        }

        return $self->resolve_handle_p($declared)->then(
            sub ($resolved_did) {
                $identity->{handle} = ($resolved_did eq $did) ? $declared : undef;
                $self->log->debug("Identity: lookup_p('$did') declared handle '$declared' - "
                    . (defined($identity->{handle}) ? 'verified' : 'failed to verify, discarded')) if DEBUG;
                return $identity;
            },
            sub ($err) {
                # resolve_handle_p rejects (rather than resolving undef)
                # when both DNS and well-known fail - that's still just
                # "couldn't verify," not a reason to fail the whole
                # lookup, same as the sync path's eval-and-ignore.
                $identity->{handle} = undef;
                return $identity;
            }
        );
    });
}

1;
