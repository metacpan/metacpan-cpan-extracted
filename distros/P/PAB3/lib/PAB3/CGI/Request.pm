package PAB3::CGI;
# =============================================================================
# Perl Application Builder
# Module: PAB3::CGI::Request
# Use "perldoc PAB3::CGI" for documenation
# =============================================================================

1;

sub _create_param {
	my( $key, $val, $post ) = @_;
	my( $len );
	$len = length( $key );
	if( substr( $key, $len - 2, 2 ) eq '[]' ) {
		$key = substr( $key, 0, $len - 2 );
		if( $post ) {
			$_POST{$key} = [] if ref( $_POST{$key} ) ne 'ARRAY';
			push @{$_POST{$key}}, $val;
		}
		else {
			$_GET{$key} = [] if ref( $_GET{$key} ) ne 'ARRAY';
			push @{$_GET{$key}}, $val;
		}
		$_REQUEST{$key} = [] if ref( $_REQUEST{$key} ) ne 'ARRAY';
		push @{$_REQUEST{$key}}, $val;
	}
	else {
		if( $post ) {
			$_POST{$key} .= defined $_POST{$key} ? "\0" . $val : $val;
		}
		else {
			$_GET{$key} .= defined $_GET{$key} ? "\0" . $val : $val;
		}
		$_REQUEST{$key} .= defined $_REQUEST{$key} ? "\0" . $val : $val;
	}
}

sub _add_param {
	my( $key, $val, $post ) = @_;
	my( $len );
	$len = length( $key );
	if( substr( $key, $len - 2, 2 ) eq '[]' ) {
		$key = substr( $key, 0, $len - 2 );
		if( $post ) {
			$_POST{$key} = [] if ref( $_POST{$key} ) ne 'ARRAY';
			${$_POST{$key}}[-1] .= $val;
		}
		else {
			$_GET{$key} = [] if ref( $_GET{$key} ) ne 'ARRAY';
			${$_GET{$key}}[-1] .= $val;
		}
		$_REQUEST{$key} = [] if ref( $_REQUEST{$key} ) ne 'ARRAY';
		${$_REQUEST{$key}}[-1] .= $val;
	}
	else {
		if( $post ) {
			$_POST{$key} .= $val;
		}
		else {
			$_GET{$key} .= $val;
		}
		$_REQUEST{$key} .= $val;
	}
}

sub _parse_request {
	my( $len, $type, $meth, $got, $input, $post, $jmp );
	
	%_GET = ();
	%_POST = ();
	%_REQUEST = ();
	%_FILES = ();
	
	binmode( STDIN ); 
	binmode( STDOUT );
	binmode( STDERR );

	$type = $ENV{'CONTENT_TYPE'};
	$len  = $ENV{'CONTENT_LENGTH'};
	$meth = $ENV{'REQUEST_METHOD'};
	
	if( $len && $RequestMaxData && $len > $RequestMaxData ) {
		&Carp::croak(
			"CGI Error: Request to receive too much data: $len bytes"
		);
	}

	my( @tb, $i, $iv, $key, $val );
	@tb = ();
	if( ! $meth ) {
		push @tb, @ARGV;
	}
	else {
		push @tb, split( /[&;]/, $ENV{'QUERY_STRING'} || '' );
		if( $meth eq 'POST' && index( $type, 'multipart/form-data' ) < 0 ) {
			$jmp = 'parse_post';
			goto parse_std;
parse_post:
			$jmp = undef;
			$post = 1;
			read( STDIN, $input, $len );
			push @tb, split( /[&;]/, $input );
		}
	}
parse_std:
	for $i( 0 .. $#tb ) {
		$iv = index( $tb[$i], '=' );
		if( $iv > 0 ) {
			$key = substr( $tb[$i], 0, $iv );
			$val = substr( $tb[$i], $iv + 1 );
			$key =~ tr/+/ /;
			$key =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge;
			if( $val ) {
				$val =~ tr/+/ /;
				$val =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge;
			}
			if( $post ) {
				&_create_param( $key, $val, 1 );
			}
			else {
				&_create_param( $key, $val, 0 );
			}
		}
		else {
			$tb[$i] =~ tr/+/ /;
			$tb[$i] =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge;
			if( $post ) {
				&_create_param( $tb[$i], '', 1 );
			}
			else {
				&_create_param( $tb[$i], '', 0 );
			}
		}
	}
	goto $jmp if $jmp;
	if( index( $type, 'multipart/form-data' ) >= 0 ) {
		my( $boundary, $blen, $bi, $bin, $head, $cd, $ct, $eoh, $name,
			$hl, $ctype, $buf, $bufsize, $fname, $writef, $fn, $ser,
			$hf, $fd, $cl
		);
		$bufsize = $MPartBufferSize || 8192;
		$writef = $SaveToFile ? $UploadFileDir || '/tmp/' : 0;
		($boundary) = $type =~ /boundary=\"([^\"]+)\"/;
		unless( $boundary ) {
			($boundary) = $type =~ /boundary=(\S+)/;
		}
		unless( $boundary ) {
			&Carp::croak( "Boundary not provided: probably a bug in your server" );
		}
		$boundary =  '--' . $boundary;
		$blen = length( $boundary );
		if( $meth ne 'POST' ) {
			&Carp::croak( "CGI Error: Invalid request method for multipart/form-data: $meth" );
		}
		if( $writef ) {
			stat( $writef );
			$writef = '/tmp/' unless  -d _ && -w _;
			$writef .= 'CGI-TMP';
		}
		$content = $input = '';
		$copen = 0;
		$bufsize = $len if $bufsize > $len;
		while( ( $got = read( STDIN, $buf, $bufsize ) ) > 0 ) {
			$len -= $got;
			$bufsize = $len if $bufsize > $len;
			$input .= $buf;
			while( ( $bi = index( $input, $boundary ) ) >= 0 ) {
				if( $bi > 0 ) {
					if( $hf ) {
						print $hf substr( $input, 0, $bi - 2 );
						close $hf;
						$fd->{'size'} .= ( $cl + $bi - 2 );
					}
					else {
						$Form{ $name } .= substr( $input, 0, $bi - 2 );
					}
				}
				$bi += $blen;
				$eoh = index( $input, "\015\012\015\012", $bi );
				last if $eoh < 0;
				$bi = $eoh + 4;
				$hl = length( $input );
				$head = substr( $input, $blen, $eoh - $blen + 2 );
				($cd) = $head =~ m!(Content-Disposition:[^\015]+)\015!;
				($ct) = $head =~ m!(Content-Type:[^\015]+)\015!;
				($name) = $cd =~ /\bname=\"([^\"]+)\"/i;
				unless( defined $name ) {
					($name) = $cd =~ /\bname=([^\s:;]+)/i;
				}
				($fname) = $cd =~ /\bfilename=\"([^\"]*)\"/i;
				unless( defined $fname ) {
					($fname) = $cd =~ /\bfilename=([^\s:;]+)/i;
				}
				if( $ct ) {
					($ctype) = $ct =~ /^\s*Content-type:\s*\"([^\"]+)\"/i;
					unless( defined $ctype ) {
						($ctype) = $ct =~ /^\s*Content-Type:\s*([^\s:;]+)/i;
					}
				}
				else {
					$ctype = '';
				}
				&_create_param( $name, '', 1 ) if defined $_POST{$name};
				if( defined $fname && $fname ne '' && $writef ) {
					$ser ++;
					$fn = $writef . '.' . $$ . '.' . $ser;
					open $hf, '>' . $fn or
						&Carp::croak( "Error while open $fn\: $!" );
					binmode $hf;
					$cl = 0;
					$_FILES{$name} ||= {};
					$fd = $_FILES{$name};
					$fd->{'name'} .= 
						defined $fd->{'name'} ? "\0" : ""
						. ( $fname || "" );
					$fd->{'type'} .=
						defined $fd->{'type'} ? "\0" : ""
						. ( $ctype || "" );
					$fd->{'size'} .=
						defined $fd->{'size'} ? "\0" : "";
					$fd->{'tmp_name'} .= defined $fd->{'tmp_name'} ? "\0" : $fn;
					&_add_param( $name, $fn, 1 ) if defined $fn;
				}
				else {
					$hf = undef;
#					$fd->{'tmp_name'} .= defined $fd->{'tmp_name'} ? "\0" : "";
				}
				if( $bi < $hl ) {
					if( ( $bin = index( $input, $boundary, $bi ) ) >= 0 ) {
						if( $hf ) {
							print $hf substr( $input, $bi, $bin - $bi - 2 );
							close $hf;
							$fd->{'size'} .= ( $cl + $bin - $bi - 2 );
						}
						else {
							&_add_param( $name, substr( $input, $bi, $bin - $bi - 2 ), 1 );
						}
						$bi = $bin;
					}
					else {
						if( $hf ) {
							print $hf substr( $input, $bi );
							$cl += ( $hl - $bi );
						}
						else {
							&_add_param( $name, substr( $input, $bi ), 1 );
						}
						$input = '';
						last;
					}
				}
				else {
					$content = '';
				}
				$input = substr( $input, $bi );
			}
			if( $len <= 0 ) {
				close $hf if $hf;
				if( $bi < 0 && substr( $input, 0, 2 ) ne '--' ) {
					&Carp::croak(
						'Reached end of input while seeking boundary of multipart.'
						. ' Format of CGI input is wrong.'
					);
				}
				last;
			}
			else {
				if( $hf ) {
					print $hf $input;
					$cl += length( $input );
				}
				else {
					&_add_param( $name, $input, 1 );
				}
				$input = '';
			}
		}
	}
#	else {
#		&Carp::croak( "Unknown content-type: $type" );
#	}	
	return 1;
}

__END__
