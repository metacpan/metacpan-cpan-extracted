package Test::Role::TinyCommons::Tree;

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Exporter qw(import);
our @EXPORT_OK = qw(test_role_tinycommons_tree);

sub test_role_tinycommons_tree {
    my %args = @_;

    my $c  = $args{class};
    my $c1 = $args{subclass1};
    my $c2 = $args{subclass2};

    my $a1 = $args{attribute1} || 'id';

    my $m  = $args{constructor_name} || 'new';

    subtest "Tree::Node" => sub {
        my $pnode  = $c->new;
        my $mode1 = $c->new;
        my $mode2 = $c->new;
        lives_ok {
            $mode1->parent($pnode);
            $mode2->parent($pnode);
            $pnode->children([$mode1, $mode2]);
        } "set parent & children";
        is_deeply($mode1->parent, $pnode, "get parent (1)");
        is_deeply($mode2->parent, $pnode, "get parent (1)");
        my @children = $pnode->children;
        @children = @{$children[0]}
            if @children==1 && ref($children[0]) eq 'ARRAY';
        is_deeply(\@children, [$mode1, $mode2], "get children");
    };

    subtest "Tree::FromStruct" => sub {
        my $tree;

        my $struct = {
            ( _instantiate => $args{code_instantiate} ) x
                !!$args{code_instantiate},
            _pass_attributes => 0,
            _constructor => $m,

            $a1 => 0, _children => [
                {$a1 => 1, _children => [
                    {$a1 => 3},
                    {$a1 => 4, _class=>$c2},
                    {$a1 => 5, _class=>$c2},
                    {$a1 => 6, _class=>$c1},
                    {$a1 => 7},
                ]},
                {$a1 => 2, _children => [
                    {$a1 => 8, _class => $c2, _children => [
                        {$a1 => 9, _class => $c1},
                    ]},
                ]},
            ],
        };

        $tree = $c->new_from_struct($struct);

        my $exp_tree = do {
            my $n0 = $c ->$m; $n0->$a1(0);

            my $n1 = $c ->$m; $n1->$a1(1); $n1->parent($n0);
            my $n2 = $c ->$m; $n2->$a1(2); $n2->parent($n0);
            $n0->children([$n1, $n2]);

            my $n3 = $c ->$m; $n3->$a1(3); $n3->parent($n1);
            my $n4 = $c2->$m; $n4->$a1(4); $n4->parent($n1);
            my $n5 = $c2->$m; $n5->$a1(5); $n5->parent($n1);
            my $n6 = $c1->$m; $n6->$a1(6); $n6->parent($n1);
            my $n7 = $c ->$m; $n7->$a1(7); $n7->parent($n1);
            $n1->children([$n3, $n4, $n5, $n6, $n7]);

            my $n8 = $c2->$m; $n8->$a1(8); $n8->parent($n2);
            $n2->children([$n8]);

            my $n9 = $c1->$m; $n9->$a1(9); $n9->parent($n8);
            $n8->children([$n9]);

            $n0;
        };

        is_deeply($tree, $exp_tree, "result") or diag explain $tree;

        $tree =
            Code::Includable::Tree::FromStruct::new_from_struct($c, $struct);

        is_deeply($tree, $exp_tree, "result (sub call)");

    } if $args{test_fromstruct};

    subtest "Tree::NodeMethods" => sub {
        my ($n0, $n1, $n2, $n3, $n4, $n5, $n6, $n7, $n8, $n9);

      BUILD:
        {
            $n0 = $c ->$m; $n0->$a1(0);

            $n1 = $c ->$m; $n1->$a1(1); $n1->parent($n0);
            $n2 = $c ->$m; $n2->$a1(2); $n2->parent($n0);
            $n0->children([$n1, $n2]);

            $n3 = $c ->$m; $n3->$a1(3); $n3->parent($n1);
            $n4 = $c2->$m; $n4->$a1(4); $n4->parent($n1);
            $n5 = $c2->$m; $n5->$a1(5); $n5->parent($n1);
            $n6 = $c1->$m; $n6->$a1(6); $n6->parent($n1);
            $n7 = $c ->$m; $n7->$a1(7); $n7->parent($n1);
            $n1->children([$n3, $n4, $n5, $n6, $n7]);

            $n8 = $c2->$m; $n8->$a1(8); $n8->parent($n2);
            $n2->children([$n8]);

            $n9 = $c1->$m; $n9->$a1(9); $n9->parent($n8);
            $n8->children([$n9]);

            # structure:
            # 0 (c)
            #   1 (c)
            #     3 (c)
            #     4 (c2)
            #     5 (c2)
            #     6 (c1)
            #     7 (c)
            #   2 (c)
            #     8 (c2)
            #       9 (c1)
        }

        is_deeply([$n9->ancestors],
                  [$n8, $n2, $n0],
                  "ancestors (1)");
        is_deeply([Code::Includable::Tree::NodeMethods::ancestors($n9)],
                  [$n8, $n2, $n0],
                  "ancestors (1) (sub call)");
        is_deeply([$n0->ancestors],
                  [],
                  "ancestors (2)");
        is_deeply([Code::Includable::Tree::NodeMethods::ancestors($n0)],
                  [],
                  "ancestors (2) (sub call)");

        is_deeply([$n0->descendants],
                  [$n1, $n2, $n3, $n4, $n5, $n6, $n7, $n8, $n9],
                  "descendants");
        is_deeply([Code::Includable::Tree::NodeMethods::descendants($n0)],
                  [$n1, $n2, $n3, $n4, $n5, $n6, $n7, $n8, $n9],
                  "descendants (sub call)");

        # XXX test walk

        is_deeply($n0->first_node(sub { $_[0]->id == 5 }),
                  $n5, "first_node");
        is_deeply(Code::Includable::Tree::NodeMethods::first_node($n0, sub { $_[0]->id == 5 }),
                  $n5, "first_node (sub call)");

        ok( $n1->is_first_child, "is_first_child [1]");
        ok(!$n2->is_first_child, "is_first_child [2]");
        ok(!$n0->is_first_child, "is_first_child [3]");
        ok( Code::Includable::Tree::NodeMethods::is_first_child($n1), "is_first_child [1] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_first_child($n2), "is_first_child [2] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_first_child($n0), "is_first_child [3] (sub call)");

        ok(!$n1->is_last_child, "is_last_child [1]");
        ok( $n2->is_last_child, "is_last_child [2]");
        ok(!$n0->is_last_child, "is_last_child [3]");
        ok(!Code::Includable::Tree::NodeMethods::is_last_child($n1), "is_last_child [1] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_last_child($n2), "is_last_child [2] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_last_child($n0), "is_last_child [3] (sub call)");

        ok(!$n1->is_only_child, "is_only_child [1]");
        ok( $n8->is_only_child, "is_only_child [2]");
        ok(!$n0->is_only_child, "is_only_child [3]");
        ok(!Code::Includable::Tree::NodeMethods::is_only_child($n1), "is_only_child [1] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_only_child($n8), "is_only_child [2] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_only_child($n0), "is_only_child [3] (sub call)");

        ok( $n1 ->is_nth_child(1), "is_nth_child [1]");
        ok(!$n1 ->is_nth_child(2), "is_nth_child [2]");
        ok( $n2 ->is_nth_child(2), "is_nth_child [3]");
        ok( Code::Includable::Tree::NodeMethods::is_nth_child($n1, 1), "is_nth_child [1] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_nth_child($n1, 2), "is_nth_child [2] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_nth_child($n2, 2), "is_nth_child [3] (sub call)");

        ok(!$n1 ->is_nth_last_child(1), "is_nth_last_child [1]");
        ok( $n1 ->is_nth_last_child(2), "is_nth_last_child [2]");
        ok(!$n2 ->is_nth_last_child(2), "is_nth_last_child [3]");
        ok(!Code::Includable::Tree::NodeMethods::is_nth_last_child($n1, 1), "is_nth_last_child [1] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_nth_last_child($n1, 2), "is_nth_last_child [2] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_nth_last_child($n2, 2), "is_nth_last_child [3] (sub call)");

        ok( $n3 ->is_first_child_of_type, "is_first_child_of_type [1]");
        ok( $n4 ->is_first_child_of_type, "is_first_child_of_type [2]");
        ok(!$n5 ->is_first_child_of_type, "is_first_child_of_type [3]");
        ok( $n6 ->is_first_child_of_type, "is_first_child_of_type [4]");
        ok(!$n7 ->is_first_child_of_type, "is_first_child_of_type [4]");
        ok( Code::Includable::Tree::NodeMethods::is_first_child_of_type($n3), "is_first_child_of_type [1] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_first_child_of_type($n4), "is_first_child_of_type [2] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_first_child_of_type($n5), "is_first_child_of_type [3] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_first_child_of_type($n6), "is_first_child_of_type [4] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_first_child_of_type($n7), "is_first_child_of_type [4] (sub call)");

        ok(!$n3 ->is_last_child_of_type, "is_last_child_of_type [1]");
        ok(!$n4 ->is_last_child_of_type, "is_last_child_of_type [2]");
        ok( $n5 ->is_last_child_of_type, "is_last_child_of_type [3]");
        ok( $n6 ->is_last_child_of_type, "is_last_child_of_type [4]");
        ok( $n7 ->is_last_child_of_type, "is_last_child_of_type [5]");
        ok(!Code::Includable::Tree::NodeMethods::is_last_child_of_type($n3), "is_last_child_of_type [1] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_last_child_of_type($n4), "is_last_child_of_type [2] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_last_child_of_type($n5), "is_last_child_of_type [3] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_last_child_of_type($n6), "is_last_child_of_type [4] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_last_child_of_type($n7), "is_last_child_of_type [5] (sub call)");

        ok(!$n3 ->is_last_child_of_type, "is_last_child_of_type [1]");
        ok(!$n4 ->is_last_child_of_type, "is_last_child_of_type [2]");
        ok( $n5 ->is_last_child_of_type, "is_last_child_of_type [3]");
        ok( $n6 ->is_last_child_of_type, "is_last_child_of_type [4]");
        ok( $n7 ->is_last_child_of_type, "is_last_child_of_type [5]");
        ok(!Code::Includable::Tree::NodeMethods::is_last_child_of_type($n3), "is_last_child_of_type [1] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_last_child_of_type($n4), "is_last_child_of_type [2] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_last_child_of_type($n5), "is_last_child_of_type [3] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_last_child_of_type($n6), "is_last_child_of_type [4] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_last_child_of_type($n7), "is_last_child_of_type [5] (sub call)");

        ok( $n3 ->is_nth_child_of_type(1), "is_nth_child_of_type [1]");
        ok(!$n3 ->is_nth_child_of_type(2), "is_nth_child_of_type [2]");
        ok( $n4 ->is_nth_child_of_type(1), "is_nth_child_of_type [3]");
        ok(!$n4 ->is_nth_child_of_type(2), "is_nth_child_of_type [4]");
        ok( Code::Includable::Tree::NodeMethods::is_nth_child_of_type($n3, 1), "is_nth_child_of_type [1] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_nth_child_of_type($n3, 2), "is_nth_child_of_type [2] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_nth_child_of_type($n4, 1), "is_nth_child_of_type [3] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_nth_child_of_type($n4, 2), "is_nth_child_of_type [4] (sub call)");

        ok(!$n3 ->is_nth_last_child_of_type(1), "is_nth_last_child_of_type [1]");
        ok( $n3 ->is_nth_last_child_of_type(2), "is_nth_last_child_of_type [2]");
        ok(!$n4 ->is_nth_last_child_of_type(1), "is_nth_last_child_of_type [3]");
        ok( $n4 ->is_nth_last_child_of_type(2), "is_nth_last_child_of_type [4]");
        ok(!Code::Includable::Tree::NodeMethods::is_nth_last_child_of_type($n3, 1), "is_nth_last_child_of_type [1] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_nth_last_child_of_type($n3, 2), "is_nth_last_child_of_type [2] (sub call)");
        ok(!Code::Includable::Tree::NodeMethods::is_nth_last_child_of_type($n4, 1), "is_nth_last_child_of_type [3] (sub call)");
        ok( Code::Includable::Tree::NodeMethods::is_nth_last_child_of_type($n4, 2), "is_nth_last_child_of_type [4] (sub call)");

        ok(!$n3 ->is_only_child_of_type, "is_only_child_of_type [1]");
        ok( $n6 ->is_only_child_of_type, "is_only_child_of_type [2]");
        ok(!Code::Includable::Tree::NodeMethods::is_only_child_of_type($n3), "is_only_child_of_type [1]");
        ok( Code::Includable::Tree::NodeMethods::is_only_child_of_type($n6), "is_only_child_of_type [2]");

        is_deeply($n3->prev_sibling, undef, "prev_sibling [1]");
        is_deeply($n5->prev_sibling, $n4  , "prev_sibling [2]");
        is_deeply($n7->prev_sibling, $n6  , "prev_sibling [3]");
        is_deeply(Code::Includable::Tree::NodeMethods::prev_sibling($n3), undef, "prev_sibling [1] (sub call)");
        is_deeply(Code::Includable::Tree::NodeMethods::prev_sibling($n5), $n4  , "prev_sibling [2] (sub call)");
        is_deeply(Code::Includable::Tree::NodeMethods::prev_sibling($n7), $n6  , "prev_sibling [3] (sub call)");

        is_deeply($n3->next_sibling, $n4  , "next_sibling [1]");
        is_deeply($n5->next_sibling, $n6  , "next_sibling [2]");
        is_deeply($n7->next_sibling, undef, "next_sibling [3]");
        is_deeply(Code::Includable::Tree::NodeMethods::next_sibling($n3), $n4  , "next_sibling [1] (sub call)");
        is_deeply(Code::Includable::Tree::NodeMethods::next_sibling($n5), $n6  , "next_sibling [2] (sub call)");
        is_deeply(Code::Includable::Tree::NodeMethods::next_sibling($n7), undef, "next_sibling [3] (sub call)");

        is_deeply([$n3->prev_siblings], []        , "prev_siblings [1] (sub call)");
        is_deeply([$n5->prev_siblings], [$n3, $n4], "prev_siblings [2] (sub call)");
        is_deeply([Code::Includable::Tree::NodeMethods::prev_siblings($n3)], []        , "prev_siblings [1] (sub call)");
        is_deeply([Code::Includable::Tree::NodeMethods::prev_siblings($n5)], [$n3, $n4], "prev_siblings [2] (sub call)");

        is_deeply([$n5->next_siblings], [$n6, $n7], "next_siblings [1] (sub call)");
        is_deeply([$n7->next_siblings], []        , "next_siblings [2] (sub call)");
        is_deeply([Code::Includable::Tree::NodeMethods::next_siblings($n5)], [$n6, $n7], "next_siblings [1] (sub call)");
        is_deeply([Code::Includable::Tree::NodeMethods::next_siblings($n7)], []        , "next_siblings [2] (sub call)");

    } if $args{test_nodemethods};
}

1;
# ABSTRACT: Test suite for Role::TinyCommons::Tree

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Role::TinyCommons::Tree - Test suite for Role::TinyCommons::Tree

=head1 VERSION

This document describes version 0.11 of Test::Role::TinyCommons::Tree (from Perl distribution Role-TinyCommons-Tree), released on 2016-11-23.

=head1 DESCRIPTION

This module provides a test suite for roles in Role::TinyCommons::Tree
distribution.

=head1 FUNCTIONS

=head2 test_role_tinycommons_tree(%args)

Test a class against roles in Role::TinyCommons::Tree distribution.

To run the tests, you need to provide a class name to test in C<class>. You have
to load the class yourself. The class must at least consume the role
L<Role::TinyCommons::Tree::Node> (and other roles too, if you want to test the
other roles). You also need to provide two subclasses names in C<subclass1> and
C<subclass2>. They must be subclass of the main class, and one must not be
subclasses of the other. You are also responsible to load these two subclasses.

Options:

=over

=item * class* => str

The main class to test.

=item * subclass1* => str

=item * subclass2* => str

=item * attribute1 => str (default: C<id>)

An attribute (rw, int) is needed for testing. The default is C<id>, but you can
set a custom attribute.

=item * code_instantiate => code

Required if your constructor does not accept name-value pairs (C<<
$class->new(id => ...) >>). Code will be supplied C<< ($class, \%attrs) >> and
must return an object.

=item * constructor_name => str (default: new)

Must be set if your constructor name is not the default C<new>.

=item * test_fromstruct => bool (default: 0)

Whether to test class against L<Role::TinyCommons::Tree::FromStruct>. If you
enable this, your class must consume the role.

If that attribute needs to be set during construction, and your constructor does
not accept name-value pairs (C<< $class->new(id => ...) >>), then you'll need to
supply C<code_instantiate> which will be passed C<<($class, \%attrs)>> so you
can instantiate your object yourself.

=item * test_nodemethods => bool (default: 0)

Whether to test class against L<Role::TinyCommons::Tree::NodeMethods>. If you
enable this, your class must consume the role.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Tree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-TreeNode>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-Tree>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
