package Role::TinyCommons::Collection::SelectItems;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-16'; # DATE
our $DIST = 'Role-TinyCommons-Collection'; # DIST
our $VERSION = '0.010'; # VERSION

### required methods

requires 'select_items';

### provided methods

sub has_matching_item {
    my ($self, %args) = @_;
    my @results = $self->select_items(result_limit => 1, %args);
    @results ? 1:0;
}

sub select_first {
    my ($self, %args) = @_;
    my @results = $self->select_items(result_limit => 1, %args);
    @results ? $results[0] : undef;
}

1;
# ABSTRACT: The search_items() interface

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Collection::SelectItems - The search_items() interface

=head1 VERSION

This document describes version 0.010 of Role::TinyCommons::Collection::SelectItems (from Perl distribution Role-TinyCommons-Collection), released on 2024-01-16.

=head1 SYNOPSIS

In your class:

 package YourClass;
 use Role::Tiny::With;
 with 'Role::TinyCommons::Collection::SelectItems';

 sub new { ... }
 sub select_items { ... }
 ...
 1;

In the code of your class user:

 use YourClass;

 my $obj = YourClass->new(...);

 # basic select
 my @results = $obj->select_items("age.min" => 20);
 die "There are no items matching that criteria" unless @results;

 # ordering

 # paging

 ## only return the first 5 results
 my @results = $obj->select_items("age.min" => 20, result_limit => 5);

 ## return the next 5 results (one-based indexing)
 my @results = $obj->select_items("age.min" => 20, result_limit => 5, result_start => 6);

=head1 DESCRIPTION

C<search_items()> is an interface to search (select) items in a collection based
on some criteria. Some options are provided. The implementor is given
flexibility to support additional options, but the basic modes of selecting must
be supported.

To do exact matching and return a single result, there is the
L<Role::TinyCommons::Collection::FindItem> interface.

=head1 REQUIRED METHODS

=head2 select_items

Usage:

 my @results = $obj->select_items(%args);

Search collection based on some criteria. Must return 0 or more results as list.
Need not return the items themselves, but can (and should preferrably) return
only the item ID's or some other unique attribute of the items, unless the
L</detail> mode is enabled, in which must return the items themselves. All
matching items must be returned unless L</result_limit> and L</result_start>
options are specified, in which case only a subset of results is returned.

Arguments:

To specify per-attribute criteria, the C<ATTR.OPERATOR> is recommended. For
example C<age.min> specifies minimum age, while C<name.is> specifies name to
match exactly.

=over

=item * detail

Type: bool.

This argument should be supported for collections that have structured items.

=item * result_limit

Type: uint. If specified, only at most this number of results should be
returned. result_limit and result_start work like LIMIT clause in SQL SELECT
statement.

This argument is optional to implement; if unimplemented should still return
results intead of returning an error.

=item * result_start

Type: posint (positive integer). If specified, return from the n'th result.
Default if unspecified is 1, meaning to return from the first result.
result_limit and result_start work like LIMIT clause in SQL SELECT statement.

This argument is optional to implement.

=item * ignore_case

Type: bool. If set to true, must enable case-insensitive matching. Otherwise,
matching should be case-sensitive.

This argument is optional to implement. It should be supported if stringwise
comparison is used.

=back

Implementor is free to add more options.

=head1 PROVIDED METHODS

=head2 has_matching_item

Usage:

 my $has_matching_item = $obj->has_matching_item(%args);

Equivalent to:

 my @results = $obj->select_items(result_limit => 1, %args);
 return @results ? 1:0;

Name is chosen to not conflict with
L<Role::TinyCommons::Collection::FindItem/has_item> from
L<Role::TinyCommons::Collection::FindItem>.

=head2 select_first

Usage:

 my $item = $obj->select_first(%args);

Return C<undef> (if not found) or the result (if found). Can be ambiguous if
item can be C<undef>. Equivalent to:

 my @results = $obj->select_items(result_limit => 1, %args);
 return @results ? $results[0] : undef;

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Collection>.

=head1 SEE ALSO

L<Role::TinyCommons::Collection::FindItem>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
