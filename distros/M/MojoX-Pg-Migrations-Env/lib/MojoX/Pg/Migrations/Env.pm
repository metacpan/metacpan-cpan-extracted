package MojoX::Pg::Migrations::Env;

use Mojo::Base 'Mojo::Pg::Migrations', -signatures;

use Carp qw(croak);

# This will be changed automatically when running `mise run create:release`
our $VERSION = '0.2.0';

# Variables looked up by ${NAME} and ${NAME:-fallback} placeholders in migration sql
has env => sub { \%ENV };

# ${NAME}, ${NAME:-fallback} and the escaped form $${NAME} which is left alone
my $PLACEHOLDER = qr/\$(\$?)\{([A-Za-z_]\w*)(?::-([^}]*))?\}/;

# How a migration is named in error messages, a subclass can add what it knows about the migration
sub label_for ( $self, $version ) { return "Migration $version" }

# Placeholders used by a migration, in order of first appearance, as {name, fallback}
sub placeholders ( $self, $version )
{
    my ( %seen, @found );
    for my $way (qw(up down)) {
        my $sql = $self->{migrations}{$way}{$version} // next;
        while ( $sql =~ /$PLACEHOLDER/g ) {
            next if $1 || $seen{$2}++;
            push @found, { name => $2, fallback => $3 };
        }
    }
    return \@found;
}

# Where the value of a placeholder comes from and what it is, the only place that decides
sub resolve ( $self, $name, $fallback = undef )
{
    my $value = $self->env->{$name};
    return ( 'env',      $value )    if defined $value && length $value;
    return ( 'fallback', $fallback ) if defined $fallback;
    return ( 'missing',  undef );
}

# Same selection as the parent, with placeholders substituted per migration so an error can name it
sub sql_for ( $self, $from, $to )
{
    my ( $up, $down ) = @{ $self->{migrations} }{qw(up down)};
    if ( $from < $to ) {
        my @versions = sort { $a <=> $b } grep { $_ <= $to && $_ > $from } keys %$up;
        return join '', map { $self->_substitute( $up->{$_}, $_ ) } @versions;
    }
    my @versions = reverse sort { $a <=> $b } grep { $_ > $to && $_ <= $from } keys %$down;
    return join '', map { $self->_substitute( $down->{$_}, $_ ) } @versions;
}

sub _substitute ( $self, $sql, $version )
{
    $sql =~ s/$PLACEHOLDER/$1 ? _unescape($2, $3) : $self->_value($2, $3, $version)/ge;
    return $sql;
}

# An escaped placeholder as it was written, without the extra dollar
sub _unescape ( $name, $fallback )
{
    return "\${$name" . ( defined $fallback ? ":-$fallback" : '' ) . '}';
}

sub _value ( $self, $name, $fallback, $version )
{
    my ( $source, $value ) = $self->resolve( $name, $fallback );
    return $value unless $source eq 'missing';
    croak $self->label_for($version) . " needs environment variable $name, which is not set and has no fallback";
}

1;

=encoding utf8

=head1 NAME

MojoX::Pg::Migrations::Env - Mojo::Pg migrations that replace environment placeholders in their sql, sponsored by Fibia

=head1 SYNOPSIS

  use Mojo::Pg;
  use MojoX::Pg::Migrations::Env;

  my $pg = Mojo::Pg->new('postgresql://app@/app');
  $pg->migrations(MojoX::Pg::Migrations::Env->new(pg => $pg, name => 'app'));
  $pg->migrations->from_file('db/migrations.sql')->migrate;

  # Or look first
  for my $placeholder (@{$pg->migrations->placeholders(3)}) {
    my ($source, $value) = $pg->migrations->resolve($placeholder->{name}, $placeholder->{fallback});
    say "$placeholder->{name} ($source)";
  }

With C<db/migrations.sql> containing

  -- 3 up
  grant select on invoices to ${APP_READONLY_ROLE:-readonly};
  -- 3 down
  revoke select on invoices from ${APP_READONLY_ROLE:-readonly};

=head1 DESCRIPTION

L<MojoX::Pg::Migrations::Env> is a drop-in replacement for L<Mojo::Pg::Migrations>. It is a subclass
that loads, selects and applies migrations exactly like its parent, with one difference: placeholders in
the migration sql are replaced with values from the environment when the sql is produced. That lets
migrations refer to things that differ between environments, for example the name of a role to grant to.

Migrations without placeholders produce the same sql as they do with L<Mojo::Pg::Migrations>, so an
existing project can switch class without changing its migrations.

It requires L<Mojo::Pg> 4.04 or newer, the first release where L<Mojo::Pg::Migrations/"migrate"> gets its
sql from L<Mojo::Pg::Migrations/"sql_for">, L<Mojolicious> 7.51 or newer and Perl 5.20 or newer for
subroutine signatures.

=head1 PLACEHOLDERS

  grant select on invoices to ${APP_READONLY_ROLE:-readonly};

=over 2

=item ${NAME}

Replaced with the value of C<NAME> in L</"env">. A variable that is unset or empty is missing, and producing
the sql fails.

=item ${NAME:-fallback}

Replaced with the value of C<NAME> in L</"env">, or with the fallback when the variable is unset or empty.
The fallback is everything up to the closing brace and can be empty, as in C<${NAME:-}>.

=item $${NAME}

Left as the literal C<${NAME}>, and C<$${NAME:-fallback}> as the literal C<${NAME:-fallback}>. An escaped
placeholder is never looked up and never listed by L</"placeholders">.

=back

A name starts with a letter or an underscore, followed by letters, digits and underscores. Nothing else is
touched, so numbered parameters like C<$1> and dollar quoted function bodies (C<$$> and C<$tag$>) are safe
to use. Take care where a dollar quote is directly followed by a placeholder, because C<$$${NAME}> reads as
a dollar sign followed by the escaped form. Put whitespace between them.

Placeholders are replaced everywhere in the sql of a migration, also inside comments and string literals,
in both up and down sql. Values are inserted as they are, without quoting.

Values are looked up when the sql is produced, and all sql between two versions is produced before any of
it runs. A missing variable therefore aborts L<Mojo::Pg::Migrations/"migrate"> with nothing applied, and
only the migrations between the active and the target version need their variables set.

=head1 ATTRIBUTES

L<MojoX::Pg::Migrations::Env> inherits all attributes from L<Mojo::Pg::Migrations> and implements the
following new ones.

=head2 env

  my $env     = $migrations->env;
  $migrations = $migrations->env({APP_READONLY_ROLE => 'reporting'});

Variables that placeholders are looked up in, defaults to C<%ENV>.

=head1 METHODS

L<MojoX::Pg::Migrations::Env> inherits all methods from L<Mojo::Pg::Migrations> and implements the
following new ones.

=head2 label_for

  my $label = $migrations->label_for(3);

How a migration is named in error messages, defaults to C<Migration 3>. It is only called when an error is
raised. A subclass that knows more about its migrations than their version can override it, and the label
becomes the subject of the error.

  package My::Migrations;
  use Mojo::Base 'MojoX::Pg::Migrations::Env', -signatures;

  sub label_for ($self, $version) { "Migration $version (" . $self->title_of($version) . ')' }

  # Migration 3 (add readonly grants) needs environment variable APP_READONLY_ROLE, which is not ...

=head2 placeholders

  my $placeholders = $migrations->placeholders(3);

Placeholders used by a version's up and down sql, in order of first appearance, as hashes with C<name> and
C<fallback>, where the fallback is C<undef> for a required variable. A name used more than once is listed
once, with the fallback of its first appearance. Escaped placeholders are not listed.

=head2 resolve

  my ($source, $value) = $migrations->resolve('APP_READONLY_ROLE');
  my ($source, $value) = $migrations->resolve('APP_READONLY_ROLE', 'readonly');

Where the value for a placeholder comes from, and the value, without producing any sql. Never dies.

=over 2

=item env

L</"env"> has a value for the name that is not empty, which is the value returned.

=item fallback

L</"env"> has no value for the name, or an empty one, and a fallback was given, which is the value returned.

=item missing

L</"env"> has no value for the name, or an empty one, and there is no fallback. The value is C<undef>.

=back

=head2 sql_for

  my $sql = $migrations->sql_for(5, 10);

Same as L<Mojo::Pg::Migrations/"sql_for">, with the placeholders of every migration on the way replaced.
Dies when a variable is missing, naming the migration that needs it with L</"label_for">.

  Migration 3 needs environment variable APP_READONLY_ROLE, which is not set and has no fallback

=head1 SPONSORS

This module is sponsored by L<Fibia|https://fibia.dk>.

=head1 AUTHOR

David Jack Wange Olrik, C<djo@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026, David Jack Wange Olrik.

This program is free software, you can redistribute it and/or modify it under the terms of the MIT license. See the
C<LICENSE> file for the full text.

=head1 SEE ALSO

L<Mojo::Pg>, L<Mojo::Pg::Migrations>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
