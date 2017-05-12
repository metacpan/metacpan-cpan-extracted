use strict;
use warnings;
# following package can be "used" only from nginx environment:
use nginx;
use XMLRPC::Transport::HTTP::Nginx;

our $request;
our $rpc;
our $initiated = 0;

sub handler {
	$request = shift;

	if(!$initiated) {
		# RPC initializing
		$rpc = XMLRPC::Transport::HTTP::Nginx
			->options( {compress_threshold => 10000} )
			->dispatch_to( 'main::test', 'main::echo' );

		$initiated = 1;
	}

	if( $request->request_method eq 'POST' ) {
		$request->has_request_body( \&ProcessRPCPOST );
		return HTTP_OK;
	}
	elsif ( $request->request_method eq 'GET' ) {
		ProcessRPCRequest( $request );
	}
	else {
		return DECLINED;
	}

    $rpc->handle($request);
	return HTTP_OK;
}

sub ProcessRPCRequest {
	my ($r,$body) = @_;
	$request = $r;
	$rpc->handle($r,$body);
	return OK;
}

sub ProcessPOSTparameters {
	my $r = shift;

	my $body = $r->request_body;
	unless ( $body ) {
		my $file = $r->request_body_file;

		if ( $file && -f $file ) {
			my ($fh, $block);
			open $fh, "<$file";
			binmode $fh;
			while ( read $fh, $block, 4096 ) { $body .= $block };
			close $fh;
		}
	}

	# check if files were posted.
	my $ContentType = $r->header_in('Content-type');
	if ( $ContentType =~ 'multipart/form-data' ) {
		my ($Boundary) = ($ContentType =~ /boundary="?([^\s]+)"?/);
		$body = "Content-Type: multipart/form-data;\n boundary=\"$Boundary\"\n\n".$body;
		my $Parser = new MIME::Parser;
		$Parser->output_to_core(1);
		$Parser->decode_bodies(0);
		$body = $Parser->parse_data($body);
	}

	(
	 request => $r,
	 body => $body,
	);
}

sub ProcessRPCPOST {
  my $r = shift;
  my %args = (
	      request => $r,
	      body => undef,
	      ProcessPOSTparameters($r,@_),
	     );


  ProcessRPCRequest( $args{request}, $args{body} );

  return OK;
}

sub test {return 'test passed'}
sub echo {return $_[1]}

12;
