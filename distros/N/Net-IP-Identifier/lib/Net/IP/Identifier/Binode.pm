#!/usr/bin/perl
#===============================================================================
#      PODNAME:  Net::IP::Identifier::Binode
#     ABSTRACT:  A node in the binary tree
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Mon Oct  6 10:20:33 PDT 2014
#===============================================================================

use 5.002;
use strict;
use warnings;

$DB::deep = 150;    # IPv6 needs 128 plus some headroom

package Net::IP::Identifier::Binode;
use Carp;
use Math::BigInt;
use Moo;
use namespace::clean;

our $VERSION = '0.111'; # VERSION

has zero => (
    is => 'rw',
    isa => \&isnode,
);
has one => (
    is => 'rw',
    isa => \&isnode,
);
has payload => (
    is => 'rw',
);

sub isnode {
    die if defined $_[0] and ref $_[0] ne __PACKAGE__;
}

sub bin_to_ip {
    my ($bin) = @_;

    my @results;
    my $max = length $bin;
    for (my $ii = 0; ; $ii++) {
        if ($ii % 8 == 0) {
            last if ($ii >= $max);
            push @results, 0;
        }
        my $b = $ii < $max ? substr($bin, $ii, 1) : 0;
        $results[-1] <<= 1;
        $results[-1] |= $b;
    }
    return join '.', @results;
}

our $path = Math::BigInt->new(0);
sub construct {
    my ($self, $path) = @_;

    my $node;
    $self->_follow(
        $path,
        0,
        sub {   # construction callback
            my ($self, $path, $level) = @_;

            if ($level < length $path) {
                if (substr($path, $level, 1)) {    # next step
                    $self->one($self->new) if (not $self->one);
                }
                else {
                    $self->zero($self->new) if (not $self->zero);
                }
            }
            else {
                $node = $self;  # when we reach the end
            }
            return 0;   # always continue
        }
    );
    return $node;
}

sub follow {
    my ($self, $path, $callback, @extra) = @_;

    croak "Need a code ref\n" if (not $callback or ref $callback ne 'CODE');
    return $self->_follow($path, 0, $callback, @extra);
}

sub _follow {
    no warnings 'recursion';    # IPv6 requires at least 128 levels
    my ($self, $path, $level, $callback, @extra) = @_;

    return if $callback->($self, $path, $level, @extra);

    return $self if ($level >= length $path); # end of the line

    if (substr($path, $level, 1)) {    # next step
        return $self->one->_follow($path, $level + 1, $callback, @extra) if ($self->one);
    }
    else {
        return $self->zero->_follow($path, $level + 1, $callback, @extra) if ($self->zero);
    }
    return; # no node at $path
}

sub traverse_width_first {
    my ($self, $callback, @extra) = @_;

    croak "Need a code ref\n" if (not $callback or ref $callback ne 'CODE');
    return $self->_traverse_width_first(0, $callback, @extra);
}

sub _traverse_width_first {
    no warnings 'recursion';    # IPv6 requires at least 128 levels
    my ($self, $level, $callback, @extra) = @_;

    return if $callback->($self, $level, @extra);

#$path <<= 1;
    $self->zero->_traverse_width_first($level + 1, $callback, @extra) if ($self->zero);
#$path |= 1;
    $self->one ->_traverse_width_first($level + 1, $callback, @extra) if ($self->one);
#$path >>= 1;
}

sub traverse_depth_first {
    my ($self, $callback, @extra) = @_;

    croak "Need a code ref\n" if (not $callback or ref $callback ne 'CODE');
    $self->_traverse_depth_first(0, $callback, @extra);
}

sub _traverse_depth_first {
    no warnings 'recursion';    # IPv6 requires at least 128 levels
    my ($self, $level, $callback, @extra) = @_;

    my $stop;
#print "path=", $path->as_hex, "\n";
#$path <<= 1;
    $stop = $self->zero->_traverse_depth_first($level + 1, $callback, @extra) if ($self->zero);
#$path |= 1;
    $stop = $self->one ->_traverse_depth_first($level + 1, $callback, @extra) if (not $stop and $self->one);
#$path >>= 1;

    $callback->($self, $level, @extra) if (not $stop);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Binode - A node in the binary tree

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Binode;

=head1 DESCRIPTION

Net::IP::Identifier::Binode represents a single node in a binary tree.  The branches off the
node are B<zero> and B<one>.  The node may also carry a B<$payload>.  Any of these may be set
via arguments to B<new> or through accessors.

=head2 Accessors (or arguments to B<new>)

=over

=item zero( [ $new ] )

Set or get the B<zero> branch.  If B<new> is defined, it must be a Net::IP::Identifier::Binode.

=item one( [ $new ] )

Set or get the B<one> branch.  If B<new> is defined, it must be a Net::IP::Identifier::Binode.

=item payload( [ $new ] )

Set or get the payload attached to this node.  B<new> can be anything.  It's a good idea to
create a Local::Payload object to hold the B<$payload>.

=back

=head2 Methods

In the following methods, any references to B<$path> mean a string
consisting of true and false characters (usually ones and zeroes) which
defines the path to follow to get to a particular node of the tree.  The
length of B<$path> represents the number of levels to descend.  False
characters ('0's) follow the B<zero> branch, and true characters follow the
B<one> branch.

=over

=item $node = $root->construct($path);

Construct a branch of the tree out to B<$path>.  New child nodes are
created as necessary.  The return value is the node at $path.

=item $node->follow($path, $callback, [ @extra ] );

Descend the binary tree, following B<$path>.  B<$callback> must be a code
reference, which will be called at each visited node.  It is called thusly:

    $callback->($self, $path, $level, @extra);

where B<$self> is the current node, B<$path> is the original path,
B<$level> is the current index into B<$path>, and @extra are just passed
along from the original call.

The callback must return true to stop following (abort the descent), or
false to continue normally.

=item $node->traverse_width_first($callback, [ @extra ] );

=item $node->traverse_depth_first($callback, [ @extra ] );

Traverse the binary tree, either width or depth first.

B<$callback> must be a code reference, which will be called at each node.
It is called thusly:

    $callback->($self, $level, @extra);

where B<$self> is the current node, B<$level> is the current depth
(starting with 0 at the entry node), and @extra are just passed along from
the original call.

The callback must return true to stop following (abort the descent), or
false to continue normally.

=back

=head1 SEE ALSO

=over

=item Net::IP::Identifier

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
