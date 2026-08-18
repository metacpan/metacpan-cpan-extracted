package Punk::OAuth2::Server::Store;

use 5.024;
use strict;
use warnings;

use Punk::OAuth2;

our $VERSION = '0.03';


1;

__END__

=head1 NAME

Punk::OAuth2::Server::Store - DBI storage for the authorization server

=head1 SYNOPSIS

	use Punk::OAuth2::Server::Store;

	# connect a fresh handle (tables auto-created)
	my $store = Punk::OAuth2::Server::Store->new(
		dsn => 'dbi:SQLite:idp.db', auto_migrate => 1);

	# or wrap a handle you already have
	my $store = Punk::OAuth2::Server::Store->new(dbh => $dbh);

	# register a client (secret is stored as a digest, never in clear)
	$store->client_put({
		client_id     => 'my-app',
		secret        => 'my-secret',
		redirect_uris => ['https://my-app/callback'],
		scopes        => 'read write',
	});

	# hand it to the authorization server
	oauth2_server '/oauth' => {
		issuer => 'https://idp.example.com',
		store  => $store,
		authenticate => 'Auth#require_user',
	};

=head1 DESCRIPTION

The default storage backend for L<Punk::OAuth2::Server>, implemented in
XS over DBI. Every credential - client secret, authorization code,
refresh token - is stored as a base64url SHA-256 digest, never in the
clear. The tables are created for you unless you pass
C<< auto_migrate => 0 >>.

The handle is fork-safe: when the store was opened from a C<dsn> and the
process id changes (a prefork worker), it reconnects automatically, so a
handle is never shared across a fork.

=head1 CONSTRUCTOR

=head2 new

	my $store = Punk::OAuth2::Server::Store->new(
		dsn          => 'dbi:SQLite:idp.db',
		user         => 'me',        # optional
		password     => 'secret',    # optional
		auto_migrate => 1,           # default; runs the schema
	);
	# or
	my $store = Punk::OAuth2::Server::Store->new(dbh => $existing_dbh);

Pass either a C<dsn> (with optional C<user>/C<password>) or an existing
C<dbh>. With a C<dsn> the store remembers how to reconnect after a fork;
a supplied C<dbh> is used as-is (you own its lifecycle).

=head1 METHODS

The authorization server calls these; you rarely call them yourself
except C<client_put> (and the other client operations) for provisioning.

=head2 client_put

	$store->client_put({
		client_id     => 'my-app',
		secret        => 'my-secret',   # omit for a public client
		name          => 'My Application',
		redirect_uris => ['https://my-app/callback'],
		grant_types   => 'authorization_code refresh_token',
		scopes        => 'read write',
		auth_method   => 'basic',       # or 'body'
		public        => 0,
	});

Inserts or replaces a client. C<secret> is digested on the way in; a
client with no secret is public (PKCE still applies).

=head2 client_get

	my $client = $store->client_get('my-app');
	# { client_id => ..., secret_digest => ..., redirect_uris => '[...]',
	#   scopes => ..., is_public => 0, ... }  or undef

Returns the client row (redirect_uris as the stored JSON array string),
or undef.

=head2 code_put / code_take

	$store->code_put($code, {
		client_id      => 'my-app',
		user_id        => 'alice',
		redirect_uri   => 'https://my-app/callback',
		scope          => 'read',
		nonce          => $nonce,        # OIDC, optional
		code_challenge => $s256_challenge,
		expires        => time + 600,
	});

	my $rec = $store->code_take($code);   # returns the record and
	                                      # deletes it (single use)

C<code_put> stores C<sha256($code)> with the bound fields; C<code_take>
returns the record once and removes it, so a code cannot be replayed.

=head2 refresh_put / refresh_take / refresh_rotate / refresh_revoke_family

	$store->refresh_put($token, {
		family_id => $family,   # groups a rotation chain
		client_id => 'my-app',
		user_id   => 'alice',
		scope     => 'read',
		expires   => time + 30*86400,
	});

	my $rec = $store->refresh_take($token);   # look up (does not delete)
	# { family_id, client_id, user_id, scope, expires,
	#   rotated_to, revoked }  or undef

	$store->refresh_rotate($token, $new_digest);  # mark $token consumed
	$store->refresh_revoke_family($family);       # kill the whole chain

Rotation marks the old token with C<rotated_to>; presenting an
already-rotated token is treated as theft and revokes the family.

=head2 consent_get / consent_put

	$store->consent_put('alice', 'my-app', 'read write');
	my $c = $store->consent_get('alice', 'my-app');
	# { user_id, client_id, scopes, ... }  or undef

Records that a user approved a client for a set of scopes, so returning
users skip the consent screen.

=head2 purge_expired

	$store->purge_expired;   # delete expired codes and refresh tokens

=head2 migrate

	$store->migrate;   # (re)create the tables; idempotent

=head2 dbh

	my $dbh = $store->dbh;   # the underlying DBI handle

=head1 SCHEMA

C<migrate> (and C<< auto_migrate => 1 >>) creates four tables. The DDL
below is what the shipped store runs; the types are SQLite-friendly and
portable to Postgres. All timestamps are epoch seconds (C<INTEGER>), and
every credential column holds a base64url SHA-256 B<digest>, never a raw
value.

	CREATE TABLE oauth2_clients (
	    client_id      TEXT PRIMARY KEY,
	    secret_digest  TEXT,            -- NULL for a public client
	    name           TEXT,
	    redirect_uris  TEXT,            -- JSON array of exact URIs
	    grant_types    TEXT,            -- space-separated
	    scopes         TEXT,            -- space-separated
	    auth_method    TEXT,            -- 'basic' or 'body'
	    is_public      INTEGER DEFAULT 0,
	    created        INTEGER
	);

	CREATE TABLE oauth2_codes (
	    code_digest    TEXT PRIMARY KEY,  -- sha256(authorization code)
	    client_id      TEXT,
	    user_id        TEXT,
	    redirect_uri   TEXT,
	    scope          TEXT,
	    nonce          TEXT,              -- OIDC, may be NULL
	    code_challenge TEXT,             -- PKCE S256 challenge
	    expires        INTEGER
	);

	CREATE TABLE oauth2_refresh (
	    token_digest   TEXT PRIMARY KEY,  -- sha256(refresh token)
	    family_id      TEXT,              -- groups a rotation chain
	    client_id      TEXT,
	    user_id        TEXT,
	    scope          TEXT,
	    expires        INTEGER,
	    rotated_to     TEXT,              -- set once the token is rotated
	    revoked        INTEGER DEFAULT 0
	);

	CREATE TABLE oauth2_consents (
	    user_id        TEXT,
	    client_id      TEXT,
	    scopes         TEXT,
	    created        INTEGER,
	    PRIMARY KEY (user_id, client_id)
	);

A row's life cycle mirrors the L</METHODS>: C<oauth2_codes> rows are
inserted by C<code_put> and deleted by C<code_take> (single use);
C<oauth2_refresh> rows are inserted by C<refresh_put>, stamped with
C<rotated_to> by C<refresh_rotate>, and flipped C<revoked> by
C<refresh_revoke_family>; C<purge_expired> removes any code or refresh
row past its C<expires>.

=head1 CREATING YOUR OWN STORE

The C<store> passed to C<oauth2_server> is any object implementing the
contract below - a Redis store, an ORM-backed store, an in-memory store
for tests. The authorization server only ever calls these methods.

=head2 The digest convention

The server checks a client secret by comparing
C<base64url(sha256($presented_secret))> against the C<secret_digest> you
return from C<client_get>. So store client secrets - and, for safety,
codes and refresh tokens - as that same digest:

	use Crypt::JWS qw(sha256 b64url);
	sub digest { b64url(sha256($_[0])) }

=head2 The method contract

=over 4

=item client_get($client_id)

Return a hashref with C<client_id>, C<secret_digest> (the base64url
sha256 of the secret, or undef/empty for a public client), and
C<redirect_uris> (an arrayref B<or> a JSON array string - both are
accepted), or undef if unknown.

=item code_put($code, \%rec) / code_take($code)

Store the record under a digest of the raw C<$code>. C<code_take> must
return it B<once> and then make it unavailable (single use). The record
carries C<client_id>, C<user_id>, C<redirect_uri>, C<scope>, C<nonce>,
C<code_challenge>, C<expires>.

=item refresh_put($token, \%rec) / refresh_take($token)

Store under a digest of the raw C<$token>. C<refresh_take> returns the
record (with C<family_id>, C<client_id>, C<user_id>, C<scope>,
C<expires>, C<rotated_to>, C<revoked>) or undef; it does not delete.

=item refresh_rotate($token, $new_digest)

Mark the record for C<$token> as consumed by setting its C<rotated_to>
to the (already digested) C<$new_digest>. A later C<refresh_take> that
finds a non-empty C<rotated_to> signals reuse.

=item refresh_revoke_family($family_id)

Set C<revoked> on every refresh record sharing C<family_id>.

=item consent_get($user_id, $client_id) / consent_put($user_id, $client_id, $scopes)

Fetch/record a user's consent for a client.

=item purge_expired()

Delete expired codes and refresh tokens.

=back

=head2 A complete in-memory store

This is a working example (the one the test suite runs against the real
server). Swap the hashes for your backend of choice:

	package My::MemStore;
	use Crypt::JWS qw(sha256 b64url);
	sub _digest { b64url(sha256($_[0])) }

	sub new { 
		bless { 
			clients=>{},
			codes=>{},
			refresh=>{},
	    	consents=>{} 
		}, shift 
	}

	sub client_put {
		my ($self, $c) = @_;
		$self->{clients}{ $c->{client_id} } = {
			client_id     => $c->{client_id},
			secret_digest => (length($c->{secret} // ''))
			    ? _digest($c->{secret}) : undef,
			redirect_uris => $c->{redirect_uris} // [],
			scopes        => $c->{scopes},
		};
	}
	sub client_get {
		my ($self, $id) = @_;
		my $c = $self->{clients}{$id} or return undef;
		return { %$c };
	}

	sub code_put  { $_[0]{codes}{ _digest($_[1]) } = { %{ $_[2] } } }
	sub code_take { delete $_[0]{codes}{ _digest($_[1]) } }

	sub refresh_put {
		my ($self, $token, $rec) = @_;
		$self->{refresh}{ _digest($token) } =
			{ %$rec, revoked => 0, rotated_to => undef };
	}
	sub refresh_take {
		my $r = $_[0]{refresh}{ _digest($_[1]) } or return undef;
		return { %$r };
	}
	sub refresh_rotate {
		my ($self, $token, $new) = @_;
		my $r = $self->{refresh}{ _digest($token) } or return;
		$r->{rotated_to} = $new;
	}
	sub refresh_revoke_family {
		my ($self, $fam) = @_;
		($_->{family_id} // '') eq $fam and $_->{revoked} = 1
			for values %{ $self->{refresh} };
	}

	sub consent_get { $_[0]{consents}{"$_[1]\0$_[2]"} }
	sub consent_put {
		$_[0]{consents}{"$_[1]\0$_[2]"} =
			{ user_id => $_[1], client_id => $_[2], scopes => $_[3] };
	}
	sub purge_expired { }   # no-op for the demo

Then: C<< oauth2_server '/oauth' => { ..., store => My::MemStore->new } >>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
