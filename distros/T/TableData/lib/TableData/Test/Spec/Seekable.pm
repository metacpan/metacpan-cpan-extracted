package TableData::Test::Spec::Seekable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-11'; # DATE
our $DIST = 'TableData'; # DIST
our $VERSION = '0.1.5'; # VERSION

use parent 'TableData::Test::Spec::Basic';
use Role::Tiny::With;

with 'TableDataRole::Spec::Seekable';

sub set_row_iterator_index {
    my ($table, $index) = @_;

    $index = int($index);
    if ($index >= 0) {
        die "Index out of range" unless $index < @{ $table->_rows };
        $table->{index} = $index;
    } else {
        die "Index out of range" unless -$index <= @{ $table->_rows };
        $table->{index} = @{ $table->_rows } + $index;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Test::Spec::Seekable

=head1 VERSION

This document describes version 0.1.5 of TableData::Test::Spec::Seekable (from Perl distribution TableData), released on 2021-04-11.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
