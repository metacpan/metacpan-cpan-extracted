#!perl -T

use strict;
use warnings;

BEGIN { chdir 't' if -d 't' }

use Test::More tests => 38;
use Test::Exception;

my $module = 'Sub::Context' ;
use_ok( $module );

can_ok( $module, '_qualify_sub' );

is( $module->_qualify_sub( 'main', 'ok' ), 'main::ok',
	'_qualify_sub() should find sub in given package name, _qualifying it' );

is( $module->_qualify_sub( 'main', 'Test::More::ok' ), 'Test::More::ok',
	'... or should find sub given fully-qualified name' );

is( $module->_qualify_sub( 'main', 'Test::More::fake' ), 'Test::More::fake',
	'... even if sub does not exist' );

can_ok( $module, '_find_glob' );
is( $module->_find_glob( 'Test::More::ok' ), \*Test::More::ok,
	'_find_glob() should find named glob' );
is( $module->_find_glob( 'Test::More::morefake' ), \*Test::More::morefake,
	'... even if it does not exist yet' );
my $foo = \*Test::More::morefake;

can_ok( $module, '_validate_contexts' );
my %ctxs = ( foo => 'bar' );
throws_ok { $module->_validate_contexts( \%ctxs ) }
	qr/Context type 'foo' not allowed!/,
	'_validate_contexts() should die given invalid context';
%ctxs    = ( void => 'bar' );
lives_ok { $module->_validate_contexts( \%ctxs ) }
	'... but should live otherwise';

can_ok( $module, '_fetch_glob' );
use vars qw( $foo @foo );
sub foo {};
my $foo_ref = \&foo;
$foo        = 10;
@foo        = qw( keep me );
my $glob    = $module->_fetch_glob( 'main::foo' );
isnt( $foo_ref, \&foo, '_fetch_glob() should not copy CODE slot' );
is( $foo, 10, '... but should copy other slots' );
is( "@foo", 'keep me', '... unmodified' );

$glob       = $module->_fetch_glob( 'main::blah' );
ok( $glob, '... and should return new glob if it does not exist' );

can_ok( $module, '_contexts' );
is_deeply( [ $module->_contexts() ], [qw( void scalar list )],
	'_contexts() should return available contexts' );

can_ok( $module, '_generate_contexts' );
%ctxs = ();
$module->_generate_contexts( 'avacado', \%ctxs );
is( keys %ctxs, 3, '_generate_contexts() should add fallback contexts' );
is_deeply( [ sort keys %ctxs ], [qw( list scalar void )],
	'... for the given contexts' );

for my $ctx (qw( list scalar void ))
{
	throws_ok { $ctxs{$ctx}->() } qr/No sub for $ctx context/,
		'... default throwing an exception, with no sub defined';
}

%ctxs = ();
$module->_generate_contexts( 'main::ok', \%ctxs );
is( keys %ctxs, 3, '... or setting fallback to defined sub' );
is_deeply( { void => \&ok, scalar => \&ok, list => \&ok }, \%ctxs,
	'... pointing all unused contexts at wrapped subroutine if it exists' );

%ctxs = ( void => \&is );
$module->_generate_contexts( 'main::ok', \%ctxs );

is_deeply( \%ctxs, { void => \&is, scalar => \&ok, list => \&ok },
	'... but not overwriting existing wrap' );

%ctxs = ( void => \'hi', scalar => [ 1, 2 ], list => { 3 => 4 } );
$module->_generate_contexts( 'main::ok', \%ctxs );

is( $ctxs{void},   \&ok, '... not allowing scalar references' );
is( $ctxs{scalar}, \&ok, '... not allowing array references' );
is( $ctxs{list},   \&ok, '... and not allowing hash references' );

can_ok( $module, '_apply_contexts' );
my $void = 0;
$module->_apply_contexts( \*bar, {
	void   => sub { $void = 1 },
	list   => sub { qw( a list ) },
	scalar => sub { 'scalar' },
});
ok( defined &bar, '_apply_contexts() should populate glob with a sub' );
bar();
is( $void,                     1, '... doing the right thing in void context' );
is( bar(),              'scalar', '... in scalar context'   );
is( join( ' ', bar() ), 'a list', '... and in list context' );

can_ok( $module, '_default_sub' );
is( $module->_default_sub( 'Test::Builder::ok', 'foo' ), \&Test::Builder::ok,
	'_default_sub() should return named subref if it exists' );
my $croaker = $module->_default_sub( 'main::pickle', 'foo', ':boo' );
throws_ok { $croaker->() } qr/No sub for foo context:boo/,
	'... or a default croaking sub';
