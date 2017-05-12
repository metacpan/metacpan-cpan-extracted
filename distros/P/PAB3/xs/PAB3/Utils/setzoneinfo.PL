$src_path = 'zoneinfo';
$dst_path = '../../../blib/arch/auto/PAB3/Utils/zoneinfo';
&dir_copy( $src_path, $dst_path );

1;

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

sub dir_copy {
	my( $src, $dst ) = @_;
	my( $dh, $item );
	if( ! -d $dst ) {
		mkdir( $dst ) or warn "Can not create dir $dst: $!";
	}
	opendir( $dh, $src );
	while( $item = readdir( $dh ) ) {
		next if substr( $item, 0, 1 ) eq '.';
		if( -d $src . '/' . $item ) {
			&dir_copy( $src . '/' . $item, $dst . '/' . $item );
			next;
		}
		elsif( index( $item, '.ics' ) > 0 ) {
			if( ! -e $dst . '/' . $item ) {
				print "Zoneinfo preparing \"$src/$item\"\n";
				#print "$src/$item\n";
			}
			&file_copy( $src . '/' . $item, $dst . '/' . $item );
		}
	}
	closedir( $dh );
}
