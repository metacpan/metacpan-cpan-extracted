package PAB3::Output::CGI;
# =============================================================================
# Perl Application Builder
# Module: PAB3::Output::CGI
# TIEHANDLE for CGI output
# =============================================================================
use strict;
no strict 'refs';
use warnings;
no warnings 'untie', 'uninitialized';

use vars qw($VERSION);

BEGIN {
	if( ! $PAB3::CGI::VERSION ) {
		die '>> Please do not use PAB3::Output::CGI directly, use PAB3::CGI instead <<';
	}
	$VERSION = $PAB3::CGI::VERSION;
}

1;

sub TIEHANDLE {
    my $class = shift;
    bless [ @_ ], $class;
}

sub HEADER_MODPERL {
	my( $key, $val ) = @_;
	if( $key eq 'content-type' ) {
		$GLOBAL::MPREQ->content_type( $val );
		return 0;
	}
	elsif( $key eq 'content-length' ) {
		goto hm_plain if $GLOBAL::MODPERL == 1;
		$GLOBAL::MPREQ->set_content_length( $val );
	}
	elsif( $key eq 'status' ) {
		if( $val =~ m!\s*(\d+)\s+(.+)! ) {
			$GLOBAL::MPREQ->status( $1 );
			$GLOBAL::MPREQ->status_line( $1 . ' ' . $2 );
			return $1 >= 300 ? 0 : 1;
		}
		else {
			$GLOBAL::MPREQ->status( $val );
			return int( $val ) >= 300 ? 0 : 1;
		}
	}
	elsif( $key eq 'intredir' ) {
		$GLOBAL::MPREQ->internal_redirect( $val );
		return 0;
	}
	elsif( $key eq 'location' ) {
		$GLOBAL::MPREQ->status( 302 );
		$GLOBAL::MPREQ->headers_out->set( 'location', $val );
		$GLOBAL::MPREQ->print( "" );
		return 0;
	}
	else {
hm_plain:
		$GLOBAL::MPREQ->headers_out->set( $key, $val );
	}
	return 1;
}

sub SENDHEADER {
	my( $needct, $key, $val, $ret );
	untie *STDOUT;
	binmode STDOUT;
	if( $GLOBAL::MODPERL == 2 ) {
		if( $GLOBAL::MPREQ->handler() eq 'modperl' ) {
			tie *STDOUT, $GLOBAL::MPREQ;
		}
	}
	elsif( $GLOBAL::MODPERL == 1 ) {
		tie *STDOUT, $GLOBAL::MPREQ;
	}
	$needct = 1;
	if( $GLOBAL::MODPERL ) {
		foreach $key( keys %PAB3::CGI::HEAD ) {
			$needct = 0 if $needct && ($key eq 'content-type' || $key eq 'location');
			if( ref( $PAB3::CGI::HEAD{$key} ) ) {
				foreach $val( @{$PAB3::CGI::HEAD{$key}} ) {
					$ret = &HEADER_MODPERL( $key, $val );
					$needct = $ret if $needct;
				}
			}
			else {
				$ret = &HEADER_MODPERL( $key, $PAB3::CGI::HEAD{$key} );
				$needct = $ret if $needct;
			}
		}
	}
	else {
		if( ( $val = $PAB3::CGI::HEAD{'status'} ) ) {
			print "Status: $val\015\012";
			$val = $val->[-1] if ref( $val );
			if( $val =~ m!\s*(\d+)\s+! ) {
				$needct = 0 if $needct && $1 >= 300;
			}
			else {
				$needct = 0 if $needct && int( $val ) >= 300;
			}
			delete $PAB3::CGI::HEAD{'status'};
		}
		foreach $key( keys %PAB3::CGI::HEAD ) {
			$needct = 0 if $needct && ($key eq 'content-type' || $key eq 'location');
			if( ref( $PAB3::CGI::HEAD{$key} ) ) {
				foreach( @{$PAB3::CGI::HEAD{$key}} ) {
		    		print $key . ': ' . $_ . "\015\012";
				}
			}
			else {
	    		print $key . ': ' . $PAB3::CGI::HEAD{$key} . "\015\012";
			}
		}
	}
	if( $needct ) {
		$val =
			'text/html; charset: '
			. ( $ENV{'CHARSET'} || 'iso-8859-1' )
		;
		if( $GLOBAL::MODPERL ) {
			$GLOBAL::MPREQ->content_type( $val );
		}
		else {
			print 'content-type: ', $val, "\015\012";
		}
	}
	if( ! $GLOBAL::MODPERL ) {
		print "\015\012\015\012";
	}
	$PAB3::CGI::HeaderDone = [ caller(2) ];
}

sub PRINT {
    my $self = shift;
	&SENDHEADER();
	print @_;
}

sub PRINTF {
    my $self  = shift;
	&SENDHEADER();
	printf @_;
}

sub BINMODE {
}

sub CLOSE {
}

sub FILENO {
}

sub GETC {
}

sub OPEN {
}

sub READ {
}


sub WRITE {
	my $self = shift;
	&SENDHEADER();
	write @_;
}

__END__
