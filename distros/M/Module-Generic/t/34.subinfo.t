#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Module::Generic - t/subinfo.t
## Tests for the _subinfo helper method in Module::Generic
## Verifies that the _subinfo method provides the information expected.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use utf8;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use open ':std' => 'utf8';
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

# Ensure we can load Module::Generic at all
use_ok( 'Module::Generic' ) or BAIL_OUT( "Cannot load Module::Generic" );

my $obj = Module::Generic->new( debug => $DEBUG ) or
    BAIL_OUT( 'Cannot instantiate a new object for Module::Generic' );

# Helper to make tests cleaner
sub test_subinfo
{
    my( $desc, $sub ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $name = $obj->_subinfo( $sub );
    ok( defined( $name ), "$desc: scalar context returns name" );

    my @info = $obj->_subinfo( $sub );
    is( $info[0], $name,  "$desc: first element matches scalar result" );
    is( ref( $info[-1] ), 'HASH', "$desc: last element is hashref" );

    return( $info[-1] );
}

# NOTE: Named subroutine
sub named_sub {1}
my $info = test_subinfo( "Named sub", \&named_sub );
is( $info->{name},       'named_sub', 'name correct' );
is( $info->{is_anon},    0,           'not anonymous' );
is( $info->{is_closure}, 0,           'not closure' );
is( $info->{is_xsub},    0,           'not xsub' );

# NOTE: Method
# add a method for testing
$info = test_subinfo( 'Method', \&Module::Generic::init );
# or call it from inside a method

# NOTE: Method (call from inside a method for reliability)
sub test_method
{
    my $self = shift( @_ );
    my $method_info = ($self->_subinfo())[-1];

    is( $method_info->{name},       'test_method', 'method name detected'  );
    is( $method_info->{is_closure}, 0,             'method is not closure' );
}

test_method( $obj );

sub test_named_closure
{
    my $method_info = ($obj->_subinfo())[-1];
    return( $method_info );
}

$info = test_named_closure();
is( $info->{is_closure}, 1, 'named sub capturing lexical is closure' );

# NOTE: Anonymous sub
my $anon = sub {42};
$info = test_subinfo( 'Anonymous sub', $anon );
is( $info->{name},       '__ANON__', 'name is __ANON__' );
is( $info->{is_anon},    1,          'is_anon flag set' );
is( $info->{is_closure}, 0,          'anonymous sub is not closure' );

# NOTE: Closure
my $make_closure = sub
{
    my $x = shift( @_ );
    # this creates a real closure
    return( sub{ $x + 1 } );
};
my $closure = $make_closure->(10);
$info = test_subinfo( 'Closure', $closure );
is( $info->{is_closure}, 1, 'detected as closure' ) or
    diag( "Closure flags: " . sprintf( '%#b', B::svref_2object( $closure )->FLAGS ) );

# NOTE: Prototype
sub proto_sub ($$@) {1}
$info = test_subinfo( 'Sub with prototype', \&proto_sub );
is( $info->{prototype}, '$$@', 'prototype captured correctly' );

# NOTE: Auto-detect mode
sub test_auto_detect
{
    my $name = $obj->_subinfo();  # no argument
    is( $name, 'test_auto_detect', 'auto-detect works' );
}
test_auto_detect();

sub test_auto_detect_list
{
    my @auto_info = $obj->_subinfo();  # called in list context
    my $auto_info = $auto_info[-1];

    is( $auto_info->{name}, 'test_auto_detect_list', 'auto-detect works' );
}
test_auto_detect_list();

# NOTE: Error cases
{
    no warnings;
    ok( !defined( $obj->_subinfo(undef) ),             'undef argument -> error' );
    ok( !defined( $obj->_subinfo( 'not a coderef' ) ), 'non-CODE ref -> error' );
}

done_testing();

__END__
