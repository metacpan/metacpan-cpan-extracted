package SQL::Composer::Delete;

use strict;
use warnings;

require Carp;
use SQL::Composer::Quoter;
use SQL::Composer::Expression;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = { table => $params{from} };
    bless $self, $class;

    $self->{quoter} =
      $params{quoter} || SQL::Composer::Quoter->new(driver => $params{driver});

    my $sql = '';
    my @bind;

    $sql .= 'DELETE FROM ';

    $sql .= $self->_quote($params{from});

    if ($params{where}) {
        my $expr = SQL::Composer::Expression->new(
            quoter => $self->{quoter},
            expr   => $params{where}
        );
        $sql .= ' WHERE ' . $expr->to_sql;
        push @bind, $expr->to_bind;
    }

    if (defined(my $limit = $params{limit})) {
        $sql .= ' LIMIT ' . $limit;
    }

    if (defined(my $offset = $params{offset})) {
        $sql .= ' OFFSET ' . $offset;
    }

    $self->{sql}  = $sql;
    $self->{bind} = \@bind;

    return $self;
}

sub table { shift->{table} }

sub to_sql { shift->{sql} }
sub to_bind { @{shift->{bind} || []} }

sub _quote {
    my $self = shift;
    my ($column) = @_;

    return $self->{quoter}->quote($column);
}

1;
__END__

=pod

=head1

SQL::Composer::Delete - DELETE statement

=head1 SYNOPSIS

    my $delete = SQL::Composer::Delete->new(from => 'table', where => [a => 'b']);

    my $sql = $delete->to_sql;   # 'DELETE FROM `table` WHERE `a` = ?'
    my @bind = $delete->to_bind; # ['b']

=cut
