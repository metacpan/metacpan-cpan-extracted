package SQL::Composer::Upsert;

use strict;
use warnings;

use base 'SQL::Composer::Insert';

use SQL::Composer::Insert;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $driver = $params{driver}
      || die 'Cannot create an Upsert object without specifying a `driver`';

    my $self = $class->SUPER::new(%params);
    my $sql  = $self->{sql};

    if ($driver =~ m/sqlite/i) {
        $sql =~ s/^INSERT /INSERT OR REPLACE /;
    }
    elsif ($driver =~ m/mysql/i) {
        $sql .= ' ON DUPLICATE KEY UPDATE ' . (
            join ', ' => map {
                my $c = $self->_quote($_);
                ($c . ' = VALUES(' . $c . ')')
            } @{$self->{columns}}
        );
    }
    elsif ($driver =~ m/pg/i) {
        $sql .= ' ON CONFLICT DO UPDATE';
    }
    else {
        die 'The Upsert `driver` (' . $driver . ') is not supported';
    }

    $self->{sql} = $sql;

    return $self;
}

1;
__END__

=pod

=head1

SQL::Composer::Upsert - UPSERT statement emulation

=head1 SYNOPSIS

    my $upsert = SQL::Composer::Upsert->new(
        into   => 'table',
        values => [ id => 1, foo => 'bar' ],
        driver => $driver # driver must be set
    );

    my $sql = $upsert->to_sql;
    # SQLite: 'INSERT INTO `table` (`id`, `foo`) VALUES (?, ?) ON CONFLICT UPDATE'
    # MySQL: 'INSERT INTO `table` (`id`, `foo`) VALUES (?, ?) ON DUPLICATE KEY UPDATE'
    # Pg: 'INSERT INTO `table` (`id`, `foo`) VALUES (?, ?) ON CONFLICT DO UPDATE'
    my @bind = $upsert->to_bind; # [1, 'bar']

=head1 DESCRIPTION

This emulates the C<UPSERT> statement, which is defined as an attempt to
C<INSERT> failing due to a key constraint and the query being turned into
an C<UPDATE> instead.

=head1 CAVEAT

Since this feature is not universally supported, you must specify a C<driver>
when creating C<SQL::Composer::Upsert> instance so that we can generate the
correct SQL.

It should also be noted that we support the lowest common denominator, which
is the basic C<UPSERT> behavior even though some RDBMS support more complex
features.

=cut
