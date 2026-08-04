package Mojolicious::Plugin::Fondation::Auth::Token::Schema::Result::ApiToken;
$Mojolicious::Plugin::Fondation::Auth::Token::Schema::Result::ApiToken::VERSION = '0.01';
# ABSTRACT: DBIx::Class Result class for api_tokens table

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/TimeStamp Core/);

__PACKAGE__->table('api_tokens');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
        extra => { openapi => { readOnly => 1 } },
    },

    user_id => {
        data_type   => 'integer',
        is_nullable => 0,
        extra => { openapi => { readOnly => 1 } },
    },

    token_hash => {
        data_type   => 'text',
        is_nullable => 0,
        extra => {
            openapi => {
                writeOnly => 1,
                minLength => 1,
                create    => { required => 0 },
            },
        },
    },

    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
        extra => { openapi => { minLength => 1, create => { required => 1 } } },
    },

    scopes => {
        data_type   => 'text',
        is_nullable => 1,
        extra => { openapi => { create => { required => 0 } } },
    },

    last_used_at => {
        data_type     => 'datetime',
        is_nullable   => 1,
        set_on_create => 0,
        set_on_update => 0,
        extra => { openapi => { readOnly => 1 } },
    },

    created_at => {
        data_type     => 'datetime',
        is_nullable   => 0,
        set_on_create => 1,
        set_on_update => 0,
        extra => { openapi => { readOnly => 1 } },
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['token_hash']);

# ── Relationship: ApiToken belongs to User ────────────────────────────
# Auth::Token has a hard dependency on Fondation::User,
# so this class is guaranteed to be loaded.

__PACKAGE__->belongs_to(
    'user',
    'Mojolicious::Plugin::Fondation::User::Schema::Result::User',
    { 'foreign.id' => 'self.user_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Auth::Token::Schema::Result::ApiToken - DBIx::Class Result class for api_tokens table

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Stores SHA-256 hashes of personal access tokens.

Each user can have multiple tokens, each identified by a unique name.

=head1 NAME

Mojolicious::Plugin::Fondation::Auth::Token::Schema::Result::ApiToken - DBIx::Class Result for api_tokens

=head1 COLUMNS

=over 4

=item id

Primary key, auto-increment.

=item user_id

Foreign key to C<users.id>. Auto-set from current_user on create.

=item token_hash

SHA-256 hex digest of the raw token. writeOnly — never returned to client.
Unique constraint.

=item name

Human-readable name for the token (e.g. "Script backup").

=item scopes

JSON array of permitted scopes (nullable, for future use).

=item last_used_at

Timestamp of last token usage (manual update, no C<set_on_update>).

=item created_at

Timestamp of token creation. Auto-set on create.

=back

=head1 RELATIONSHIPS

=over 4

=item user

Belongs to L<Mojolicious::Plugin::Fondation::User::Schema::Result::User>.

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation::Auth::Token>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
