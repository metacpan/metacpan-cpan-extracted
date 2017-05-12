use strict;
use warnings;

use Test::More tests => 2;

use Scalar::Util qw(refaddr);
use OO::InsideOut qw(id register);

use t::Class::Simple;

# 1
is( 
    refaddr( \&main::register ), 
    refaddr( \&OO::InsideOut::register ), 
    'exported' 
);

# 2
is_deeply( $t::Class::Simple::Register, {}, 'registered' );
