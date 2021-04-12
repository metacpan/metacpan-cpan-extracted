package TableDataRole::Spec::Seekable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-11'; # DATE
our $DIST = 'TableData'; # DIST
our $VERSION = '0.1.5'; # VERSION

use Role::Tiny;

requires 'set_row_iterator_index';

sub get_row_arrayref_at_index {
    my ($table, $index) = @_;
    $table->set_row_iterator_index($index);
    $table->get_row_arrayref;
}

sub get_row_hashref_at_index {
    my ($table, $index) = @_;
    $table->set_row_iterator_index($index);
    $table->get_row_hashref;
}

1;
# ABSTRACT: Required methods for seekable TableData::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Spec::Seekable - Required methods for seekable TableData::* modules

=head1 VERSION

This document describes version 0.1.5 of TableDataRole::Spec::Seekable (from Perl distribution TableData), released on 2021-04-11.

=head1 REQUIRED METHODS

=head2 set_row_iterator_index

Usage:

 $table->set_row_iterator_index($index);

C<$index> is a zero-based integer, where 0 refers to the first data row, 1 the
second, and so on. Negative index must also be supported, where -1 means the
last data row, -2 the second last, and so on.

Must die when seeking outside the range of data (e.g. there are only 5 data rows
and this method is called with argument 5 or 6 or -6).

=head1 PROVIDED METHODS

=head2 get_row_arrayref_at_index

Usage:

 my $row = $table->get_row_arrayref_at_index($index); # might die

Basically shortcut for:

 $table->set_row_iterator_index($index);
 $table->get_row_arrayref;

=head2 get_row_hashref_at_index

Usage:

 my $row = $table->get_row_hashref_at_index($index); # might die

Basically shortcut for:

 $table->set_row_iterator_index($index);
 $table->get_row_hashref;

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<TableDataRole::Spec::Basic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
