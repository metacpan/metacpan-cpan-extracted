package Code::Includable::Tree::FromStruct;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-14'; # DATE
our $DIST = 'Role-TinyCommons-Tree'; # DIST
our $VERSION = '0.124'; # VERSION

use strict;
our $GET_PARENT_METHOD = 'parent';
our $GET_CHILDREN_METHOD = 'children';
our $SET_PARENT_METHOD = 'parent';
our $SET_CHILDREN_METHOD = 'children';

sub new_from_struct {
    my $class = shift;
    my $struct = shift;

    my $wanted_class = $struct->{_class} || $class;

    # options that will be passed to children nodes (although children nodes can
    # override these with their own)
    my $pass_attributes = $struct->{_pass_attributes};
    $pass_attributes = 'hash' if !defined $pass_attributes;
    my $constructor = $struct->{_constructor} || "new";
    my $instantiate = $struct->{_instantiate};

    my %attrs = map { $_ => $struct->{$_} } grep {!/^_/} keys %$struct;

    my $node;
    if ($instantiate) {
        $node = $instantiate->($wanted_class, \%attrs);
    } else {
        if (!$pass_attributes) {
            $node = $wanted_class->$constructor;
            for (keys %attrs) {
                $node->$_($attrs{$_});
            }
        } elsif ($pass_attributes eq 'hash') {
            $node = $wanted_class->$constructor(%attrs);
        } elsif ($pass_attributes eq 'hashref') {
            $node = $wanted_class->$constructor(\%attrs);
        } else {
            die "Invalid _pass_attributes value '$pass_attributes'";
        }
    }

    # connect node to parent
    $node->$SET_PARENT_METHOD($struct->{_parent}) if $struct->{_parent};

    # create children
    if ($struct->{_children}) {
        my @children;
        for my $child_struct (@{ $struct->{_children} }) {
            push @children, new_from_struct(
                $class,
                {
                    # default for children nodes
                    _constructor => $constructor,
                    _pass_attributes => $pass_attributes,
                    _instantiate => $instantiate,

                    %$child_struct,

                    _parent => $node,
                },
            );
        }
        # connect node to children
        $node->$SET_CHILDREN_METHOD(\@children);
    }

    $node;
}

1;
# ABSTRACT: Routine to build tree object from data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Includable::Tree::FromStruct - Routine to build tree object from data structure

=head1 VERSION

This document describes version 0.124 of Code::Includable::Tree::FromStruct (from Perl distribution Role-TinyCommons-Tree), released on 2020-04-14.

=for Pod::Coverage .+

The routines in this module can be imported manually to your tree class/role.
The only requirement is that your tree class supports C<parent> and C<children>
methods as described in L<Role::TinyCommons::Tree::Node>.

The routines can also be called as a normal function call, with your tree node
object as the first argument, e.g.:

 new_from_struct($class, $struct)

The full documentation about the routines is in
L<Role::TinyCommons::Tree::FromStruct>.

=head1 VARIABLES

=head2 $GET_PARENT_METHOD => str (default: parent)

The method names C<parent> can actually be customized by (locally) setting this
variable and/or C<$SET_PARENT_METHOD>.

=head2 $SET_PARENT_METHOD => str (default: parent)

The method names C<parent> can actually be customized by (locally) setting this
variable and/or C<$GET_PARENT_METHOD>.

=head2 $GET_CHILDREN_METHOD => str (default: children)

The method names C<children> can actually be customized by (locally) setting
this variable and C<$SET_CHILDREN_METHOD>.

=head2 $SET_CHILDREN_METHOD => str (default: children)

The method names C<children> can actually be customized by (locally) setting
this variable and C<$GET_CHILDREN_METHOD>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Tree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-TreeNode>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-Tree>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Tree::FromStruct> if you want to use the routines in this
module via consuming role.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
