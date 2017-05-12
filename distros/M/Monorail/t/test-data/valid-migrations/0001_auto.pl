#!perl

use Moose;

with 'Monorail::Role::Migration';

__PACKAGE__->meta->make_immutable;


sub dependencies {
    return [qw//];
}

sub upgrade_steps {
    return [
        Monorail::Change::CreateTable->new(
          name => 'album',
          fields => [
                      {
                        name => 'id',
                        default_value => undef,
                        is_nullable => 0,
                        is_primary_key => 1,
                        is_unique => 0,
                        type => 'bigserial',
                        size => [
                                  16
                                ],
                      },
                      {
                        name => 'artist',
                        default_value => undef,
                        is_nullable => 0,
                        is_primary_key => 0,
                        is_unique => 0,
                        type => 'integer',
                        size => [
                                  16
                                ],
                      },
                      {
                        name => 'title',
                        default_value => undef,
                        is_nullable => 0,
                        is_primary_key => 0,
                        is_unique => 0,
                        type => 'varchar',
                        size => [
                                  256
                                ],
                      },
                      {
                        name => 'rank',
                        default_value => 0,
                        is_nullable => 0,
                        is_primary_key => 0,
                        is_unique => 0,
                        type => 'integer',
                        size => [
                                  16
                                ],
                      },
                      {
                        name => 'isbn',
                        default_value => undef,
                        is_nullable => 1,
                        is_primary_key => 0,
                        is_unique => 0,
                        type => 'text',
                        size => [
                                  256
                                  ],
                      },
                      {
                        name => 'release_year',
                        default_value => undef,
                        is_nullable => 1,
                        is_primary_key => 0,
                        is_unique => 0,
                        type => 'integer',
                        size => [
                                  16
                                ],
                      }
                    ]
        ),
        # Monorail::Change::RunPerl->new(function => \&upgrade_extras),
    ];
}

sub upgrade_extras {
    my ($dbix) = @_;
    # $dbix gives you access to your DBIx::Class schema if you need to add
    # data do extra work, etc....
    #
    # For example:
    #
    #  $self->dbix->tnx_do(sub {
    #      $self->dbix->resultset('foo')->create(\%stuff)
    #  });
}

sub downgrade_steps {
    return [
        Monorail::Change::DropTable->new(
          name => 'album'
        ),
        # Monorail::Change::RunPerl->new(function => \&downgrade_extras),
    ];
}

sub downgrade_extras {
    my ($dbix) = @_;
    # Same drill as upgrade_extras - you know what to do!
}

1;
