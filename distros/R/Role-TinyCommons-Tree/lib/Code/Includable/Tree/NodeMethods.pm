package Code::Includable::Tree::NodeMethods;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-06'; # DATE
our $DIST = 'Role-TinyCommons-Tree'; # DIST
our $VERSION = '0.120'; # VERSION

use strict;
our $GET_PARENT_METHOD = 'parent';
our $GET_CHILDREN_METHOD = 'children';
our $SET_PARENT_METHOD = 'parent';
our $SET_CHILDREN_METHOD = 'children';

# we must contain no other functions

use Scalar::Util ();

# like children, but always return list
sub _children_as_list {
    my $self = shift;
    my @c = $self->$GET_CHILDREN_METHOD;
    if (@c == 1) {
        return () unless defined($c[0]);
        return @{$c[0]} if ref($c[0]) eq 'ARRAY';
    }
    @c;
}

sub _descendants {
    my ($self, $res) = @_;
    my @c = _children_as_list($self);
    push @$res, @c;
    for (@c) { _descendants($_, $res) }
}

sub descendants {
    my $self = shift;
    my $res = [];
    _descendants($self, $res);
    @$res;
}

sub ancestors {
    my $self = shift;
    my @res;
    my $p = $self->$GET_PARENT_METHOD;
    while ($p) {
        push @res, $p;
        $p = $p->$GET_PARENT_METHOD;
    }
    @res;
}

sub walk {
    my ($self, $code) = @_;
    for (descendants($self)) {
        $code->($_);
    }
}

sub first_node {
    my ($self, $code) = @_;
    for (descendants($self)) {
        return $_ if $code->($_);
    }
    undef;
}

sub is_first_child {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my @c = _children_as_list($parent);
    @c && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[0]);
}

sub is_last_child {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my @c = _children_as_list($parent);
    @c && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[-1]);
}

sub is_only_child {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my @c = _children_as_list($parent);
    @c==1;# && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[0]);
}

sub is_nth_child {
    my ($self, $n) = @_;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my @c = _children_as_list($parent);
    @c >= $n && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[$n-1]);
}

sub is_nth_last_child {
    my ($self, $n) = @_;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my @c = _children_as_list($parent);
    @c >= $n && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[-$n]);
}

sub is_first_child_of_type {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my $type = ref($self);
    my @c = grep { ref($_) eq $type } _children_as_list($parent);
    @c && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[0]);
}

sub is_last_child_of_type {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my $type = ref($self);
    my @c = grep { ref($_) eq $type } _children_as_list($parent);
    @c && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[-1]);
}

sub is_only_child_of_type {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my $type = ref($self);
    my @c = grep { ref($_) eq $type } _children_as_list($parent);
    @c == 1; # && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[0]);
}

sub is_nth_child_of_type {
    my ($self, $n) = @_;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my $type = ref($self);
    my @c = grep { ref($_) eq $type } _children_as_list($parent);
    @c >= $n && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[$n-1]);
}

sub is_nth_last_child_of_type {
    my ($self, $n) = @_;
    my $parent = $self->$GET_PARENT_METHOD;
    return 0 unless $parent;
    my $type = ref($self);
    my @c = grep { ref($_) eq $type } _children_as_list($parent);
    @c >= $n && Scalar::Util::refaddr($self) == Scalar::Util::refaddr($c[-$n]);
}

sub prev_sibling {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD or return undef;
    my $refaddr = Scalar::Util::refaddr($self);
    my @c = _children_as_list($parent);
    for my $i (1..$#c) {
        if (Scalar::Util::refaddr($c[$i]) == $refaddr) {
            return $c[$i-1];
        }
    }
    undef;
}

sub prev_siblings {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD or return ();
    my $refaddr = Scalar::Util::refaddr($self);
    my @c = _children_as_list($parent);
    for my $i (1..$#c) {
        if (Scalar::Util::refaddr($c[$i]) == $refaddr) {
            return @c[0..$i-1];
        }
    }
    ();
}

sub next_sibling {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD or return undef;
    my $refaddr = Scalar::Util::refaddr($self);
    my @c = _children_as_list($parent);
    for my $i (0..$#c-1) {
        if (Scalar::Util::refaddr($c[$i]) == $refaddr) {
            return $c[$i+1];
        }
    }
    undef;
}

sub next_siblings {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD or return ();
    my $refaddr = Scalar::Util::refaddr($self);
    my @c = _children_as_list($parent);
    for my $i (0..$#c-1) {
        if (Scalar::Util::refaddr($c[$i]) == $refaddr) {
            return @c[$i+1 .. $#c];
        }
    }
    ();
}

# remove self from parent
sub remove {
    my $self = shift;
    my $parent = $self->$GET_PARENT_METHOD or return ();
    my $refaddr = Scalar::Util::refaddr($self);
    my @c;
    for my $c (_children_as_list($parent)) {
        if (Scalar::Util::refaddr($c) == $refaddr) {
            next;
        }
        push @c, $c;
    }
    $parent->$SET_CHILDREN_METHOD(\@c);
}

1;
# ABSTRACT: Tree node routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Includable::Tree::NodeMethods - Tree node routines

=head1 VERSION

This document describes version 0.120 of Code::Includable::Tree::NodeMethods (from Perl distribution Role-TinyCommons-Tree), released on 2020-02-06.

=head1 DESCRIPTION

The routines in this module can be imported manually to your tree class/role.
The only requirement is that your tree class supports C<parent> and C<children>
methods.

The routines can also be called as a normal function call, with your tree node
object as the first argument, e.g.:

 next_siblings($node)

=for Pod::Coverage .+

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

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Tree>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-Tree>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Tree::NodeMethods> if you want to use the routines in this
module via consuming role.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
