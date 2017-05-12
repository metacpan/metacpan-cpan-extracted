
if( $^O eq 'MSWin32' ) {
	if( $ARGV[0] eq 'pab' ) {
		$path = '../../../../../';
		&copy_dlls( '', $path . 'blib/arch/auto/PAB3/DB/Driver/Postgres/' );
	}
	elsif( $ARGV[0] eq 'self' ) {
		$path = '';
		&copy_dlls( '', $path . 'blib/arch/auto/PAB3/DB/Driver/Postgres/' );
	}
}

1;

sub copy_dlls {
	my( $source, $dest ) = @_;
	return if $^O ne 'MSWin32';
	my @dlls = (
		'libpq.dll', 'comerr32.dll', 'libintl-2.dll', 'libiconv-2.dll',
		'krb5_32.dll', 'libeay32.dll', 'ssleay32.dll'
	);
	foreach( @dlls ) {
		if( -f $source . $_ ) {
			&file_copy( $source . $_, $dest . $_ );
		}
	}
}

sub file_copy {
	my( $src, $dst ) = @_;
	my( $sfh, $dfh, $buf );
	return if ! -f $src;
	open( $sfh, '<', $src ) or warn "Can not open $src: $!";
	binmode( $sfh );
	open( $dfh, '>', $dst ) or warn "Can not open $dst: $!";
	binmode( $dfh );
	while( read( $sfh, $buf, 8192 ) ) {
		print $dfh $buf;
	}
	close( $dfh );
	close( $sfh );
}

