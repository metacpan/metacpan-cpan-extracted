## no critic: TestingAndDebugging::RequireUseStrict
package TableDataRole::Spec::Basic;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-25'; # DATE
our $DIST = 'TableData'; # DIST
our $VERSION = '0.2.6'; # VERSION

### constructor

requires 'new';

### mixins

with 'Role::TinyCommons::Iterator::Resettable';

### additional method names to return hashref

requires 'get_next_row_hashref';

### column information

requires 'get_column_count';
requires 'get_column_names';

### aliases, for convenience and clarity

sub has_next_row {
    my $self = shift;
    $self->has_next_item(@_);
}

sub get_next_row_arrayref {
    my $self = shift;
    $self->get_next_item(@_);
}

sub get_row_count {
    my $self = shift;
    $self->get_item_count(@_);
}

sub get_all_rows_arrayref {
    my $self = shift;
    $self->get_all_items(@_);
}

sub get_all_rows_hashref {
    my $self = shift;

    my @items;
    $self->reset_iterator;
    while ($self->has_next_item) {
        my $row = $self->get_next_row_hashref;
        push @items, $row;
    }
    @items;
}

sub each_row_arrayref {
    my $self = shift;
    $self->each_item(@_);
}

sub each_row_hashref {
    my ($self, $coderef) = @_;

    $self->reset_iterator;
    my $index = 0;
    while ($self->has_next_item) {
        my $row = $self->get_next_row_hashref;
        my $res = $coderef->($row, $self, $index);
        return 0 unless $res;
        $index++;
    }
    return 1;
}

sub convert_row_arrayref_to_hashref {
    my ($self, $row_arrayref) = @_;

    my $row_hashref = {};
    my @column_names = $self->get_column_names;
    for my $i (0 .. $#column_names) {
        $row_hashref->{ $column_names[$i] } = $row_arrayref->[$i];
    }
    $row_hashref;
}

sub convert_row_hashref_to_arrayref {
    my ($self, $row_hashref) = @_;

    my $row_arrayref = [];
    my @column_names = $self->get_column_names;
    for my $i (0 .. $#column_names) {
        $row_arrayref->[$i] = $row_hashref->{ $column_names[$i] };
    }
    $row_arrayref;
}

1;
# ABSTRACT: Basic interface for all TableData::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Spec::Basic - Basic interface for all TableData::* modules

=head1 VERSION

This document describes version 0.2.6 of TableDataRole::Spec::Basic (from Perl distribution TableData), released on 2023-11-25.

=head1 DESCRIPTION

C<TableData::*> modules let you iterate rows using a resettable iterator
interface (L<Role::TinyCommons::Iterator::Resettable>). They also let you get
information about the columns.

 category                     method name                note                        modifies iterator?
 --------                     -----------                -------                     ------------------
 instantiating                new(%args)                                             N/A

 iterating rows               has_next_item()                                        no
                              has_next_row()             Alias for has_next_item()   no
                              get_next_item()                                        yes (moves forward 1 position)
                              get_next_row_arrayref()    Alias for get_next_item()   yes (moves forward 1 position)
                              get_next_row_hashref()                                 yes *moves forward 1 position)
                              reset_iterator()                                       yes (resets)

 iterating rows (alt)         each_item()                                            yes (resets)
                              each_row_arrayref()        Alias for each_item()       yes (resets)
                              each_row_hashref()                                     yes (resets)

 getting all rows             get_all_items()                                        yes (resets)
                              get_all_rows_arrayref()    Alias for get_all_items()   yes (resets)
                              get_all_rows_hashref()                                 yes (resets)

 getting row count            get_item_count()                                       yes (resets) / no (for some implementations)
                              get_row_count()            Alias for get_item_count()  yes (resets) / no (for some implementations)

 getting column information   get_column_names()                                     no
                              get_column_count()                                     no


 utility: convert row format  convert_row_arrayref_to_hashref()                      no
                              convert_row_hashref_to_arrayref()                      no

=head1 REQUIRED METHODS

=head2 new

Usage:

 my $table = TableData::Foo->new([ %args ]);

Constructor. Must accept a pair of argument names and values.

=head2 has_next_item

Usage:

 $table->has_next_item; # bool

Must return true if table has next row when iterating, false otherwise.

From L<Role::TinyCommons::Iterator::Resettable>.

=head2 reset_iterator

Usage:

 $table->reset_iterator;

Reset iterator so that the next L</get_next_item> retrieves the first row.

From L<Role::TinyCommons::Iterator::Resettable>.

=head2 get_iterator_pos

Usage:

 $table->get_iterator_pos;

Get iterator position.

From L<Role::TinyCommons::Iterator::Resettable>.

=head2 get_next_item

Usage:

 my $row_arrayref = $table->get_next_item;

Must return the next row as arrayref. See also L</get_next_row_hashref>.

=head2 get_next_row_hashref

Usage:

 my $row_hashref = $table->get_next_row_hashref;

Must return the next row as arrayref. See also L</get_next_row_arrayref> (a.k.a.
L</get_next_item>).

=head2 get_column_count

Usage:

 my $n = $table->get_column_count;

Must return the number of columns of the table.

All tables must have finite number of columns.

Should not reset iterator.

=head2 get_column_names

Usage:

 my @colnames = $table->get_column_names;
 my $colnames = $table->get_column_names;

Must return a list (or arrayref) containing the names of columns, ordered. For
ease of use, when in list context the method must return a list, and in scalar
context must return an arrayref.

Should not reset iterator.

=head1 PROVIDED METHODS

=head2 get_item_count

Usage:

 my $count = $table->get_item_count;

Return the number of data rows in the table. Resets the row iterator (see
L</get_row_arrayref> and L</reset_iterator>).

A table with infinite data rows can return -1.

The default implementation will call L</reset_iterator>, call L</has_next_item>
and L</get_next_item> repeatedly until there is no more row, then return the
counted number of rows. If your source data is already in an array or some other
form where the count is easily known, you can replace the implementation with a
more efficient one.

=head2 get_row_count

Alias for L</get_item_count>.

=head2 has_next_row

Alias for L</has_next_item>.

=head2 get_next_row_arrayref

Alias for L</get_next_item>.

=head2 get_all_items

Usage:

 my @rows = $table->get_all_items;

Return all rows as a list of arrayrefs. Resets the row iterator. Basically
shortcut for:

 my @rows;
 $table->reset_iterator;
 while ($table->has_next_item) {
     push @rows, $table->get_next_item;
 }
 @rows;

You can provide a more efficient implementation if your source data allows it.

A table with infinite data rows can throw an exception if this method is called.

=head2 get_all_rows_arrayref

Alias for L</get_all_items>.

=head2 get_all_rows_hashref

Usage:

 my @rows = $table->get_all_rows_hashref;

Return all rows as a list of hashrefs. Resets the row iterator. Basically
shortcut for:

 my @rows;
 $table->reset_iterator;
 while ($table->has_next_item) {
     push @rows, $table->get_next_row_hashref;
 }
 @rows;

You can provide a more efficient implementation if your source data allows it.

A table with infinite data rows can throw an exception if this method is called.

=head2 each_item

Usage:

 $table->each_item($coderef);

Call C<$coderef> for each row. If C<$coderef> returns false, will immediately
return false and skip the rest of the rows. Otherwise, will return true.
Basically:

 $table->reset_iterator;
 my $index = 0;
 while ($table->has_next_item) {
     my $row = $table->get_next_item;
     my $res = $coderef->($row, $table, $index);
     return 0 unless $res;
     $index++;
 }
 return 1;

See also L</each_row_hashref>.

=head2 each_row_arrayref

Alias for L</each_item>.

=head2 each_row_hashref

Usage:

 $table->each_row_hashref($coderef);

Call C<$coderef> for each row. If C<$coderef> returns false, will immediately
return false and skip the rest of the rows. Otherwise, will return true.
Basically:

 $table->reset_iterator;
 my $index = 0;
 while ($table->has_next_item) {
     my $row = $table->get_next_row_hashref;
     my $res = $coderef->($row, $table, $index);
     return 0 unless $res;
     $index++;
 }
 return 1;

See also L</each_row_arrayref> (a.k.a. L</each_item>).

=head2 convert_row_arrayref_to_hashref

Usage:

 my $row_hashref = $td->convert_row_arrayref_to_hashref($row_arrayref);

=head2 convert_row_hashref_to_arrayref

Usage:

 my $row_arrayref = $td->convert_row_hashref_to_arrayref($row_hashref);

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
