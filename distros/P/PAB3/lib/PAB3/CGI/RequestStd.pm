package PAB3::CGI;
# =============================================================================
# Perl Application Builder
# Module: PAB3::CGI::RequestStd
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

sub _parse_request {
	my( $len, $meth, $got, $input, $post, $jmp );
	
	%_GET = ();
	%_POST = ();
	%_REQUEST = ();
	%_FILES = ();
	
	binmode( STDIN ); 
	binmode( STDOUT );
	binmode( STDERR );

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
		if( $meth eq 'POST' ) {
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
	return 1;
}

__END__
