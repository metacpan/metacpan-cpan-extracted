# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-Dumpfilter.t'

#########################

use Test::More tests => 106;

use SVN::Dumpfile::Node;
ok( 1, 'Module loading' );    # If we made it this far, we're ok.

#use Data::Dumper;
#open( LOG, ">/home/martin/log.txt" );

my $node;
$node = eval { new SVN::Dumpfile::Node };
ok( defined $node, 'new() returns value' );
isa_ok( $node, 'SVN::Dumpfile::Node', 'new() returns correct class' );
ok( defined $node->new(), '$object->new() returns value' );
isa_ok( $node->new(), 'SVN::Dumpfile::Node',
    '$object->new() returns correct class' );

$node =
  eval { new SVN::Dumpfile::Node( headers => { a => 1, b => 2, c => 3 } ) };
ok( defined $node );
is( $node->{headers}->{'a'}, '1' );
is( $node->{headers}->{'b'}, '2' );
is( $node->{headers}->{'c'}, '3' );
is( $node->header('a'),     '1' );
is( $node->header('b'),     '2' );
is( $node->header('c'),     '3' );
is_deeply( $node->{headers}, $node->headers );

$node =
  eval { new SVN::Dumpfile::Node( headers => [ a => 1, b => 2, c => 3 ] ) };
ok( defined $node );
is( $node->{headers}->{'a'}, '1' );
is( $node->{headers}->{'b'}, '2' );
is( $node->{headers}->{'c'}, '3' );
ok( !$node->has_properties );

$node =
  eval { new SVN::Dumpfile::Node( properties => { a => 1, b => 2, c => 3 } ) };
ok( defined $node );
ok( $node->has_properties );
is( $node->{properties}->number, 3);
is( $node->{properties}->{property}->{'a'}, '1' );
is( $node->{properties}->{property}->{'b'}, '2' );
is( $node->{properties}->{property}->{'c'}, '3' );
ok( $node->has_property('a') );
ok( $node->has_property('b') );
ok( $node->has_property('c') );
ok(!$node->has_property('d') );
is( $node->property('a'), '1' );
is( $node->property('b'), '2' );
is( $node->property('c'), '3' );
is( $node->changed, undef );
ok( $node->has_changed );

is( $node->property('other') = 'bla', 'bla' );
is( $node->property('other'), 'bla' );
is( $node->{properties}->number, 4);

ok( $node->{properties}->add('third','test',2) );
is( $node->property('third'), 'test' );
is( $node->{properties}->{order}->[2], 'third' );
is( $node->{properties}->number, 5);

ok( $node->{properties}->add('last','test2') );
is( $node->property('last'), 'test2' );
is( $node->{properties}->{order}->[-1], 'last' );
is( $node->{properties}->number, 6);

ok( $node->{properties}->del('last') );
ok( !exists $node->properties->{'last'} );
isnt( $node->{properties}->{order}->[-1], 'last' );
is( $node->{properties}->number, 5);

ok( $node->{properties}->mark_deleted('third') );
is( $node->{properties}->number, 4);
ok( !exists $node->properties->{'third'} );
is( $node->{properties}->{deleted}->[-1], 'third' );
ok( $node->{properties}->is_deleted('third') );

ok( $node->{properties}->mark_deleted('other') );
is( $node->{properties}->number, 3);
ok( !exists $node->properties->{'other'} );
is( $node->{properties}->{deleted}->[-1], 'other' );
ok( $node->{properties}->is_deleted('other') );

is( scalar $node->{properties}->list_deleted, 2);
is_deeply( [ $node->{properties}->list_deleted ], [ 'third', 'other' ] );

ok( $node->{properties}->unmark_deleted('other') );
is( $node->{properties}->number, 3);
ok( !exists $node->properties->{'other'} );
ok( !$node->{properties}->is_deleted('other') );

is( scalar $node->{properties}->list_deleted, 1);
is_deeply( [ $node->{properties}->list_deleted ], [ 'third' ] );


$node =
  eval { new SVN::Dumpfile::Node( properties => [ a => 1, b => 2, c => 3 ] ) };
ok( defined $node );
is( $node->{properties}->number, 3);
is ( $node->{properties}->{order}->[0], 'a' );
is ( $node->{properties}->{order}->[1], 'b' );
is ( $node->{properties}->{order}->[2], 'c' );

my $prop;
$prop =
  eval { new SVN::Dumpfile::Node::Properties( { a => 1, b => 2, c => 3 } ) };
ok( defined $prop );
is( $prop->number, 3);
is( $prop->{property}->{'a'}, '1' );
is( $prop->{property}->{'b'}, '2' );
is( $prop->{property}->{'c'}, '3' );

$prop =
  eval { new SVN::Dumpfile::Node::Properties( [ a => 1, b => 2, c => 3 ] ) };
ok( defined $prop );
is( $prop->number, 3);
is( $prop->{property}->{'a'}, '1' );
is( $prop->{property}->{'b'}, '2' );
is( $prop->{property}->{'c'}, '3' );


$prop =
  eval { new SVN::Dumpfile::Node::Properties(  a => 1, b => 2, c => 3  ) };
ok( defined $prop );
is( $prop->number, 3);
is( $prop->{property}->{'a'}, '1' );
is( $prop->{property}->{'b'}, '2' );
is( $prop->{property}->{'c'}, '3' );

$prop =
  eval { new SVN::Dumpfile::Node::Properties(  a => 1, b => 2, c => 3, 'd' ) };
ok( !defined $prop );
like( $@, qr/^SVN::Dumpfile::Node::Properties::new\(\) awaits hashref or key\/value pairs as arguments\./);

$prop =
  eval { new SVN::Dumpfile::Node::Properties( undef ) };
ok( defined $prop );

$prop =
  eval { new SVN::Dumpfile::Node::Properties(  ) };
ok( defined $prop );

my $test_string = 'Hello, I\'m a test string!';
$node = eval { new SVN::Dumpfile::Node( content => $test_string ) };
ok( defined $node );
is( $node->contents->as_string, $test_string );
is( $node->contents->value    , $test_string );
is( $node->contents           , $test_string );
is( $node->contents->value = 'other test string', 'other test string');
is( $node->contents->value, 'other test string');
is( $node->contents->value ('third test string'), 'third test string');
is( $node->contents->value, 'third test string');
ok( $node->contents->exists );
ok( $node->has_contents );
is( $node->contents->lines, 1 );
$node->contents->value("test\012string\012with\012linebreaks.");
is( $node->contents->lines, 4 );
$node->contents->value("test\012string\012with\012linebreaks.\012");
is( $node->contents->lines, 4 );

is( $node->contents->delete, undef );
ok( !$node->contents->exists );
ok( !$node->has_contents );

#TODO: {
#    local $TODO = "::Headers::sanitycheck() not complete converted to OO
#    module.\n";
#    is ( eval { $node->{headers}->sanitycheck() }, 0 );
#}

1;
