package Role::TinyCommons::BinarySearch::LinesInHandle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-07'; # DATE
our $DIST = 'Role-TinyCommons-BinarySearch-LinesInHandle'; # DIST
our $VERSION = '0.001'; # VERSION

use Role::Tiny;

requires 'fh';

# optionally depended methods
# fh_min_offset
# fh_max_offset
# cmp_items

# provided methods

sub has_item {
    require File::SortedSeek::PERLANCAR;

    my ($self, $item) = @_;

    my $fh = $self->fh;
    my $fh_min_offset = $self->can('fh_min_offset') ? $self->fh_min_offset : 0;
    my $fh_max_offset = $self->can('fh_max_offset') ? $self->fh_max_offset : undef;

    my $tell;
    if ($self->can('cmp_items')) {
        $tell = File::SortedSeek::PERLANCAR::binsearch($fh, $item, sub { $self->cmp_items(@_) }, undef, $fh_min_offset, $fh_max_offset);
    } else {
        $tell = File::SortedSeek::PERLANCAR::alphabetic($fh, $item, undef, $fh_min_offset, $fh_max_offset);
    }

    return 0 unless File::SortedSeek::PERLANCAR::was_exact();
    return 0 unless defined $tell;
    1;
}

1;
# ABSTRACT: Provide has_item() that uses binary search

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::BinarySearch::LinesInHandle - Provide has_item() that uses binary search

=head1 VERSION

This document describes version 0.001 of Role::TinyCommons::BinarySearch::LinesInHandle (from Perl distribution Role-TinyCommons-BinarySearch-LinesInHandle), released on 2021-05-07.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 REQUIRED METHODS

=head2 fh

Must return the filehandle.

=head1 OPTIONALLY DEPENDED METHODS

=head2 fh_min_offset

Must return the minimum position (in bytes) to search the filehandle from.

If this method is not supported by object, 0 will be assumed.

=head2 fh_max_offset

Must return the maximum position (in bytes) to search the filehandle to. Can
also return C<undef>, in which case the filehandle will be C<stat()>-ed to find
out the size of the file.

If this method is not supported by object, the filehandle will also be
C<stat()>-ed.

=head2 cmp_items

Usage:

 my $res = $obj->cmp_items($item1, $item2); # 0|-1|1

Must return 0, -1, or 1 like Perl's C<cmp> or C<< <=> >> operator. Note that
L<Role::TinyCommons::Collection::CompareItems> also uses this method.

=head1 PROVIDED METHODS

=head2 has_item

Usage:

 my $has_item = $obj->has_item($item); # bool

Return true if C<$item> is found in the filehandle (searched using binary
search), false otherwise.

Note that the L<Role::TinyCommons::Collection::FindItem> role also uses this
method.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-BinarySearch-LinesInHandle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-BinarySearch-LinesInHandle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Role-TinyCommons-BinarySearch-LinesInHandle/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
