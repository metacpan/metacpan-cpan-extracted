package Role::TinyCommons::Collection::FindItem::Iterator;

use strict;
use Role::Tiny;
use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'RoleBundle-TinyCommons-Collection'; # DIST
our $VERSION = '0.009'; # VERSION

### implements

with 'Role::TinyCommons::Collection::FindItem';

### requires

requires 'each_item';

### optionally depends
# 'cmp_items'; # Role::TinyCommons::Collection::CompareItems

### provides

sub find_item {
    my ($self, %args) = @_;

    my $search_item = $args{item};
    my $return_pos  = $args{return_pos};
    my $all         = $args{all};

    my @results;
    if ($self->can('cmp_items')) {
        $self->each_item(
            sub {
                my ($iter_item, $obj, $pos) = @_;
                if ($obj->cmp_items($iter_item, $search_item) == 0) {
                    push @results, $return_pos ? $pos : $iter_item;
                    return 0 unless $all;
                }
                1;
            });
    } else {
        $self->each_item(
            sub {
                my ($iter_item, $obj, $pos) = @_;
                if (($iter_item cmp $search_item) == 0) {
                    push @results, $return_pos ? $pos : $iter_item;
                    return 0 unless $all;
                }
                1;
            });
    }
    @results;
}

1;
# ABSTRACT: Provides find_item() for iterators

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Collection::FindItem::Iterator - Provides find_item() for iterators

=head1 VERSION

This document describes version 0.009 of Role::TinyCommons::Collection::FindItem::Iterator (from Perl distribution RoleBundle-TinyCommons-Collection), released on 2021-10-07.

=head1 DESCRIPTION

This role provides find_item() which searches linearly using each_item() and
cmp_items(). each_item() is usually provided by an iterator.

=head1 ROLES MIXED IN

L<Role::TinyCommons::Collection::FindItem>

=head1 REQUIRED METHODS

=head2 each_item

Provided by roles like in L<Role::TinyCommons::Iterator::Resettable> or
L<Role::TinyCommons::Iterator::Circular>.

=head1 OPTIONALLY DEPENDED METHODS

=head2 cmp_items

Usage:

 $res = $obj->cmp_items($item1, $item2); # returns either -1, 0, 1

For flexibility in searching. The method should accept two items and return
either -1, 0, 1 like Perl's C<cmp> or C<< <=> >> operator. See also
L<Role::TinyCommons::Collection::CompareItems> for the more formal encapsulated
form of this interface.

=head1 PROVIDED METHODS

=head2 find_item

Usage:

 my @results = $obj->find_item(%args);

For more details, see L<Role::TinyCommons::Collection::FindItem/find_item>. This
module implements arguments C<item>, C<all>, and C<return_pos>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/RoleBundle-TinyCommons-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-RoleBundle-TinyCommons-Collection>.

=head1 SEE ALSO

L<Role::TinyCommons::Collection::FindItem>

L<Role::TinyCommons::Iterator::Resettable>,
L<Role::TinyCommons::Iterator::Circular>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=RoleBundle-TinyCommons-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
