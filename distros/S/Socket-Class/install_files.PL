use File::Copy;

if( -d 'blib/arch/auto/Socket/Class' ) {
	&copy( 'mod_sc.h', 'blib/arch/auto/Socket/Class/mod_sc.h' );
}

1;
