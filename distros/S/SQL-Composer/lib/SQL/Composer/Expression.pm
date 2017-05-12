package SQL::Composer::Expression;

use strict;
use warnings;

require Carp;
use Storable ();
use SQL::Composer::Quoter;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $expr = $params{expr} || [];
    $expr = [$expr] unless ref $expr eq 'ARRAY';

    my $self = {};
    bless $self, $class;

    $self->{default_prefix} = $params{default_prefix};

    $self->{quoter} =
      $params{quoter} || SQL::Composer::Quoter->new(driver => $params{driver});

    my ($sql, $bind) = $self->_build_subexpr('-and', $expr);

    $self->{sql}  = $sql;
    $self->{bind} = $bind;

    return $self;
}

sub _build_subexpr {
    my $self = shift;
    my ($op, $params) = @_;

    $params = Storable::dclone($params);

    $op = uc $op;
    $op =~ s{-}{};

    my @parts;
    my @bind;
    while (my ($key, $value) = splice(@$params, 0, 2)) {
        my $quote = 1;
        if (ref $key) {
            $quote = 0;

            my ($_key, $_bind) = $self->_build_value($key);

            $key = $_key;
            push @bind, @$_bind;
        }

        if ($key eq '-or' || $key eq '-and') {
            my ($sql, $bind) = $self->_build_subexpr($key, $value);
            push @parts, '(' . $sql . ')';
            push @bind,  @$bind;
        }
        elsif (ref $value eq 'HASH') {
            my ($op)       = keys %$value;
            my ($subvalue) = values %$value;

            if ($op eq '-col') {
                push @parts,
                  $self->_quote($quote, $key) . ' = ' . $self->_quote(1, $subvalue);
            }
            else {
                my ($_value, $_bind) = $self->_build_value($subvalue);

                push @parts, $self->_quote($quote, $key) . " $op $_value";
                push @bind, @$_bind;
            }
        }
        elsif (defined $value) {
            my ($_value, $_bind) = $self->_build_value($value);

            my $op = ref($value) && ref($value) eq 'ARRAY' ? '' : '= ';
            push @parts, $self->_quote($quote, $key) . " $op$_value";
            push @bind, @$_bind;
        }
        else {
            push @parts, $key;
        }
    }

    my $sql = join " $op ", @parts;

    return ($sql, \@bind);
}

sub _build_value {
    my $self = shift;
    my ($value) = @_;

    my $sql;
    my @bind;
    if (ref $value eq 'SCALAR') {
        $sql = $$value;
    }
    elsif (ref $value eq 'ARRAY') {
        $sql = 'IN (' . (join ',', split('', '?' x @$value)) . ')';
        push @bind, @$value;
    }
    elsif (ref $value eq 'REF') {
        if (ref $$value eq 'ARRAY') {
            $sql = $$value->[0];
            push @bind, @$$value[1 .. $#{$$value}];
        }
        else {
            Carp::croak('unexpected reference');
        }
    }
    elsif (ref($value) eq 'HASH') {
        my ($key)      = keys %$value;
        my ($subvalue) = values %$value;

        if ($key eq '-col') {
            $sql = $self->_quote(1, $subvalue);
        }
        else {
            Carp::croak('unexpected reference');
        }
    }
    else {
        $sql  = '?';
        @bind = ($value);
    }

    ($sql, \@bind);
}

sub to_sql { shift->{sql} }
sub to_bind { @{shift->{bind} || []} }

sub _quote {
    my $self = shift;
    my ($yes, $column) = @_;

    return $column unless $yes;

    return $self->{quoter}->quote($column, $self->{default_prefix});
}

1;
__END__

=pod

=head1 NAME

SQL::Composer - sql builder

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Raw SQL

    my $expr = SQL::Composer::Expression->new(expr => \'a = b');

    my $sql = $expr->to_sql;   # 'a = b'
    my @bind = $expr->to_bind; # []

=head2 Raw SQL with bind

    my $expr = SQL::Composer::Expression->new(expr => \['a = ?', 'b']);

    my $sql = $expr->to_sql;   # 'a = ?'
    my @bind = $expr->to_bind; # 'b'

=head2 Simple SQL

    my $expr = SQL::Composer::Expression->new(expr => [a => 'b']);

    my $sql = $expr->to_sql;
    is $sql, '`a` = ?';
    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];

=head2 Expression with custom operator

    my $expr = SQL::Composer::Expression->new(expr => [a => {'>' => 'b'}]);

    my $sql = $expr->to_sql;
    is $sql, '`a` > ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];

=head2 Expression with column name

    my $expr = SQL::Composer::Expression->new(expr => [a => {'-col' => 'b'}]);

    my $sql = $expr->to_sql;
    is $sql, '`a` = `b`';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];

=head2 Mixed logical expression

    my $expr =
      SQL::Composer::Expression->new(
        expr => [-or => [a => 'b', -and => [c => 'd', 'e' => 'f']]]);

    my $sql = $expr->to_sql;   # '(`a` = ? OR (`c` = ? AND `e` = ?))'
    my @bind = $expr->to_bind; # ['b', 'd', 'f']

=head2 C<IN>

    my $expr = SQL::Composer::Expression->new(expr => [a => ['b', 'c', 'd']]);

    my $sql = $expr->to_sql;   # '`a` IN (?,?,?)'
    my @bind = $expr->to_bind; # ['b', 'c', 'd']

=cut
