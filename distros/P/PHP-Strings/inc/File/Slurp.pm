#line 1 "inc/File/Slurp.pm - /opt/perl/5.8.2/lib/site_perl/5.8.2/File/Slurp.pm"
package File::Slurp;

use strict;

use Carp ;
use Fcntl qw( :DEFAULT :seek ) ;
use Symbol ;

use base 'Exporter' ;
use vars qw( %EXPORT_TAGS @EXPORT_OK $VERSION  @EXPORT) ;

%EXPORT_TAGS = ( 'all' => [
	qw( read_file write_file overwrite_file append_file read_dir ) ] ) ;

#@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = ( @{ $EXPORT_TAGS{'all'} } );

$VERSION = '9999.01';


sub read_file {

	my( $file_name, %args ) = @_ ;

	my $buf ;
	my $buf_ref = $args{'buf_ref'} || \$buf ;

	${$buf_ref} = '' ;

	my( $read_fh, $size_left, $blk_size ) ;

	if ( defined( fileno( $file_name ) ) ) {

		$read_fh = $file_name ;
		$blk_size = $args{'blk_size'} || 1024 * 1024 ;
		$size_left = $blk_size ;
	}
	else {

		my $mode = O_RDONLY ;
		$mode |= O_BINARY if $args{'binmode'} ;


		$read_fh = gensym ;
		unless ( sysopen( $read_fh, $file_name, $mode ) ) {
			@_ = ( \%args, "read_file '$file_name' - sysopen: $!");
			goto &error ;
		}

		$size_left = -s $read_fh ;
	}

	while( 1 ) {

		my $read_cnt = sysread( $read_fh, ${$buf_ref},
				$size_left, length ${$buf_ref} ) ;

		if ( defined $read_cnt ) {

			last if $read_cnt == 0 ;
			next if $blk_size ;

			$size_left -= $read_cnt ;
			last if $size_left <= 0 ;
			next ;
		}

# handle the read error

		@_ = ( \%args, "read_file '$file_name' - sysread: $!");
		goto &error ;
	}

# handle array ref

	return [ split( m|(?<=$/)|, ${$buf_ref} ) ] if $args{'array_ref'}  ;

# handle list context

	return split( m|(?<=$/)|, ${$buf_ref} ) if wantarray ;

# handle scalar ref

	return $buf_ref if $args{'scalar_ref'} ;

# handle scalar context

	return ${$buf_ref} if defined wantarray ;

# handle void context (return scalar by buffer reference)

	return ;
}

sub write_file {

	my $file_name = shift ;

	my $args = ( ref $_[0] eq 'HASH' ) ? shift : {} ;

	my( $buf_ref, $write_fh, $no_truncate ) ;

# get the buffer ref - either passed by name or first data arg or autovivified
# ${$buf_ref} will have the data after this

	if ( ref $args->{'buf_ref'} eq 'SCALAR' ) {

		$buf_ref = $args->{'buf_ref'} ;
	}
	elsif ( ref $_[0] eq 'SCALAR' ) {

		$buf_ref = shift ;
	}
	elsif ( ref $_[0] eq 'ARRAY' ) {

		${$buf_ref} = join '', @{$_[0]} ;
	}
	else {

		${$buf_ref} = join '', @_ ;
	}

	if ( defined( fileno( $file_name ) ) ) {

		$write_fh = $file_name ;
		$no_truncate = 1 ;
	}
	else {

		my $mode = O_WRONLY | O_CREAT ;
		$mode |= O_BINARY if $args->{'binmode'} ;
		$mode |= O_APPEND if $args->{'append'} ;

		$write_fh = gensym ;
		unless ( sysopen( $write_fh, $file_name, $mode ) ) {
			@_ = ( $args, "write_file '$file_name' - sysopen: $!");
			goto &error ;
		}

	}

	my $size_left = length( ${$buf_ref} ) ;
	my $offset = 0 ;

	do {
		my $write_cnt = syswrite( $write_fh, ${$buf_ref},
				$size_left, $offset ) ;

		unless ( defined $write_cnt ) {

			@_ = ( $args, "write_file '$file_name' - syswrite: $!");
			goto &error ;
		}

		$size_left -= $write_cnt ;
		$offset += $write_cnt ;

	} while( $size_left > 0 ) ;

	truncate( $write_fh,
		  sysseek( $write_fh, 0, SEEK_CUR ) ) unless $no_truncate ;

	close( $write_fh ) ;

	return 1 ;
}

# this is for backwards compatibility with the previous File::Slurp module. 
# write_file always overwrites an existing file

*overwrite_file = \&write_file ;

# the current write_file has an append mode so we use that. this
# supports the same API with an optional second argument which is a
# hash ref of options.

sub append_file {

	my $args = $_[1] ;
	if ( ref $args eq 'HASH' ) {
		$args->{append} = 1 ;
	}
	else {

		splice( @_, 1, 0, { append => 1 } ) ;
	}
	
	goto &write_file
}

sub read_dir {
	my ($dir, %args ) = @_;

	local(*DIRH);

	if ( opendir( DIRH, $dir ) ) {
		return grep( $_ ne "." && $_ ne "..", readdir(DIRH));
	}

	@_ = ( \%args, "read_dir '$dir' - opendir: $!" ) ; goto &error ;

	return undef ;
}

my %err_func = (
	carp => \&carp,
	croak => \&croak,
) ;

sub error {

	my( $args, $err_msg ) = @_ ;

#print $err_msg ;

 	my $func = $err_func{ $args->{'err_mode'} || 'croak' } ;

	return unless $func ;

	$func->($err_msg) ;

	return undef ;
}

1;
__END__

#line 461
