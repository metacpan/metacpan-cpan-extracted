use inc::Module::Install;

use Test::More tests => 8;

use File::Spec;

use strict;
use warnings;

name( 'foo' );
version( '33' );

@ARGV = ( "INSTALL_BASE=prefix" );
template_install_path();
is( $ARGV[0], "INSTALL_BASE=prefix", "no CL tokens" );

@ARGV = ( "INSTALL_BASE=prefix" );
template_install_path( template => '%v-%n' );
is( $ARGV[0], File::Spec->catdir( 'INSTALL_BASE=prefix', '33-foo'), "supplied template, no CL tokens" );

@ARGV = ( "INSTALL_BASE=prefix" );
template_install_path( template => '%v-%n', catdir => 0 );
is( $ARGV[0], "INSTALL_BASE=33-foo", "supplied template, no CL tokens, catdir => 0" );


@ARGV = ( "INSTALL_BASE=prefix/%v" );
template_install_path( );
is( $ARGV[0], "INSTALL_BASE=prefix/33", "default template, CL tokens" );

@ARGV = ( "INSTALL_BASE=prefix/%v-%k" );
template_install_path( tokens => { '%k' => 'frosty' } );
is( $ARGV[0], "INSTALL_BASE=prefix/33-frosty", "added static token" );

@ARGV = ( "INSTALL_BASE=prefix/%v-%N" );
template_install_path( tokens => { '%N' => sub { uc($_[0]->name) } } );
is( $ARGV[0], "INSTALL_BASE=prefix/33-FOO", "added sub token" );

@ARGV = ( "INSTALL_BASE=prefix/%n-%v" );
template_install_path( tokens => { '%n' => sub { uc($_[0]->name) } } );
is( $ARGV[0], "INSTALL_BASE=prefix/FOO-33", "override token" );

@ARGV = ( "INSTALL_BASE=prefix/%n-%v" );
template_install_path( tokens => { '%n' => undef } );
is( $ARGV[0], "INSTALL_BASE=prefix/%n-33", "delete token" );
