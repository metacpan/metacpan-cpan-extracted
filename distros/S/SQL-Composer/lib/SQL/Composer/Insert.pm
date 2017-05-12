package SQL::Composer::Insert;

use strict;
use warnings;

require Carp;
use SQL::Composer::Quoter;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = { table => $params{into} };
    bless $self, $class;

    $self->{quoter} =
      $params{quoter} || SQL::Composer::Quoter->new(driver => $params{driver});

    my $sql = '';
    my @bind;

    $sql .= 'INSERT INTO ';

    $sql .= $self->_quote($params{into});

    if ($params{values} && @{$params{values}}) {
        my @columns;
        my @values;
        while (my ($key, $value) = splice @{$params{values}}, 0, 2) {
            push @columns, $key;

            if (ref $value) {
                if (ref $value eq 'SCALAR') {
                    push @values, $$value;
                }
                elsif (ref $value eq 'REF') {
                    if (ref $$value eq 'ARRAY') {
                        push @values, $$value->[0];
                        push @bind,   @$$value[1 .. $#{$$value}];
                    }
                    else {
                        Carp::croak('unexpected reference');
                    }
                }
                else {
                    Carp::croak('unexpected reference');
                }
            }
            else {
                push @values, '?';
                push @bind,   $value;
            }
        }

        if (@columns) {
            $sql .= ' (' . (join ',', map { $self->_quote($_) } @columns) . ')';
            $sql .= ' VALUES (';
            $sql .= join ',', @values;
            $sql .= ')';
        }

        # save this for later ...
        $self->{columns} = \@columns;
    }
    else {
        my $driver = $params{driver};
        if ($driver && $driver =~ m/(?:sqlite|pg)/i) {
            $sql .= ' DEFAULT VALUES';
        }
        else {
            $sql .= ' () VALUES ()';
        }
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
    my ($column, $prefix) = @_;

    return $self->{quoter}->quote($column, $prefix);
}

1;
__END__

=pod

=head1

SQL::Composer::Insert - INSERT statement

=head1 SYNOPSIS

    my $insert =
      SQL::Composer::Insert->new(into => 'table', values => [foo => 'bar']);

    my $sql = $insert->to_sql;   # 'INSERT INTO `table` (`foo`) VALUES (?)'
    my @bind = $insert->to_bind; # ['bar']

=cut
