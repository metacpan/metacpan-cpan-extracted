package ObjectDB::Util;

use strict;
use warnings;

use base 'Exporter';

our $VERSION   = '3.26';
our @EXPORT_OK = qw(load_class execute to_array merge_rows filter_columns);

require Carp;
require Storable;

sub load_class {
    my ($class) = @_;

    Carp::croak('class name is required') unless $class;

    Carp::croak("Invalid class name '$class'")
      unless $class =~ m/^[[:lower:]\d:]+$/smxi;

    my $path = $class;
    $path =~ s{::}{/}smxg;
    $path .= '.pm';

    return 1 if exists $INC{$path} && defined $INC{$path};

    {
        no strict 'refs';

        for (keys %{"$class\::"}) {
            return 1 if defined &{$_};
        }
    }

    eval {
        require $path;

        1;
    } or do {
        my $e = $@;

        delete $INC{$path};

        {
            no strict 'refs';
            %{"$class\::"} = ();
        }

        Carp::croak($e);
    };
}

sub execute {
    my ($dbh, $stmt) = @_;

    my $sql  = $stmt->to_sql;
    my @bind = $stmt->to_bind;

    my $sth = $dbh->prepare($sql);
    my $rv  = $sth->execute(@bind);

    return wantarray ? ($rv, $sth) : $rv;
}

sub force_arrayrefs {
    my ($data, $defaults) = @_;

    my $clone = Storable::dclone($data);

    foreach my $key (keys %$defaults) {
        if (!exists $clone->{$key}) {
            $clone->{$key} = [ @{ $defaults->{$key} } ];
        }
        elsif (!ref $clone->{$key}) {
            $clone->{$key} = [ $clone->{$key} ];
        }

        push @{ $clone->{$key} }, @{ $defaults->{$key} };

    }

    return $clone;
}

sub to_array {
    my ($data) = @_;

    return () unless defined $data;

    return @$data if ref $data eq 'ARRAY';

    return ($data);
}

sub merge_rows {
    my $rows = shift;

    my $merged = [];

    my %order;
  NEXT_MERGE: while (@$rows) {
        my $row = shift @$rows;

        my $row_sign = '';
        foreach my $key (sort keys %$row) {
            my $value = $row->{$key};
            $value = \'join' if ref $value eq 'HASH' || ref $value eq 'ARRAY';

            $value = \undef unless defined $value;
            $row_sign .= "$key=$value";
        }

        if (!exists $order{$row_sign}) {
            $order{$row_sign} = $row;

            push @$merged, $row;
            next NEXT_MERGE;
        }

        my $prev = $order{$row_sign};

        foreach my $key (keys %$row) {
            next
              unless ref $prev->{$key} eq 'HASH'
              || ref $prev->{$key} eq 'ARRAY';

            my $prev_row =
              ref $prev->{$key} eq 'ARRAY'
              ? $prev->{$key}->[-1]
              : $prev->{$key};

            my $merged_rows = merge_rows([ $prev_row, $row->{$key} ]);
            if (@$merged_rows > 1) {
                my $prev_rows =
                  ref $prev->{$key} eq 'ARRAY'
                  ? $prev->{$key}
                  : [ $prev->{$key} ];
                pop @$prev_rows;
                $prev->{$key} = [ @$prev_rows, @$merged_rows ];
            }
        }
    }

    return $merged;
}

sub filter_columns {
    my ($meta_columns, $params) = @_;

    my @columns;
    if ($params->{columns}) {
        push @columns, to_array($params->{columns}) if $params->{columns};
    }
    else {
        push @columns, @$meta_columns;
    }

    push @columns, to_array($params->{'+columns'}) if $params->{'+columns'};
    if ($params->{'-columns'}) {
        my $minus_columns = { map { $_ => 1 } to_array($params->{'-columns'}) };

        @columns = grep { !exists $minus_columns->{ ref($_) ? $_->{'-col'} : $_ } } @columns;
    }

    return \@columns;
}

1;
