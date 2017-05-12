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
          name => 'cd',
          fields => [
                      {
                        name => 'id',
                        default_value => undef,
                        is_nullable => 0,
                        is_primary_key => 1,
                        is_unique => 0,
                        size => [
                                  16
                                ],
                        type => 'bigserial'
                      },
                      {
                        name => 'artist',
                        default_value => undef,
                        is_nullable => 0,
                        is_primary_key => 0,
                        is_unique => 0,
                        size => [
                                  16
                                ],
                        type => 'integer'
                      },
                      {
                        name => 'title',
                        default_value => undef,
                        is_nullable => 0,
                        is_primary_key => 0,
                        is_unique => 0,
                        size => [
                                  256
                                ],
                        type => 'varchar'
                      },
                      {
                        name => 'rank',
                        default_value => 0,
                        is_nullable => 0,
                        is_primary_key => 0,
                        is_unique => 0,
                        size => [
                                  16
                                ],
                        type => 'integer'
                      },
                      {
                        name => 'isbn',
                        default_value => undef,
                        is_nullable => 1,
                        is_primary_key => 0,
                        is_unique => 0,
                        size => [
                                  256
                                ],
                        type => 'text'
                      },
                      {
                        name => 'released',
                        default_value => undef,
                        is_nullable => 1,
                        is_primary_key => 0,
                        is_unique => 0,
                        size => [
                                  16
                                ],
                        type => 'integer'
                      }
                    ]
        )
    ];
}

sub downgrade_steps {
    return Monorail::Change::DropTable(name => 'cd');
}

1;
