package Slick::Database;

use 5.036;

use Moo;
use Types::Standard qw(Str HashRef Int);
use Module::Runtime qw(require_module);
use Carp            qw(croak);
use Try::Tiny;

my $first_migration = {
    up => <<'EOF',
CREATE TABLE IF NOT EXISTS slick_migrations (
  id VARCHAR(255) PRIMARY KEY,
  up TEXT,
  down TEXT
);
EOF
    down => <<'EOF'
DROP TABLE slick_migrations;
EOF
};

has conn => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

has type => (
    is  => 'ro',
    isa => Str
);

has auto_migrate => (
    is      => 'rw',
    isa     => Int,
    default => sub { return 0; }
);

has migrations => (
    is      => 'ro',
    default => sub {
        return { 'create_slick_migrations_table' => $first_migration };
    }
);

has _executor => (
    is      => 'ro',
    handles => [qw(insert update delete select execute dbi)]
);

sub BUILD {
    my $self = shift;

    require_module('URI');

    my $uri = URI->new( $self->conn );

    if ( $uri->scheme =~ /^postgres(?:ql)?$/x ) {
        require_module('Slick::DatabaseExecutor::Pg');
        $self->{type} = 'Pg';
        $self->{_executor} =
          Slick::DatabaseExecutor::Pg->new( connection => $uri );
    }
    elsif ( $uri->scheme =~ /^mysql$/x ) {
        require_module('Slick::DatabaseExecutor::MySQL');
        $self->{type} = 'mysql';
        $self->{_executor} =
          Slick::DatabaseExecutor::MySQL->new( connection => $uri );
    }
    else {
        croak q{Unknown scheme or un-supported database: } . $uri->scheme;
    }

    try {
        no warnings;
        $self->dbi->do( $first_migration->{up} );
        $self->insert(
            'slick_migrations',
            {
                id   => 'create_slick_migrations_table',
                up   => $first_migration->{up},
                down => $first_migration->{down}
            }
        );
    }

    return $self;
}

sub migrate_up {
    my $self = shift;
    my $id   = shift;

    my $run_migrations = $self->select( 'slick_migrations', ['id'] );

    if ($id) {
        croak qq{Couldn't find migration: $id}
          unless exists $self->migrations->{$id};

        if ( not( grep { $_->{id} eq $id } $run_migrations->@* ) ) {
            my $migration = $self->migrations->{$id};
            $self->dbi->do( $migration->{up} )
              || croak qq{Couldn't migrate up $id - } . $self->dbi->errstr;

            $self->insert(
                'slick_migrations',
                {
                    id   => $id,
                    up   => $migration->{up},
                    down => $migration->{down}
                }
            );

            say qq{Migrated $id up successfully.};
        }
    }
    else {
        for ( keys $self->migrations->%* ) {
            my $key = $_;
            next
              if grep { $_->{id} eq $key } $run_migrations->@*;

            $self->dbi->do( $self->migration->{$_}->{up} )
              || croak qq{Couldn't migrate up $_ - } . $self->dbi->errstr;
            $self->insert(
                'slick_migrations',
                {
                    id   => $key,
                    up   => $_->{up},
                    down => $_->{down}
                }
            );

            say qq{Migrated $_ up successfully.};
        }
    }

    return $self;
}

sub migrate_down {
    my $self = shift;
    my $id   = shift;

    my $run_migrations = $self->select( 'slick_migrations', ['id'] );

    if ($id) {
        croak qq{Couldn't find migration: $id}
          unless exists $self->migrations->{$id};

        if ( not( grep { $_->{id} eq $id } $run_migrations->@* ) ) {
            my $migration = $self->migrations->{$id};
            $self->dbi->do( $migration->{down} )
              || croak qq{Couldn't migrate down $id - } . $self->dbi->errstr;
            $self->delete( 'slick_migrations', { id => $id } );

            say qq{Migrated $id down successfully.};
        }
    }
    else {
        for ( keys $self->migrations->%* ) {
            my $key = $_;
            next
              if grep { $_->{id} eq $key } $run_migrations->@*;

            $self->dbi->do( $self->migration->{$_}->{down} )
              || croak qq{Couldn't migrate down $_ - } . $self->dbi->errstr;
            $self->delete( 'slick_migrations', { id => $key } );

            say qq{Migrated $_ down successfully.};
        }
    }

    return $self;
}

sub migration {
    my ( $self, $id, $up, $down ) = @_;

    my $migration = {
        up   => $up,
        down => $down
    };

    $self->migrations->{$id} = $migration;

    if ( $self->auto_migrate ) {
        $self->migrate_up($id);
    }

    return $self;
}

1;

=encoding utf8

=head1 NAME

Slick::Database

=head1 SYNOPSIS

An OO wrapper around L<DBI> and L<SQL::Abstract>.

Currently L<Slick::Database> supports C<MySQL> and C<PostgreSQL>. Note, you will need to install the
driver that you'd like to use manually, as L<Slick> does not come bundled with any.

See C<Slick::DatabaseExecutor> for lower level information on how L<Slick::Database> works.

=head1 API

=head2 dbi

Returns the underlying L<DBI> driver object associated with the database.

=head2 execute

Runs some statement against the underlying L<DBI> driver object associated with the database.

=head2 select, select_one, update, delete, insert

    my $users = $s->database('my_postgres')
                ->select('users', [ 'id', 'name' ]); # SELECT id, name FROM users;

    my $user = $s->database('my_postgres')
                ->select_one('users', [ 'id', 'name', 'age' ], { id => 1 }); # SELECT id, name, age FROM users WHERE id = 1;

    $s->database('my_postgres')
      ->insert('users', { name => 'Bob', age => 23 }); # INSERT INTO users (name, age) VALUES ('Bob', 23);

    $s->database('my_postgres')
      ->update('users', { name => 'John' }, { id => 2 }); # UPDATE users SET name = 'John' WHERE id = 2;

    $s->database('my_postgres')
      ->delete('users', { id => 2 }); # DELETE FROM users WHERE id = 2;

Wrapper around L<SQL::Abstract>, see L<SQL::Abstract> for more information on how to use these methods.

See L<"dbi"> if you would like to directly use the L<DBI> connection instead of L<SQL::Abstract>.

=head2 migrations

    $s->database('db')->migrations;

Returns a C<HashRef> with all of the migrations associated with the database.

=head2 migration

    $s->database('db')->migration(
        'migration_id', # id
        'CREATE TABLE foo (id INT PRIMARY KEY);', # up
        'DROP TABLE foo;' # down
    );

Create a migration and associate it with the database.

=head2 migrate_up

    $s->database('db')->migrate_up;

Runs all pending migrations against the database.

If you wish to only migrate a single migration, you can provide the id of the migration
you'd like to run:

    $s->database('db')->migrate_up('migration_id');

=head2 migrate_down

    $s->database('db')->migrate_down;

Migrates all migrations down effectively destroying your database.

If you wish to only de-migrate a single migration, you can provide the id of the migration
you'd like to run:

    $s->database('db')->migrate_down('migration_id');

=head1 See also

=over2

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
