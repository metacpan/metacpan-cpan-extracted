#use Cwd;

$path = '';
if( $ARGV[0] eq 'pab' ) {
	$path = '../../../../../';
}
&file_copy( 'Mysql.pm', $path . 'blib/lib/PAB3/DB/Driver/Mysql.pm' );

if( $^O eq 'MSWin32' ) {
	if( -f 'libmysql.dll' ) {
		&file_copy( 'libmysql.dll', , $path . 'blib/arch/auto/PAB3/DB/Driver/Mysql/libmysql.dll' );
	}
}

1;

sub file_copy {
	my( $src, $dst ) = @_;
	my( $sfh, $dfh, $buf );
	return if ! -f $src;
	unlink( $dst );
	open( $sfh, '<', $src ) or warn "Could not open $src: $!";
	binmode( $sfh );
	open( $dfh, '>', $dst ) or warn "Could not open $dst: $!";
	binmode( $dfh );
	while( read( $sfh, $buf, 8192 ) ) {
		print $dfh $buf;
	}
	close( $dfh );
	close( $sfh );
	chmod( 0664, $dst );
}
