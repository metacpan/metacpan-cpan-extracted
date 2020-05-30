package TableData::Object::hash;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-29'; # DATE
our $DIST = 'TableData-Object'; # DIST
our $VERSION = '0.112'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent 'TableData::Object::Base';

sub new {
    my ($class, $data) = @_;

    bless {
        data         => $data,
        cols_by_name => {key=>0, value=>1},
        cols_by_idx  => ["key", "value"],
    }, $class;
}

sub row_count {
    my $self = shift;
    scalar keys %{ $self->{data} };
}

sub row {
    my ($self, $idx) = @_;
    # XXX not very efficient
    my $rows = $self->rows;
    $rows->[$idx];
}

sub row_as_aos {
    my ($self, $idx) = @_;
    # XXX not very efficient
    my $rows = $self->rows;
    $rows->[$idx];
}

sub row_as_hos {
    my ($self, $idx) = @_;
    # XXX not very efficient
    my $rows = $self->rows;
    my $row = $rows->[$idx];
    return undef unless $row;
    {key => $row->[0], value => $row->[1]};
}

sub rows {
    my $self = shift;
    $self->rows_as_aoaos;
}

sub rows_as_aoaos {
    my $self = shift;
    my $data = $self->{data};
    [map {[$_, $data->{$_}]} sort keys %$data];
}

sub rows_as_aohos {
    my $self = shift;
    my $data = $self->{data};
    [map {{key=>$_, value=>$data->{$_}}} sort keys %$data];
}

sub uniq_col_names {
    my $self = shift;

    my @res = ('key'); # by definition, hash key is unique
    my %mem;
    for (values %{$self->{data}}) {
        return @res unless defined;
        return @res if $mem{$_}++;
    }
    push @res, 'value';
    @res;
}

sub const_col_names {
    my $self = shift;

    # by definition, hash key is not constant
    my $i = -1;
    my $val;
    my $val_undef;
    for (values %{$self->{data}}) {
        $i++;
        if ($i == 0) {
            $val = $_;
            $val_undef = 1 unless defined $val;
        } else {
            if ($val_undef) {
                return () if defined;
            } else {
                return () unless defined;
                return () unless $val eq $_;
            }
        }
    }
    ('value');
}

sub switch_cols {
    die "Cannot switch column in hash table";
}

sub add_col {
    die "Cannot add_col in hash table";
}

sub set_col_val {
    my ($self, $name_or_idx, $value_sub) = @_;

    my $col_name = $self->col_name($name_or_idx);
    my $col_idx  = $self->col_idx($name_or_idx);

    die "Column '$name_or_idx' does not exist" unless defined $col_name;

    my $hash = $self->{data};
    if ($col_name eq 'key') {
        my $row_idx = -1;
        for my $key (sort keys %$hash) {
            $row_idx++;
            my $new_key = $value_sub->(
                table    => $self,
                row_idx  => $row_idx,
                row_name => $key,
                col_name => $col_name,
                col_idx  => $col_idx,
                value    => $hash->{$key},
            );
            $hash->{$new_key} = delete $hash->{$key}
                unless $key eq $new_key;
        }
    } else {
        my $row_idx = -1;
        for my $key (sort keys %$hash) {
            $row_idx++;
            $hash->{$key} = $value_sub->(
                table    => $self,
                row_idx  => $row_idx,
                row_name => $key,
                col_name => $col_name,
                col_idx  => $col_idx,
                value    => $hash->{$key},
            );
        }
    }
}

1;
# ABSTRACT: Manipulate hash via table object

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Object::hash - Manipulate hash via table object

=head1 VERSION

This document describes version 0.112 of TableData::Object::hash (from Perl distribution TableData-Object), released on 2020-05-29.

=head1 SYNOPSIS

To create:

 use TableData::Object qw(table);

 my $td = table({foo=>10, bar=>20, baz=>30});

or:

 use TableData::Object::hash;

 my $td = TableData::Object::hash->new({foo=>10, bar=>20, baz=>30});

=head1 DESCRIPTION

This class lets you manipulate a hash as a table object. The table will have two
columns named C<key> (containing hash keys) and C<value> (containing hash
values).

=for Pod::Coverage .+

=head1 METHODS

See L<TableData::Object::Base>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Object>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
