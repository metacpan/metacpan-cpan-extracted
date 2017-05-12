package SQL::Composer::Join;

use strict;
use warnings;

require Carp;
use SQL::Composer::Quoter;
use SQL::Composer::Expression;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{quoter} = $params{quoter}
      || SQL::Composer::Quoter->new(
        driver         => $params{driver},
        default_prefix => $params{as} || $params{source}
      );

    my $sql = '';
    my @bind;

    $sql .= uc($params{op}) . ' ' if $params{op};
    $sql .= 'JOIN ';

    $sql .= $self->_quote($params{source}) . ' ';

    if (my $as = $params{as}) {
        $sql .= 'AS ' . $self->_quote($as) . ' ';
    }

    if (my $constraint = $params{on}) {
        my $expr = SQL::Composer::Expression->new(
            default_prefix => $params{as} || $params{source},
            quoter         => $self->{quoter},
            expr           => $constraint
        );
        $sql .= 'ON ' . $expr->to_sql;
        push @bind, $expr->to_bind;
    }
    elsif (my $column = $params{using}) {
        $sql .= 'USING ' . $self->_quote($column);
    }

    $self->{sql}  = $sql;
    $self->{bind} = \@bind;

    return $self;
}

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

=head1 NAME

SQL::Composer::Join - build joins

=head1 SYNOPSIS

    my $join = SQL::Composer::Join->new(source => 'table', on => [a => 'b']);

    my $sql = $join->to_sql;   # 'JOIN `table` ON `table`.`a` = ?'
    my @bind = $expr->to_bind; # ['b']

=head1 DESCRIPTION

Accepts and builds join statement using these parameters:

    <op> JOIN <source> AS <as> ( ON <on> | <USING> )

=cut
