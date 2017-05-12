
use strict;
use warnings;

use Test::More tests => 14;

BEGIN { use_ok('Queue::Base') }

################################################################################

our @testElements = qw(one two three);

# simple add/remove (queue size)
my $q = new_ok('Queue::Base');
ok( $q->size() == 0 );

$q->add('one');
$q->add('two');
$q->remove();
$q->add('three');
ok( $q->size() == 2 );

$q->remove();
$q->remove();
ok( $q->empty() );
ok( !defined( $q->remove() ) );

# simple add/remove (content)
my $q2 = new Queue::Base;

$q2->add('one');
$q2->add('two');
$q2->add('three');

my @read2;
my $element = $q2->remove();
push( @read2, $element );
$element = $q2->remove();
push( @read2, $element );
$element = $q2->remove();
push( @read2, $element );

is_deeply( [@testElements], [@read2] );

ok( !defined( $q2->remove() ) );

# add/remove multiple elements
my $q3 = new Queue::Base;
$q3->add( 'one', 'two' );
$q3->add('three');

my @read3;
push( @read3, $q3->remove(2) );
push( @read3, $q3->remove() );

is_deeply( [@testElements], [@read3] );

# the queue is now empty
ok( !defined( $q3->remove() ) );

# try to remove more nonexistent elements
push( @read3, $q3->remove(5) );

is_deeply( [@testElements], [@read3] );

# initializing the queue
my $q4 = new Queue::Base( [@testElements] );
is_deeply( [@testElements], [ $q4->remove( $q4->size() ) ] );

my $q4a = new Queue::Base( [@testElements] );
is_deeply( [@testElements], [ $q4a->remove_all() ] );

# clear the queue
my $q5 = new Queue::Base( [@testElements] );
$q5->clear();

ok( $q5->empty() );
