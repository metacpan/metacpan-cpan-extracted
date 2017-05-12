#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 31;

use SVN::Dumpfile::Node;

=pod

=head1 Test $node->header method

=head2 First generate test node

=cut

my $node = SVN::Dumpfile::Node->new(
    headers => {
        test  => 'abc123',
        other => 'Test me'
    }
);

ok($node);
isa_ok( $node->{headers}, 'SVN::Dumpfile::Node::Headers' );
is( $node->{headers}{test},  'abc123' );
is( $node->{headers}{other}, 'Test me' );

=head2 Test has_header(name)

=cut

ok( $node->has_header('test')  );
ok( $node->has_header('other') );
ok( !$node->has_header('flskgfls') );

=head2 Test header(name)

=cut

is( $node->header('test'),  'abc123' );
is( $node->header('other'), 'Test me' );

=head2 Test header(name, new value)

=cut

is( $node->header( 'test',  'new' ),    'new' );
is( $node->header( 'other', 'string' ), 'string' );
is( $node->header('test'),  'new' );
is( $node->header('other'), 'string' );

=head2 Test header(name) = new_value

=cut

is( $node->header('test')  = 'newer', 'newer' );
is( $node->header('other') = 'stuff', 'stuff' );
is( $node->header('test'),  'newer' );
is( $node->header('other'), 'stuff' );

=head2 Test headers()

Should return hash ref like $node->{headers}.

=cut

is( ref $node->headers,          'SVN::Dumpfile::Node::Headers' );
is( ref $node->headers(),        'SVN::Dumpfile::Node::Headers' );
is( $node->headers->{'test'},    'newer' );
is( $node->headers->{'other'},   'stuff' );
is( $node->headers()->{'test'},  'newer' );
is( $node->headers()->{'other'}, 'stuff' );

=head2 Test generation of new headers

=cut

is( $node->header( 'new1', 'text1' ), 'text1' );
is( $node->header('new2') = 'text2', 'text2' );
is( $node->headers->{'new3'} = 'text3', 'text3' );

is( $node->header('new1'), 'text1' );
is( $node->header('new2'), 'text2' );
is( $node->header('new3'), 'text3' );


=head2 Test if 'exists' is working

=cut

ok( $node->has_headers         );
ok(!SVN::Dumpfile::Node->new->has_headers);



