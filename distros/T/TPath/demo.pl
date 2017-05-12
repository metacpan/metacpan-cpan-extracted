#!/usr/bin/perl

use strict;
use warnings;
use Carp;

# we define our trees
package MyTree;

use overload '""' => sub {
    my $self     = shift;
    my $tag      = $self->{tag};
    my @children = @{ $self->{children} };
    return "<$tag/>" unless @children;
    local $" = '';
    "<$tag>@children</$tag>";
};

sub new {
    my ( $class, %opts ) = @_;
    die 'tag required' unless $opts{tag};
    bless { tag => $opts{tag}, children => $opts{children} // [] }, $class;
}

sub add {
    my ( $self, @children ) = @_;
    push @{ $self->{children} }, $_ for @children;
}

# teach TPath::Forester how to get the information it needs
package MyForester;
use Moose;
use MooseX::MethodAttributes;    # needed for @tag attribute below
with 'TPath::Forester';

# implement required methods

sub children {
    my ( $self, $n ) = @_;
    @{ $n->{children} };
}

sub tag : Attr {                 # also an attribute!
    my ( $self, $ctx ) = @_;
    $ctx->n->{tag};
}

package main;

# make the tree
#      a
#     /|\
#    / | \
#   b  c  \
#  /\  |   d
#  e f |  /|\
#      h / | \
#     /| i j  \
#    l | | |\  \
#      m n o p  \
#     /|    /|\  \
#    s t   u v w  k
#                / \
#               q   r
#                  / \
#                 x   y
#                     |
#                     z
my %nodes = map { $_ => MyTree->new( tag => $_ ) } 'a' .. 'z';
$nodes{a}->add($_) for @nodes{qw(b c d)};
$nodes{b}->add($_) for @nodes{qw(e f)};
$nodes{c}->add( $nodes{h} );
$nodes{d}->add($_) for @nodes{qw(i j k)};
$nodes{h}->add($_) for @nodes{qw(l m)};
$nodes{i}->add( $nodes{n} );
$nodes{j}->add($_) for @nodes{qw(o p)};
$nodes{k}->add($_) for @nodes{qw(q r)};
$nodes{m}->add($_) for @nodes{qw(s t)};
$nodes{p}->add($_) for @nodes{qw(u v w)};
$nodes{r}->add($_) for @nodes{qw(x y)};
$nodes{y}->add( $nodes{z} );
my $root = $nodes{a};

# make our forester
my $rhood = MyForester->new;

# index our tree (not necessary, but efficient)
my $index = $rhood->index($root);

# try out some paths
my @nodes = $rhood->path('//r')->select( $root, $index );
print scalar @nodes, "\n";    # 1
print $nodes[0], "\n";        # <r><x/><y><z/></y></r>
print $_
  for $rhood->path('leaf::*[@tag > "o"]')->select( $root, $index )
  ;                           # <s/><t/><u/><v/><w/><q/><x/><z/>
print "\n";
print $_->{tag}
  for $rhood->path('//*[@tsize = 3]')->select( $root, $index );    # bm
print "\n";
@nodes = $rhood->path('/>~[bh-z]~')->select( $root, $index );
print $_->{tag} for @nodes;                                        # bhijk
print "\n";

# we can map nodes back to their parents
@nodes = $rhood->path('//*[parent::~[adr]~]')->select( $root, $index );
print $_->{tag} for @nodes;                                        # bcijxykd
print "\n";
