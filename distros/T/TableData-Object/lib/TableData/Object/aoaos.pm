package TableData::Object::aoaos;

our $DATE = '2021-01-10'; # DATE
our $VERSION = '0.113'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent 'TableData::Object::Base';

sub new {
    my ($class, $data, $spec) = @_;
    my $self = bless {
        data     => $data,
        spec     => $spec,
    }, $class;
    if ($spec) {
        $self->{cols_by_idx}  = [];
        my $ff = $spec->{fields};
        for (keys %$ff) {
            $self->{cols_by_idx}[ $ff->{$_}{pos} ] = $_;
        }
        $self->{cols_by_name} = {
            map { $_ => $ff->{$_}{pos} }
                keys %$ff
        };
    } else {
        if (@$data) {
            my $ncols = @{ $data->[0] };
            $self->{cols_by_idx}  = [ map {"column$_"} 0 .. $ncols-1 ];
            $self->{cols_by_name} = { map {("column$_" => $_)} 0..$ncols-1 };
        } else {
            $self->{cols_by_idx}  = [];
            $self->{cols_by_name} = {};
        }
    }
    $self;
}

sub row_count {
    my $self = shift;
    scalar @{ $self->{data} };
}

sub row {
    my ($self, $idx) = @_;
    $self->{data}[$idx];
}

sub row_as_aos {
    my ($self, $idx) = @_;
    $self->{data}[$idx];
}

sub row_as_hos {
    my ($self, $idx) = @_;
    my $row_aos = $self->{data}[$idx];
    return undef unless $row_aos;
    my $cols = $self->{cols_by_idx};
    my $row_hos = {};
    for my $i (0..$#{$cols}) {
        $row_hos->{$cols->[$i]} = $row_aos->[$i];
    }
    $row_hos;
}

sub rows {
    my $self = shift;
    $self->{data};
}

sub rows_as_aoaos {
    my $self = shift;
    $self->{data};
}

sub rows_as_aohos {
    my $self = shift;
    my $data = $self->{data};

    my $cols = $self->{cols_by_idx};
    my $rows = [];
    for my $aos (@{$self->{data}}) {
        my $row = {};
        for my $i (0..$#{$cols}) {
            $row->{$cols->[$i]} = $aos->[$i];
        }
        push @$rows, $row;
    }
    $rows;
}

sub uniq_col_names {
    my ($self, $which) = @_;

    my @res;
  COL:
    for my $colname (sort keys %{$self->{cols_by_name}}) {
        my $colidx = $self->{cols_by_name}{$colname};
        my %mem;
        for my $row (@{$self->{data}}) {
            next COL unless $#{$row} >= $colidx;
            next COL unless defined $row->[$colidx];
            next COL if $mem{ $row->[$colidx] }++;
        }
        push @res, $colname;
    }

    @res;
}

sub const_col_names {
    my ($self, $which) = @_;

    my @res;
  COL:
    for my $colname (sort keys %{$self->{cols_by_name}}) {
        my $colidx = $self->{cols_by_name}{$colname};
        my $i = -1;
        my $val;
        my $val_undef;
        for my $row (@{$self->{data}}) {
            next COL unless $#{$row} >= $colidx;
            $i++;
            if ($i == 0) {
                $val = $row->[$colidx];
                $val_undef = 1 unless defined $val;
            } else {
                if ($val_undef) {
                    next COL if defined;
                } else {
                    next COL unless defined $row->[$colidx];
                    next COL unless $val eq $row->[$colidx];
                }
            }
        }
        push @res, $colname;
    }

    @res;
}

sub del_col {
    my ($self, $name_or_idx) = @_;

    my $idx = $self->col_idx($name_or_idx);
    return undef unless defined $idx;

    my $name = $self->{cols_by_idx}[$idx];

    for my $row (@{$self->{data}}) {
        splice @$row, $idx, 1;
    }

    # adjust cols_by_{name,idx}
    for my $i (reverse 0..$#{$self->{cols_by_idx}}) {
        my $name = $self->{cols_by_idx}[$i];
        if ($i > $idx) {
            $self->{cols_by_name}{$name}--;
        } elsif ($i == $idx) {
            splice @{ $self->{cols_by_idx} }, $i, 1;
            delete $self->{cols_by_name}{$name};
        }
    }

    # adjust spec
    if ($self->{spec}) {
        my $ff = $self->{spec}{fields};
        for my $name (keys %$ff) {
            if (!exists $self->{cols_by_name}{$name}) {
                delete $ff->{$name};
            } else {
                $ff->{$name}{pos} = $self->{cols_by_name}{$name};
            }
        }
    }

    $name;
}

sub rename_col {
    my ($self, $old_name_or_idx, $new_name) = @_;

    my $idx = $self->col_idx($old_name_or_idx);
    die "Unknown column '$old_name_or_idx'" unless defined($idx);
    my $old_name = $self->{cols_by_idx}[$idx];
    die "Please specify new column name" unless length($new_name);
    return if $new_name eq $old_name;
    die "New column name must not be a number" if $new_name =~ /\A\d+\z/;

    $self->{cols_by_idx}[$idx] = $new_name;
    $self->{cols_by_name}{$new_name} = delete($self->{cols_by_name}{$old_name});
    if ($self->{spec}) {
        my $ff = $self->{spec}{fields};
        $ff->{$new_name} = delete($ff->{$old_name});
    }
}

sub switch_cols {
    my ($self, $name_or_idx1, $name_or_idx2) = @_;

    my $idx1 = $self->col_idx($name_or_idx1);
    die "Unknown first column '$name_or_idx1'" unless defined($idx1);
    my $idx2 = $self->col_idx($name_or_idx2);
    die "Unknown second column '$name_or_idx2'" unless defined($idx2);
    return if $idx1 == $idx2;

    my $name1 = $self->col_name($name_or_idx1);
    my $name2 = $self->col_name($name_or_idx2);

    ($self->{cols_by_idx}[$idx1], $self->{cols_by_idx}[$idx2]) =
        ($self->{cols_by_idx}[$idx2], $self->{cols_by_idx}[$idx1]);
    ($self->{cols_by_name}{$name1}, $self->{cols_by_name}{$name2}) =
        ($self->{cols_by_name}{$name2}, $self->{cols_by_name}{$name1});
    if ($self->{spec}) {
        my $ff = $self->{spec}{fields};
        ($ff->{$name1}, $ff->{$name2}) = ($ff->{$name2}, $ff->{$name1});
    }
}

sub add_col {
    my ($self, $name, $idx, $spec) = @_;

    die "Column '$name' already exists" if defined $self->col_name($name);
    my $col_count = $self->col_count;
    if (defined $idx) {
        die "Index must be between 0..$col_count"
            unless $idx >= 0 && $idx <= $col_count;
    } else {
        $idx = $col_count;
    }

    for (keys %{ $self->{cols_by_name} }) {
        $self->{cols_by_name}{$_}++ if $self->{cols_by_name}{$_} >= $idx;
    }
    $self->{cols_by_name}{$name} = $idx;
    splice @{ $self->{cols_by_idx} }, $idx, 0, $name;
    if ($self->{spec}) {
        my $ff = $self->{spec}{fields};
        for my $f (values %$ff) {
            $f->{pos}++ if defined($f->{pos}) && $f->{pos} >= $idx;
        }
        $ff->{$name} = defined($spec) ? {%$spec} : {};
        $ff->{$name}{pos} = $idx;
    }

    for my $row (@{ $self->{data} }) {
        splice @$row, $idx, 0, undef;
    }
}

sub set_col_val {
    my ($self, $name_or_idx, $value_sub) = @_;

    my $col_name = $self->col_name($name_or_idx);
    my $col_idx  = $self->col_idx($name_or_idx);

    die "Column '$name_or_idx' does not exist" unless defined $col_name;

    for my $i (0..$#{ $self->{data} }) {
        my $row = $self->{data}[$i];
        $row->[$col_idx] = $value_sub->(
            table    => $self,
            row_idx  => $i,
            col_name => $col_name,
            col_idx  => $col_idx,
            value    => $row->[$col_idx],
        );
    }
}

1;
# ABSTRACT: Manipulate array of arrays-of-scalars via table object

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Object::aoaos - Manipulate array of arrays-of-scalars via table object

=head1 VERSION

This document describes version 0.113 of TableData::Object::aoaos (from Perl distribution TableData-Object), released on 2021-01-10.

=head1 SYNOPSIS

To create:

 use TableData::Object qw(table);

 my $td = table([[1,2,3], [4,5,6]]);

or:

 use TableData::Object::aoaos;

 my $td = TableData::Object::aoaos->new([[1,2,3], [4,5,6]]);

=head1 DESCRIPTION

This class lets you manipulate an array of arrays-of-scalars as a table object.
The table will have column names C<column0>, C<column1>, and so on. The first
array-of-scalars will determine the number of columns (unless if you also give
C<spec>).

=for Pod::Coverage .+

=head1 METHODS

See L<TableData::Object::Base>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-TableData-Object/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
