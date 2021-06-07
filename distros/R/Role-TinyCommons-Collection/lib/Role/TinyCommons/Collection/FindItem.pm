package Role::TinyCommons::Collection::FindItem;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-20'; # DATE
our $DIST = 'Role-TinyCommons-Collection'; # DIST
our $VERSION = '0.008'; # VERSION

use Role::Tiny;

### required methods

requires 'find_item';

### provided methods

sub has_item {
    my ($self, $item) = @_;
    my @results = $self->find_item(item => $item);
    @results ? 1:0;
}

1;
# ABSTRACT: The find_item() interface

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Collection::FindItem - The find_item() interface

=head1 VERSION

This document describes version 0.008 of Role::TinyCommons::Collection::FindItem (from Perl distribution Role-TinyCommons-Collection), released on 2021-05-20.

=head1 SYNOPSIS

In your class:

 package YourClass;
 use Role::Tiny::With;
 with 'Role::TinyCommons::Collection::FindItem';

 sub new { ... }
 sub find_item { ... }
 ...
 1;

In the code of your class user:

 use YourClass;

 my $obj = YourClass->new(...);

 # basic finding
 my @results = $obj->find_item(item => 'x');
 die "Not found" unless @results;

 # shortcut for the above
 die "Not found" unless $obj->has_item('x');

 # return all items instead of only the first
 my @results = $obj->find_item(item => 'x', all => 1);

 # return positions instead of the items themselves
 my @pos = $obj->find_item(item => 'x', return_pos => 1);

 # numeric comparison
 my @results = $obj->find_item(item => 10, numeric=>1);

=head1 DESCRIPTION

C<find_item()> is an interface to do exact matching and/or single-item searching
in a collection. Some options are provided. The implementor is given flexibility
to support additional options, but the basic modes of finding must be supported.

To search for multiple items based on some criteria, there is the
L<Role::TinyCommons::Collection::SelectItems> interface.

=head1 REQUIRED METHODS

=head2 find_item

Usage:

 my @results = $obj->find_item(%args);

Find an item. Must return the found items as a list. By default must return
either 0-item list if item is not found, or 1-item list if item is found. If
L</all> mode is turned on, can return more than one item. The item(s) themselves
must be returned, unless L</return_pos> mode is enabled, in which the positions
are returned instead.

Arguments:

=over

=item * item

Type: any. The item to search for. The item should be matched exactly with items
in the collection (using numerical or string-wise equality comparison, or
something like L<Data::Cmp>), unless approximate matching (L</approx>) is turned
on.

If implementor provides both numeric vs string-wise comparison for choosing, the
string-wise comparison must be the default and the numeric searching mode must
be turned on using the L</numeric> option.

This argument must be supported.

=item * return_pos

Type: bool. If set to true, must return found positions of items in the
collection instead of the items themselves.

This argument must be supported for ordered collection (where each item in the
collection has a fixed position).

=item * all

Type: bool. If set to true, must enable all mode, returning all instead of the
first item found.

This argument must be supported.

=item * numeric

Type: bool. If set to true, must enable numeric searching mode. Otherwise,
string-wise searching mode is the default.

This argument must be supported as a way to choose modes if both numeric and
stringwise searching modes are available.

=item * ignore_case

Type: bool. If set to true, must enable case-insensitive matching. Otherwise,
matching should be case-sensitive.

This argument is optional to implement. It should be supported if stringwise
comparison is used.

=item * approx

Type: bool. If set to true, must enable approximate matching.

This argument is optional to implement.

=back

Implementor is free to add more options.

=head1 PROVIDED METHODS

=head2 has_item

Usage:

 my $has_item = $obj->has_item($item);

Must return a bool, true if collection has item C<$item>, false otherwise.
Equivalent to:

 my @results = $obj->find_item(item => $item);
 return @results ? 1:0;

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Collection>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Role-TinyCommons-Collection/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Collection::SelectItems>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
