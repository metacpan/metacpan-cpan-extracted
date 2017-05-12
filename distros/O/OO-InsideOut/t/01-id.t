use strict;
use warnings;

use Test::More tests => 2;

use Scalar::Util qw(refaddr);
use OO::InsideOut qw(id);

use t::Class::Simple;

# 1
is( 
    refaddr( \&main::id ), 
    refaddr( \&OO::InsideOut::id ), 
    'exported' 
);

# 2
my $object = t::Class::Simple->new();
is( id( $object ), refaddr( $object ), 'refaddr' );
