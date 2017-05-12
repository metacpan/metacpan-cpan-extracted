#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 16;

use SVN::Dumpfile::Node;


=pod

=head1 Test $node->header method

=head2 First generate test node

=cut

my $node = SVN::Dumpfile::Node->new( content => 'test content' );
ok ( $node );


=head2 Check if correct class and content got generated correct

=cut

isa_ok ( $node->{contents}, 'SVN::Dumpfile::Node::Content' );
isa_ok ( $node->contents, 'SVN::Dumpfile::Node::Content' );
is ( ${$node->{contents}}, 'test content' );


=head2 Test content->value and stringification

=cut

is ( $node->contents->value, 'test content' );
is ( $node->contents->as_string, 'test content' );
is ( $node->contents->to_string, 'test content' );
is ( $node->contents() . "", 'test content' );


=head2 Test content->value(new value)

=cut

is ( $node->contents->value('new content'), 'new content' );
is ( $node->contents->value, 'new content' );


=head2 Test content->value() = new value

=cut

is ( $node->contents->value = 'newer content', 'newer content' );
is ( $node->contents->value, 'newer content' );


=head2 Test content()->delete and has_content()

=cut

ok ( $node->has_contents );
is ( $node->contents->delete, undef );
ok ( !$node->has_contents );

$node->contents->value('test');

$node->content =~ s/t/T/g;
isa_ok( $node->contents, 'SVN::Dumpfile::Node::Content');


