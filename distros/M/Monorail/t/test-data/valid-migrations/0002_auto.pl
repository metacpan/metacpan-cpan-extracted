#!perl

use Moose;

with 'Monorail::Role::Migration';

__PACKAGE__->meta->make_immutable;


sub dependencies {
    return [qw/0001_auto/];
}

sub upgrade_steps {
    return [
        Monorail::Change::AddField->new(
          table => 'album',
          name => 'producer',
          is_nullable => 1,
          is_primary_key => 0,
          is_unique => 0,
          type => 'text',
          size => [
                256
          ],
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
        Monorail::Change::DropField->new(
          table => 'album',
          name => 'producer'
        ),
        # Monorail::Change::RunPerl->new(function => \&downgrade_extras),
    ];
}

sub downgrade_extras {
    my ($dbix) = @_;
    # Same drill as upgrade_extras - you know what to do!
}

1;
