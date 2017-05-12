package PERLANCAR::Tree::Examples;

our $DATE = '2016-04-14'; # DATE
our $VERSION = '1.0.6'; # VERSION

use 5.010001;
use strict;
use warnings;

use Tree::Create::Callback::ChildrenPerLevel
    qw(create_tree_using_callback);

use Exporter::Rinci qw(import);

our %SPEC;

$SPEC{gen_sample_data} = {
    v => 1.1,
    summary => 'Generate sample tree object',
    args => {
        size => {
            summary => 'Which tree to generate',
            schema => ['str*', in=>['tiny1', 'small1', 'medium1']],
            description => <<'_',

There are several predefined sizes to choose from.

`tiny1` is a very tiny tree, with only depth of 2 and a total of 3 nodes,
including root node.

`small1` is a small tree with depth of 4 and a total of 16 nodes, including root
node.

`medium1` is a tree of depth 7 and ~20k nodes, which is about the size of
`Org::Document` tree generated when parsing my `todo.org` document circa early
2016 (~750kB, ~2900 todo items).

_
            req => 1,
            pos => 0,
            tags => ['data-parameter'],
        },
        backend => {
            schema => ['str*', in=>['array', 'hash', 'insideout']],
            default => 'hash',
            tags => ['data-parameter'],
        },
    },
    result => {
        schema => 'obj*',
    },
    result_naked => 1,
};
sub gen_sample_data {
    my %args = @_;

    my $size = $args{size} or die "Please specify size";
    my $backend = $args{backend} // 'hash';

    my @classes;
    push @classes, "Tree::Example::".ucfirst($backend)."Node";
    push @classes, "Tree::Example::".ucfirst($backend)."Node::Sub$_"
        for 1..7;

    my $nums_per_level;
    my $classes_per_level;
    if ($size eq 'tiny1') {
        $nums_per_level = [2];
        $classes_per_level = [@classes[0..1]];
    } elsif ($size eq 'small1') {
        $nums_per_level = [3, 2, 8, 2];
        $classes_per_level = [@classes[0..4]];
    } elsif ($size eq 'medium1') {
        $nums_per_level = [100, 3000, 5000, 8000, 3000, 1000, 300];
        $classes_per_level = [@classes[0..7]];
    } else {
        die "Unknown size '$size'";
    }

    my $id = 0;
    create_tree_using_callback(
        sub {
            my ($parent, $level, $seniority) = @_;
            $id++;
            my $class = $classes_per_level->[$level];
            my $obj = $class->new;
            $obj->id($id);
            $obj->level($level);
            $obj;
        },
        $nums_per_level,
    );
}

package # hide from PAUSE
    Tree::Example::HashNode;
use parent qw(Tree::Object::Hash);

sub id    { $_[0]{id}    = $_[1] if @_>1; $_[0]{id}    }
sub level { $_[0]{level} = $_[1] if @_>1; $_[0]{level} }

package # hide from PAUSE
    Tree::Example::HashNode::Sub1;
use base qw(Tree::Example::HashNode);

package # hide from PAUSE
    Tree::Example::HashNode::Sub2;
use base qw(Tree::Example::HashNode);

package # hide from PAUSE
    Tree::Example::HashNode::Sub3;
use base qw(Tree::Example::HashNode);

package # hide from PAUSE
    Tree::Example::HashNode::Sub4;
use base qw(Tree::Example::HashNode);

package # hide from PAUSE
    Tree::Example::HashNode::Sub5;
use base qw(Tree::Example::HashNode);

package # hide from PAUSE
    Tree::Example::HashNode::Sub6;
use base qw(Tree::Example::HashNode);

package # hide from PAUSE
    Tree::Example::HashNode::Sub7;
use base qw(Tree::Example::HashNode);


package # hide from PAUSE
    Tree::Example::ArrayNode;
use Tree::Object::Array::Glob qw(id level);

package # hide from PAUSE
    Tree::Example::ArrayNode::Sub1;
use base qw(Tree::Example::ArrayNode);

package # hide from PAUSE
    Tree::Example::ArrayNode::Sub2;
use base qw(Tree::Example::ArrayNode);

package # hide from PAUSE
    Tree::Example::ArrayNode::Sub3;
use base qw(Tree::Example::ArrayNode);

package # hide from PAUSE
    Tree::Example::ArrayNode::Sub4;
use base qw(Tree::Example::ArrayNode);

package # hide from PAUSE
    Tree::Example::ArrayNode::Sub5;
use base qw(Tree::Example::ArrayNode);

package # hide from PAUSE
    Tree::Example::ArrayNode::Sub6;
use base qw(Tree::Example::ArrayNode);

package # hide from PAUSE
    Tree::Example::ArrayNode::Sub7;
use base qw(Tree::Example::ArrayNode);

package # hide from PAUSE
    Tree::Example::InsideoutNode;
use parent qw(Tree::Object::InsideOut);
use Class::InsideOut qw(public);

public id    => my %id;
public level => my %level;

package # hide from PAUSE
    Tree::Example::InsideoutNode::Sub1;
use base qw(Tree::Example::InsideoutNode);

package # hide from PAUSE
    Tree::Example::InsideoutNode::Sub2;
use base qw(Tree::Example::InsideoutNode);

package # hide from PAUSE
    Tree::Example::InsideoutNode::Sub3;
use base qw(Tree::Example::InsideoutNode);

package # hide from PAUSE
    Tree::Example::InsideoutNode::Sub4;
use base qw(Tree::Example::InsideoutNode);

package # hide from PAUSE
    Tree::Example::InsideoutNode::Sub5;
use base qw(Tree::Example::InsideoutNode);

package # hide from PAUSE
    Tree::Example::InsideoutNode::Sub6;
use base qw(Tree::Example::InsideoutNode);

package # hide from PAUSE
    Tree::Example::InsideoutNode::Sub7;
use base qw(Tree::Example::InsideoutNode);

1;
# ABSTRACT: Generate sample tree object

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::Tree::Examples - Generate sample tree object

=head1 VERSION

This document describes version 1.0.6 of PERLANCAR::Tree::Examples (from Perl distribution PERLANCAR-Tree-Examples), released on 2016-04-14.

=head1 SYNOPSIS

 use PERLANCAR::Tree::Examples qw(gen_sample_data);

 my $tree = gen_sample_data(size => 'medium1');

=head1 DESCRIPTION

This distribution can generate sample tree objects of several size (depth +
number of nodes) and implementation (hash-based nodes or array-based). I use
these example trees for benchmarking or testing in several other distributions.

=head2 Overview of available sample data

=over

=item * size=tiny1, backend=hash

 (Tree::Example::HashNode) {_parent=>undef,id=>1,level=>0}
 |-- (Tree::Example::HashNode::Sub1) {id=>2,level=>1}
 \-- (Tree::Example::HashNode::Sub1) {id=>3,level=>1}

=item * size=tiny1, backend=array

 (Tree::Example::ArrayNode) [1,0,undef,"<obj>","<obj>"]
 |-- (Tree::Example::ArrayNode::Sub1) [2,1,"<obj>"]
 \-- (Tree::Example::ArrayNode::Sub1) [3,1,"<obj>"]

=item * size=small1, backend=hash

 (Tree::Example::HashNode) {_parent=>undef,id=>1,level=>0}
 |-- (Tree::Example::HashNode::Sub1) {id=>2,level=>1}
 |   \-- (Tree::Example::HashNode::Sub2) {id=>5,level=>2}
 |       |-- (Tree::Example::HashNode::Sub3) {id=>7,level=>3}
 |       |-- (Tree::Example::HashNode::Sub3) {id=>8,level=>3}
 |       |-- (Tree::Example::HashNode::Sub3) {id=>9,level=>3}
 |       |   \-- (Tree::Example::HashNode::Sub4) {id=>15,level=>4}
 |       \-- (Tree::Example::HashNode::Sub3) {id=>10,level=>3}
 |-- (Tree::Example::HashNode::Sub1) {id=>3,level=>1}
 \-- (Tree::Example::HashNode::Sub1) {id=>4,level=>1}
     \-- (Tree::Example::HashNode::Sub2) {id=>6,level=>2}
         |-- (Tree::Example::HashNode::Sub3) {id=>11,level=>3}
         |-- (Tree::Example::HashNode::Sub3) {id=>12,level=>3}
         |   \-- (Tree::Example::HashNode::Sub4) {id=>16,level=>4}
         |-- (Tree::Example::HashNode::Sub3) {id=>13,level=>3}
 (... 1 more line(s) not shown ...)

=item * size=small1, backend=array

 (Tree::Example::ArrayNode) [1,0,undef,"<obj>","<obj>","<obj>"]
 |-- (Tree::Example::ArrayNode::Sub1) [2,1,"<obj>","<obj>"]
 |   \-- (Tree::Example::ArrayNode::Sub2) [5,2,"<obj>","<obj>","<obj>","<obj>","<obj>"]
 |       |-- (Tree::Example::ArrayNode::Sub3) [7,3,"<obj>"]
 |       |-- (Tree::Example::ArrayNode::Sub3) [8,3,"<obj>"]
 |       |-- (Tree::Example::ArrayNode::Sub3) [9,3,"<obj>","<obj>"]
 |       |   \-- (Tree::Example::ArrayNode::Sub4) [15,4,"<obj>"]
 |       \-- (Tree::Example::ArrayNode::Sub3) [10,3,"<obj>"]
 |-- (Tree::Example::ArrayNode::Sub1) [3,1,"<obj>"]
 \-- (Tree::Example::ArrayNode::Sub1) [4,1,"<obj>","<obj>"]
     \-- (Tree::Example::ArrayNode::Sub2) [6,2,"<obj>","<obj>","<obj>","<obj>","<obj>"]
         |-- (Tree::Example::ArrayNode::Sub3) [11,3,"<obj>"]
         |-- (Tree::Example::ArrayNode::Sub3) [12,3,"<obj>","<obj>"]
         |   \-- (Tree::Example::ArrayNode::Sub4) [16,4,"<obj>"]
         |-- (Tree::Example::ArrayNode::Sub3) [13,3,"<obj>"]
 (... 1 more line(s) not shown ...)

=item * size=medium1, backend=hash

 (Tree::Example::HashNode) {_parent=>undef,id=>1,level=>0}
 |-- (Tree::Example::HashNode::Sub1) {id=>2,level=>1}
 |   |-- (Tree::Example::HashNode::Sub2) {id=>102,level=>2}
 |   |   |-- (Tree::Example::HashNode::Sub3) {id=>3102,level=>3}
 |   |   |   |-- (Tree::Example::HashNode::Sub4) {id=>8102,level=>4}
 |   |   |   \-- (Tree::Example::HashNode::Sub4) {id=>8103,level=>4}
 |   |   |       \-- (Tree::Example::HashNode::Sub5) {id=>16102,level=>5}
 |   |   \-- (Tree::Example::HashNode::Sub3) {id=>3103,level=>3}
 |   |       \-- (Tree::Example::HashNode::Sub4) {id=>8104,level=>4}
 |   |-- (Tree::Example::HashNode::Sub2) {id=>103,level=>2}
 |   |   \-- (Tree::Example::HashNode::Sub3) {id=>3104,level=>3}
 |   |       |-- (Tree::Example::HashNode::Sub4) {id=>8105,level=>4}
 |   |       |   \-- (Tree::Example::HashNode::Sub5) {id=>16103,level=>5}
 |   |       |       \-- (Tree::Example::HashNode::Sub6) {id=>19102,level=>6}
 |   |       \-- (Tree::Example::HashNode::Sub4) {id=>8106,level=>4}
 (... 20386 more line(s) not shown ...)

=item * size=medium1, backend=array

 (Tree::Example::ArrayNode) [1,0,undef,"<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>"]
 |-- (Tree::Example::ArrayNode::Sub1) [2,1,"<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>","<obj>"]
 |   |-- (Tree::Example::ArrayNode::Sub2) [102,2,"<obj>","<obj>","<obj>"]
 |   |   |-- (Tree::Example::ArrayNode::Sub3) [3102,3,"<obj>","<obj>","<obj>"]
 |   |   |   |-- (Tree::Example::ArrayNode::Sub4) [8102,4,"<obj>"]
 |   |   |   \-- (Tree::Example::ArrayNode::Sub4) [8103,4,"<obj>","<obj>"]
 |   |   |       \-- (Tree::Example::ArrayNode::Sub5) [16102,5,"<obj>"]
 |   |   \-- (Tree::Example::ArrayNode::Sub3) [3103,3,"<obj>","<obj>"]
 |   |       \-- (Tree::Example::ArrayNode::Sub4) [8104,4,"<obj>"]
 |   |-- (Tree::Example::ArrayNode::Sub2) [103,2,"<obj>","<obj>"]
 |   |   \-- (Tree::Example::ArrayNode::Sub3) [3104,3,"<obj>","<obj>","<obj>"]
 |   |       |-- (Tree::Example::ArrayNode::Sub4) [8105,4,"<obj>","<obj>"]
 |   |       |   \-- (Tree::Example::ArrayNode::Sub5) [16103,5,"<obj>","<obj>"]
 |   |       |       \-- (Tree::Example::ArrayNode::Sub6) [19102,6,"<obj>"]
 |   |       \-- (Tree::Example::ArrayNode::Sub4) [8106,4,"<obj>"]
 (... 20386 more line(s) not shown ...)

=back

=head1 FUNCTIONS


=head2 gen_sample_data(%args) -> obj

Generate sample tree object.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backend> => I<str> (default: "hash")

=item * B<size>* => I<str>

Which tree to generate.

There are several predefined sizes to choose from.

C<tiny1> is a very tiny tree, with only depth of 2 and a total of 3 nodes,
including root node.

C<small1> is a small tree with depth of 4 and a total of 16 nodes, including root
node.

C<medium1> is a tree of depth 7 and ~20k nodes, which is about the size of
C<Org::Document> tree generated when parsing my C<todo.org> document circa early
2016 (~750kB, ~2900 todo items).

=back

Return value:  (obj)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-Tree-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-Tree-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-Tree-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<dump-perlancar-sample-tree> (L<App::DumpPERLANCARSampleTree>), a simple CLI to
conveniently view the sample data.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
