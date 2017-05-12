$src_path = 'locale/';
$dst_path = '../../../blib/arch/auto/PAB3/Utils/locale/';
if( ! -d $dst_path ) {
	mkdir( $dst_path ) or warn "Can not create dir $dst_path: $!";
}
opendir( $dh, $src_path );
while( $file = readdir( $dh ) ) {
	next if substr( $file, 0, 1 ) eq '.';
	if( ! -e $dst_path . $file ) {
		print "Locale preparing \"$file\"\n";
	}
	&file_copy( $src_path . $file, $dst_path . $file );
}
closedir( $dh );

1;

sub file_copy {
	my( $src, $dst ) = @_;
	my( $sfh, $dfh, $buf );
	return if ! -f $src;
	open( $sfh, '<', $src ) or warn "Could not open $src: $!";
	binmode( $sfh );
	open( $dfh, '>', $dst ) or warn "Could not open $dst: $!";
	binmode( $dfh );
	while( read( $sfh, $buf, 8192 ) ) {
		print $dfh $buf;
	}
	close( $dfh );
	close( $sfh );
}
