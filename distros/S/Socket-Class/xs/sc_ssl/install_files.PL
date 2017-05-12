use File::Copy;

if( -d 'blib/arch/auto/Socket/Class/SSL' ) {
	&copy( 'mod_sc_ssl.h', 'blib/arch/auto/Socket/Class/SSL/mod_sc_ssl.h' );
	&copy( 'cert/server.key', 'blib/arch/auto/Socket/Class/SSL/server.key' );
	&copy( 'cert/server.crt', 'blib/arch/auto/Socket/Class/SSL/server.crt' );
	mkdir 'blib/arch/auto/Socket/Class/SSL/openssl';
	&copy( 'openssl/openssl.conf', 'blib/arch/auto/Socket/Class/SSL/openssl/openssl.conf' );
	if( $^O eq 'MSWin32' ) {
		#mkdir 'blib/arch/auto/Socket/Class/SSL/openssl/bin';
		&copy( 'openssl/LICENSE', 'blib/arch/auto/Socket/Class/SSL/openssl/LICENSE' );
		&copy( 'openssl/mkcert.bat', 'blib/arch/auto/Socket/Class/SSL/openssl/mkcert.bat' );
		&copy( 'openssl/source/out32/openssl.exe', 'blib/arch/auto/Socket/Class/SSL/openssl/openssl.exe' );
	}
	else {
		&copy( 'openssl/mkcert.sh', 'blib/arch/auto/Socket/Class/SSL/openssl/mkcert.sh' );
		chmod 0755, 'blib/arch/auto/Socket/Class/SSL/openssl/mkcert.sh';
	}
}

1;
