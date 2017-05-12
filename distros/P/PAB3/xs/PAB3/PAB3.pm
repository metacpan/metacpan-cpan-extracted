package PAB3;
# =============================================================================
# Perl Application Builder
# Module: PAB3
# Use "perldoc PAB3" for documentation 
# =============================================================================
use Carp ();
use Symbol ();

use strict;
no strict 'refs';
use warnings;
no warnings 'uninitialized';

use vars qw($VERSION %SC $_CURRENT);

use constant {
	SCALAR			=> 1,
	ARRAY			=> 2,
	HASH			=> 3,
	FUNC			=> 4,
};

BEGIN {
	$VERSION = '3.201';
	require XSLoader;
	XSLoader::load( __PACKAGE__, $VERSION );
	if( ! $PAB3::CGI::VERSION ) {
		$SIG{'__DIE__'} = \&_die_handler;
		$SIG{'__WARN__'} = \&_warn_handler;
	}
	*print_r = \&print_var;
}

END {
	&_cleanup();
}

1;

sub import {
	my $pkg = shift;
	my $callpkg = caller();
	if( $_[0] and $pkg eq __PACKAGE__ and $_[0] eq 'import' ) {
		*{$callpkg . '::import'} = \&import;
		return;
	}
	foreach( @_ ) {
		if( $_ eq ':const' || $_ eq ':default' ) {
			*{$callpkg . '::PAB_SCALAR'} = \&{$pkg . '::SCALAR'};
			*{$callpkg . '::PAB_ARRAY'} = \&{$pkg . '::ARRAY'};
			*{$callpkg . '::PAB_HASH'} = \&{$pkg . '::HASH'};
			*{$callpkg . '::PAB_FUNC'} = \&{$pkg . '::FUNC'};
		}
		if( $_ eq ':default' ) {
			*{$callpkg . '::print_var'} = \&{$pkg . '::print_var'};
			*{$callpkg . '::print_r'} = \&{$pkg . '::print_var'};
			*{$callpkg . '::require'} = \&{$pkg . '::require'};
			*{$callpkg . '::require_and_run'} = \&{$pkg . '::require_and_run'};
		}
	}
}

sub setenv {
	if( $0 =~ /^(.+\/)(.+?)$/ ) {
		$ENV{'SCRIPT_PATH'} = $1;
		$ENV{'SCRIPT'} = $2;
	}
	else {
		$ENV{'SCRIPT_PATH'} = '';
		$ENV{'SCRIPT'} = $0;
	}
}

sub new {
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $this = &_new( $class, @_ ) or return undef;
	my %arg = @_;
	$this->{'die'} = defined $arg{'die'} ? $arg{'die'} : 1;
	$this->{'warn'} = defined $arg{'warn'} ? $arg{'warn'} : 1;
	$this->{'path_template'} = $arg{'path_template'};
	$this->{'path_cache'} = $arg{'path_cache'};
	$this->{'auto_cache'} = $arg{'auto_cache'};
	$this->{'hashmap_cache'} = $arg{'hashmap_cache'};
	$this->{'logger'} = $arg{'logger'};
	return $this;
}

sub handle_error {
	my( $this ) = @_;
	if( $this ) {
		&Carp::croak( &error( $this ) ) if $this->{'die'};
		&Carp::carp( &error( $this ) ) if $this->{'warn'};
	}
	return 0;
}

sub parse_template {
	&_parse_template( @_ ) or return handle_error( @_ );
}

sub make_script_and_run {
	my( $this, $template, $cache, $package ) = @_;
	my( @ts, @cs, $rv, $ct, $cac, $tpl, $fh );
	$_CURRENT = $this;
	$package ||= ( CORE::caller )[0];
	$tpl = $this->{'path_template'} . $template;
	if( ! $cache && $this->{'auto_cache'} ) {
		$cache = '_auto.' . $template . '.pl';
		$cache =~ tr!/!.!;
		$cache =~ tr!\\!.!;
	}
	if( $cache ) {
		$cac = $this->{'path_cache'} . $cache;
		if( -f $tpl ) {
			@ts = stat( $tpl );
			if( -f $cac ) {
				@cs = stat( $cac );
				if( $ts[9] == $cs[9] ) {
					&require_and_run( $this, $cac, $package );
					return 1;
				}
			}
		}
	}
	if( $this->{'logger'} ) {
		$this->{'logger'}->debug( "Parse template \"$tpl\"" );
	}
	( $rv, $ct ) = &_make_script( $this, $template, $cache );
	if( $rv == 3 ) {
		if( $this->{'logger'} ) {
			$this->{'logger'}->debug( "Save script at \"$cac\"" );
		}
		open( $fh, '> ' . $cac )
			or do {
				$this->set_error( "Unable to open file '$cac': $!" );
				return $this->handle_error();
			};
		flock( $fh, 2 );
		syswrite( $fh, $ct );
		flock( $fh, 8 );
		close( $fh );
		utime( $ts[9], $ts[9], $cac );
		&require_and_run( $this, $cac, $package );
	}
	elsif( $rv == 1 ) {
		utime $ts[9], $ts[9], $cac;
		&require_and_run( $this, $cac, $package );
	}
	elsif( $rv == 2 ) {
		if( $this->{'logger'} ) {
			$this->{'logger'}->debug( "Compile and run \"$tpl\"" );
		}
		$tpl =~ s/\W/_/go;
		&PAB3::_create_script_cache( \$ct, $tpl, $package );
		my $of = $0;
		*0 = \$template;
		&{"PAB3::SC::${tpl}::handler"}();
		*0 = \$of;
	}
	elsif( ! $rv ) {
		return &handle_error( $this );
	}
	return 1;
}

sub add_hashmap {
	my( $this, $loopid, $record, $fieldmap, $tfm ) = @_;
	my( $fm, $fmc, $hmc );
	if( ref( $fieldmap ) eq 'ARRAY' ) {
		my $ifm = 0;
		$fm = {};
		foreach( @$fieldmap ) {
			$fm->{$_} = $ifm ++;
		}
	}
	elsif( ref( $fieldmap ) eq 'HASH' ) {
		$fm = $fieldmap;
	}
	else {
		&set_error( $this, 'Parameter fieldmap is invalid' );
		return &handle_error( $this );
	}
	if( ( $hmc = $this->{'hashmap_cache'} ) ) {
		$fmc = $hmc->get( $loopid, $record, $fm );
	}
	if( ! %$fm ) {
		if( ! $fmc ) {
			&set_error( $this, 'Hashmap is empty' );
			return &handle_error( $this );
		}
		$fm = $fmc;
	}
	&_add_hashmap( $this, $loopid, $record, $fieldmap )
		or return &handle_error( $this );
	if( $hmc && ! $fmc ) {
		$hmc->set( $loopid, $record, $fm );
	}
	$_[4] = $fm;
	return 1;
}

sub require {
	my $this = shift if ref( $_[0] ) eq __PACKAGE__;
	my( $file, $package, $inject_code, $args ) = @_;
	my( $fid, $cache, $content, $fh, @fs, $logger );
	$package ||= ( caller )[0];
	$fid = $file . '_' . $package;
	$fid =~ s/\W/_/go;
	if( $package eq $fid ) {
		&Carp::croak( 'Script requires itself' );
	}
	@fs = stat( $file );
	$cache = $SC{$fid};
	$logger = $this->{'logger'} if $this && $this->{'logger'};
	if( ! $cache || $cache != $fs[9] ) {
		if( $cache ) {
			if( $logger ) {
				$logger->debug( "Unloading PAB3::SC::${fid}" );
			}
			&Symbol::delete_package( "PAB3::SC::${fid}" );
		}
		if( $logger ) {
			$logger->debug( "Compile \"$file\"" );
		}
		open( $fh, $file ) or &Carp::croak( "Unable to open '$file': $!" );
		flock( $fh, 1 );
		read( $fh, $content, $fs[7] );
		flock( $fh, 8 );
		close( $fh );
		&_create_script_cache( \$content, $fid, $package, $file, $inject_code );
		$SC{$fid} = $fs[9];
		if( $logger ) {
			$logger->debug( "Run PAB3::SC::${fid}::handler" );
		}
		my $of = $0;
		*0 = \$file;
		&{"PAB3::SC::${fid}::handler"}( ref( $args ) eq 'ARRAY' ? @$args : $args );
		*0 = \$of;
		return 1;
	}
	return 1;
}

sub require_and_run {
	my $this = shift if ref( $_[0] ) eq __PACKAGE__;
	my( $file, $package, $inject_code, $args ) = @_;
	my( $fid, $cache, $content, $fh, @fs, $of, $logger );
	$package ||= ( caller )[0];
	$fid = $file . '_' . $package;
	$fid =~ s/\W/_/go;
	if( $package eq $fid ) {
		&Carp::croak( 'Script requires itself' );
	}
	@fs = stat( $file );
	$cache = $SC{$fid};
	$logger = $this->{'logger'} if $this && $this->{'logger'};
	if( ! $cache || $cache != $fs[9] ) {
		if( $cache ) {
			if( $logger ) {
				$logger->debug( "Unloading PAB3::SC::${fid}" );
			}
			&Symbol::delete_package( "PAB3::SC::${fid}" );
		}
		if( $logger ) {
			$logger->debug( "Compile \"$file\"" );
		}
		open( $fh, $file ) or &Carp::croak( "Unable to open '$file': $!" );
		flock( $fh, 1 );
		read( $fh, $content, $fs[7] );
		flock( $fh, 8 );
		close( $fh );
		&_create_script_cache( \$content, $fid, $package, $file, $inject_code );
		$SC{$fid} = $fs[9];
	}
	if( $logger ) {
		$logger->debug( "Run PAB3::SC::${fid}::handler" );
	}
	$of = $0;
	*0 = \$file;
	&{"PAB3::SC::${fid}::handler"}( ref( $args ) eq 'ARRAY' ? @$args : $args );
	*0 = \$of;
	return 1;
}

sub _create_script_cache {
	my( $content, $pkg_require, $pkg_caller, $filename, $inject_code ) = @_;
	my( $hr, $data, $end );
	if( ref( $content ) ) {
		$content = $$content;
	}
	$content =~ s!\r!!gso;
	if( $content =~ s/(\n__DATA__\n.*$)//s ) {
		$data = $1;
	}
	else {
		$data = '';
	}
	if( $content =~ s/(\n__END__\n.*$)//s ) {
		$end = $1;
	}
	else {
		$end = '';
	}
	$filename ||= $0;
	$inject_code ||= '';
	$content = <<EORAR01;
package PAB3::SC::$pkg_require;
our \$VERSION = 1;
*handler = sub {
package $pkg_caller;
$inject_code
#line 1 $filename
$content
};
1;
$data
$end
EORAR01
	if( $GLOBAL::DEBUG ) {
		$PAB3::CGI::VERSION
			? &PAB3::CGI::print_code( $content, $filename )
			: &PAB3::print_code( $content, $filename )
		;
	}	
    {
        no strict;
        no warnings FATAL => 'all';
        local( $SIG{'__DIE__'}, $SIG{'__WARN__'} );
        eval $content;
    }
	if( $@ ) {
		if( ! $GLOBAL::DEBUG ) {
			$PAB3::CGI::VERSION
				? &PAB3::CGI::print_code( $content, $filename )
				: &PAB3::print_code( $content, $filename )
			;
		}
		&Carp::croak( $@ );
	};
}

sub print_code {
	my( $t, $l, $p );
	foreach $t( @_ ) {
		$t =~ s!\r!!gso;
		if( defined $t ) {
			print "\n";
			$p = 1;
			foreach $l( split( /\n/, $t ) ) {
				print $p . "\t" . $l . "\n";
				$p ++;
			}
			print "\n";
		}
	}
}

sub print_hash {
	my( $hashname, $ref_table, $level ) = @_;
	my( $r_hash, $r, $k );
	$ref_table ||= [];
	if( $hashname =~ /HASH\(0x\w+\)/ ) {
		$r_hash = $hashname;
	}
	else {
		return;
	}
	print $r_hash;
	if( $ref_table->{$r_hash} && $ref_table->{$r_hash} <= $level ) {
		print " [recursive loop]\n";
		return;
	}
	print "\n", "    " x $level, "(\n";
	$ref_table->{$r_hash} = $level + 1;
	foreach $k( sort { lc( $a ) cmp lc( $b ) } keys %{ $r_hash } ) {
		print "    " x ( $level + 1 ) . "[$k] => ";
		$r = ref( $r_hash->{$k} );
		if( $r && index( $r_hash->{$k}, 'ARRAY(' ) >= 0 ) {
			&print_array( $r_hash->{$k}, $ref_table, $level + 1 );
		}
		elsif( $r && index( $r_hash->{$k}, 'HASH(' ) >= 0 ) {
			&print_hash( $r_hash->{$k}, $ref_table, $level + 1 );
		}
		else {
			print ( ! defined $r_hash->{$k} ? '(null)' : $r_hash->{ $k } );
			print "\n";
		}
	}
	print "    " x $level, ")\n";
}

sub print_array {
	my( $arrayname, $ref_table, $level ) = @_;
	my( $r_array, $r, $v, $i );
	$ref_table ||= {};
	$level ||= 0;
	if( $arrayname =~ /ARRAY\(0x\w+\)/ ) {
		$r_array = $arrayname;
	}
	else {
		return;
	}
	print $r_array;
	if( $ref_table->{$r_array} && $ref_table->{$r_array} <= $level ) {
		print " [recursive loop]\n";
		return;
	}
	print "\n", "    " x $level, "(\n";
	$ref_table->{$r_array} = $level + 1;
	$i = 0;
	foreach $v( @{ $r_array } ) {
		$r = ref( $v );
		print "    " x ( $level + 1 ) . "[$i] => ";
		if( $r && index( $v, 'ARRAY(' ) >= 0 ) {
			&print_array( $v, $ref_table, $level + 1 );
		}
		elsif( $r && index( $v, 'HASH(' ) >= 0 ) {
			&print_hash( $v, $ref_table, $level + 1 );
		}
		else {
			print "" . ( ! defined $v ? '(null)' : $v ) . "\n";
		}
		$i ++;
	}
	print "    " x $level, ")\n";
}

sub print_var {
	my( $v, $r, $ref_table );
	$ref_table = {};
	foreach $v( @_ ) {
		$r = ref( $v );
		if( $r && index( $v, 'ARRAY(' ) >= 0 ) {
			&print_array( $v, $ref_table, 0 );
		}
		elsif( $r && index( $v, 'HASH(' ) >= 0 ) {
			&print_hash( $v, $ref_table, 0 );
		}
		elsif( $r && index( $v, 'SCALAR(' ) >= 0 ) {
			print defined $$v ? $$v : '(null)', "\n";
		}
		else {
			print defined $v ? $v : '(null)', "\n";
		}
	}
}

sub _die_handler {
	my $str = shift;
	my( @c, $step );
	print "\nFatal: $str\n\n";
	@c = caller();
	print $c[0] . ' raised the exception at ' . $c[1] . ' line ' . $c[2] . "\n";
	$step = 1;
	while( @c = caller( $step ) ) {
		print $c[0] . ' called ' . $c[3] . ' at ' . $c[1] . ' line ' . $c[2] . "\n";
		$step ++;
	}
	print "\n";
	exit( 0 );
}

sub _warn_handler {
	my $str = shift;
	print "\nWarning: $str\n";
}

__END__

=head1 NAME

PAB3 - Perl Application Builder / Version 3

=head1 SYNOPSIS

  use PAB3;

=head1 DESCRIPTION

C<PAB3> provides a framework for building rapid applications with Perl.
It includes a template handler for producing output. This part
is defined here.

=head2 Examples

Following example loads a template from B<template1.tpx>, does a loop
over the %ENV variable and prints the output to STDOUT.

- perl script -

  #!/usr/bin/perl -w
  
  use PAB3;
  
  my $pab = PAB3->new();
  
  $pab->make_script_and_run( 'template1.tpx' );

- B<template1.tpx> -

  main script:
  
  <*= $0 *>
  
  show the environment:
  
  <* LOOP HASH %ENV *>
  <* PRINT "[$_] => " . $ENV{$_} . "\n" *>
  <* END LOOP *>
  
  # or - with loop directive
  
  <* loop foreach( keys %ENV ) *>
  <* = "[$_] => " . $ENV{$_} . "\n" *>
  <* end loop *>
  
  # or - perl like
  
  <* foreach( keys %ENV ) { *>
  <* print "[$_] => " . $ENV{$_} . "\n" *>
  <* } *>
  
  # or - with internal function
  
  <* &PAB3::print_r( \%ENV ) *>


=head1 METHODS

=over

=item setenv ()

Set some useful variables to the interpreters environment 

these variables are:

  $ENV{'SCRIPT_PATH'}   : path to the main script
  $ENV{'SCRIPT'}        : name of the main script


=item new ( [%arg] )

Create a new instance of the PAB3 (template handler) class.

Posible arguments are:

  path_cache     => path to save parsed templates
  path_template  => path to the template files
  auto_cache     => create cache files automatically. 'path_cache' is required
  prg_start      => begin of program sequence, default is '<*'
  prg_end        => end of program sequence, default is '*>'
  cmd_sep        => command separator, to define more directives in one program
                    sequence, default is ';;'
  record_name    => name of default record in loops, default is '$_'
  logger         => reference to a PAB3::Logger class
  warn           => warn on error, default is OFF
  die            => die on error, default is ON
  class_name     => name of the variable for this class. eg '$pab'
                    It is needed when templates including templates. If its
                    undefined, a variable $PAB3::_CURRENT will
                    be used as a reference to the current PAB3 class.

Example:

  $pab = PAB3->new(
      'path_cache'    => '/path/to/cache',
      'path_template' => '/path/to/template-files',
  );


=item parse_template ( $template )

Parse the template given at I<$template> and return Perl code.
If I<$template> points to an existing file, the content of the file will be
parsed. In the other case the content of the variable will be used as template.

Example:

  $code = $pab->parse_template( '<*= $0 *>' );
  eval( $code );


=item make_script_and_run ( $template )

=item make_script_and_run ( $template, $cache )

=item make_script_and_run ( $template, $cache, $package )

Parse the template given at I<$template>, generate Perl code and execute it.
If I<$cache> is set to a filename or "auto_cache" is enabled, the Perl code
will be saved into a file. If the cache file already exists and the template has
not been changed, the template will not be parsed again.
Third parameter I<$package> defines the package where the Perl code should
be executed. If I<$package> has not been specified the package from
C<caller(0)> is used.

Returns TRUE on success or FALSE on error.

Example:

  # parse the template and execute it
  $pab->make_script_and_run( 'template.htm' );
  
  # parse the template, cache it into file and execute it
  $pab->make_script_and_run( 'template.htm', 'template.pl' );


=item register_loop ( $id, $source, $s_type )

=item register_loop ( $id, $source, $s_type, $record, $r_type )

=item register_loop ( $id, $source, $s_type, $record, $r_type, $object )

=item register_loop ( $id, $source, $s_type, $record, $r_type, $object, $arg )

=item register_loop ( $id, $source, $s_type, $record, $r_type, $object, $arg, $fixed )

Registers a loop to be used inside templates.

Loops need not registered here. It also can be declared in the
template.

B<Arguments>

I<$id>

Loop identifier

I<$source>

the source of the loop.

I<$s_type>

the type of the source. One of these constants: PAB_ARRAY, PAB_HASH
or PAB_FUNC

I<$record>

the record in the loop.

I<$r_type>

the type of the record. One of these constants: PAB_SCALAR, PAB_FUNC, PAB_ARRAY
or PAB_HASH

I<$object>

a object for $source or $record functions.

I<$arg>

arguments passed to the source if it is a function, as an array reference

I<$fixed>

installes the loop as fixed. it can not be overwritten

B<Combinations>

Following combinations are possible:

   --------------------------------------
  |   Source   |   Record   |   Object   |
   --------------------------------------
  | PAB_ARRAY  | PAB_SCALAR |     -      |
  | PAB_ARRAY  | PAB_FUNC   |    yes     |
  | PAB_HASH   | PAB_SCALAR |     -      |
  | PAB_HASH   | PAB_FUNC   |    yes     |
  | PAB_FUNC   | PAB_SCALAR |    yes     |
  | PAB_FUNC   | PAB_ARRAY  |    yes     |
  | PAB_FUNC   | PAB_HASH   |    yes     |
   --------------------------------------

The constants can be accessed in three ways, by the object like $pab->SCALAR,
by the module like PAB3::SCALAR and by export like PAB_SCALAR. See more at
L<EXPORTS|PAB3/exports> 

I<Source as Array, Record as Scalar>

  # definition
  register_loop( 'id', 'source' => PAB_ARRAY, 'record' => PAB_SCALAR )
  
  # result
  foreach $record( @source ) {
  }

I<Source as Array, Record as Function>

  # definition
  register_loop( 'id', 'source' => PAB_ARRAY, 'record' => PAB_FUNC )
  
  # result
  foreach $<iv>( @source ) {
       &record( $<iv> [, <arg>] );
  }

I<Source as Array, Record as Function, Object>

  # definition
  register_loop( 'id', 'source' => PAB_ARRAY, 'record' => PAB_FUNC, 'object' )
  
  # result
  foreach $<iv>( @source ) {
       $object->record( $<iv> [, <arg>] );
  }

I<Source as Hash, Record as Scalar>

  # definition
  register_loop( 'id', 'source' => PAB_HASH, 'record' => PAB_SCALAR )
  
  # result
  foreach $record( keys %source ) {
  }

I<Source as Hash, Record as Function>

  # definition
  register_loop( 'id', 'source' => PAB_HASH, 'record' => PAB_FUNC )
  
  # result
  foreach $<iv>( keys %source ) {
      &record( $<iv> [, <arg>] );
  }

I<Source as Hash, Record as Function, Object>

  # definition
  register_loop( 'id', 'source' => PAB_HASH, 'record' => PAB_FUNC, 'object' )
  
  # result
  foreach $<iv>( keys %source ) {
      $object->record( $<iv> [, <arg>] );
  }

I<Source as Function, Record as Scalar>

  # definition
  register_loop( 'id', 'source' => PAB_FUNC, 'record' => PAB_SCALAR )
  
  # result
  while( $record = &source( [<arg>] ) ) {
  }

I<Source as Function, Record as Scalar, Object>

  # definition
  register_loop( 'id', 'source' => PAB_FUNC, 'record' => PAB_SCALAR, 'object' )
  
  # result
  while( $record = $object->source( [<arg>] ) ) {
  }

I<Source as Function, Record as Array>

  # definition
  register_loop( 'id', 'source' => PAB_FUNC, 'record' => PAB_ARRAY )
  
  # result
  while( @record = &source( [<arg>] ) ) {
  }

I<Source as Function, Record as Hash>

  # definition
  register_loop( 'id', 'source' => PAB_FUNC, 'record' => PAB_HASH )
  
  # result
  while( %record = &source( [<arg>] ) ) {
  }

I<Source as Function, Record as Function>

  # definition
  register_loop( 'id', 'source' => PAB_FUNC, 'record' => PAB_FUNC )
  
  # result
  while( $<iv> = &source( [<arg>] ) ) {
      &record( $<iv> [, <arg>] );
  }

I<Source as Function, Record as Function, Object>

  # definition
  register_loop( 'id', 'source' => PAB_FUNC, 'record' => PAB_FUNC, 'object' )
  
  # result
  while( $<iv> = $object->source( [<arg>] ) ) {
      $object->record( $<iv> [, <arg>] );
  }

B<Examples>

Example of a loop over an array with record as subroutine:

  use PAB3 qw(:const);
  
  my @Array1 = ( 1, 2, 3 );
  
  $pab->register_loop(
      'MYLOOP', 'Array1' => PAB_ARRAY , 'init_record' => PAB_FUNC
  );
  
  sub init_record {
      $Record = shift;
      ...
  }

Example of an enumeration loop:

  $pab->register_loop(
      'MYLOOP', 'enum' => PAB_FUNC, 'Record' => PAB_SCALAR
  );
  
  $Counter = 10;
  
  sub enum {
       if( $Counter == 0 ) {
           $Counter = 10;
           return 0;
       }
       return $Counter --;
  }

--- inside the template ---

  <* LOOP MYLOOP *>
  <* PRINT $Record . "\n" *>
  <* END LOOP *>
  

B<See also>

L<directive LOOP|PAB3/LOOP>.


=item add_hashmap ( $loop_id, $hashname, $fieldmap )

=item add_hashmap ( $loop_id, $hashname, $fieldmap, $fm_save )

Add a hashmap to the parser.
Hashmaps are designed to translate hashes in templates into arrays in the
parsed script. For example: you use $var->{'Key'} in your template. With a
hashmap you can convert it into an array like $var->[0] without taking care of
the indices.
This can noticable make the execution time faster.

B<Parameters>

I<$loop_id>

If it is defined only the program sequences inside the loop will be converted,
otherwise the complete template is used.

I<$hashname>

Specifies the name of the hash to be translated.

I<$fieldmap>

Can be a reference to an array of fieldnames or a
reference to a hash containing fieldnames as keys and the assiocated indices
as values.

I<$fm_save>

If $fieldmap is an arrayref, the new generated hashmap can be saved in this
parameter.

B<Return Values>

Returns TRUE on success or FALSE if it fails.

B<Example>

  @data = (
      [ 'Smith', 'John', 33 ],
      [ 'Thomson', 'Peggy', 45 ],
      [ 'Johanson', 'Gustav', 27 ],
  );
  @fields = ( 'Name', 'Prename', 'Age' );
  
  # map all $per items in loop "Person" from hash to array
  $pab->add_hashmap( 'Person', 'per', \@fields );
  
  $pab->make_script_and_run( 'template' );

--- template ---

  <* LOOP Person foreach $per(@data) *>
  <* = $per->{'Prename'} . ' ' . $per->{'Name'} *> is <* = $per->{'Age'} *> years old
  <* END LOOP *>

B<Warning>

If an empty result from a db query is returned, no hashmap can be created.
If your template needs to be compiled and uses hashmaps, which are empty,
you will get an error.
You should recompile affected templates once by running them with
valid hashmaps. Or you can use a hashmap cache handler.
See more at L<PAB3::HashmapCache>.


=item reset ()

Clears loop definitions and hashmaps in the PAB3 class.


=item require ( $filename )

Loads the required file and compiles it into a package and runs it once it has
been changed.

Example:

  &PAB3::require( 'config.inc.pl' );
  
  - or -
  
  $pab->require( 'foo.pl' );


=item require_and_run ( $filename )

Loads the required file and compiles it into a package once it has been changed.
Runs it on every call.

Example:

  &PAB3::require_and_run( 'dosomething.pl' );
  
  - or -
  
  $pab->require_and_run( 'foo.pl' );


=item print_var ( ... )

=item print_r ( ... )

Prints human-readable information about one or more variables 

Example:

  &PAB3::print_r( \%ENV );


=back

=head1 PAB3 TEMPLATE LANGUAGE SYNTAX

The little extended language is needed to extract the PAB3 and Perl elements
from the rest of the template.
By default program sequences are included in B<E<lt>* ... *E<gt>>
and directives are separated by B<;;> .
These parameters can be overwritten by L<new()|PAB3/new>.

=head3 Examples

  <p><* PRINT localtime *></p>
  
  <*
      my $pos = int( rand( 3 ) );
      my @text =
          (
              'I wish you a nice day.',
              'Was happy to see you.',
              'Would be nice to see you back.'
          )
  *>
  
  <* if $pos == 0 *>
  <p>I wish you a nice day.</p>
  <* elsif $pos == 1 *>
  <p>Was happy to see you.</p>
  <* else *>
  <p>Would be nice to see you back.</p>
  <* end if *>
  
  <!-- or shortly -->
  
  <p><* = $text[$pos] *></p>


=head2 Directives

The following list explains the directives available within the PAB3 template
system. B<All directives are case insensitive>. The description is using
the default program and command separators.

=over

=item PRINT   E<lt>expressionE<gt>

=item =   E<lt>expressionE<gt>

Prints the output returned from E<lt>expressionE<gt>.

  <* PRINT <expression> *>

or shortly

  <* = <expression>     *>

Example:

  <* print $0, "\n" *>
  <* PRINT 'Now: ' . time . "\n" *>
  <* = 'Or formated: ' . &PAB3::Utils::strftime( '%c', time ) *>


B<Performance notice:> Combining multiple expressions into one string can speed
up the print process.
For example:

   faster:
   <* print $x . ' some data: ' . $str *>
   
   slower:
   <* print $x, ' some data: ', $str *>

Joining several PRINT directives into one directive does not realy
affect to the speed, because the optimizer will do it automatically.


=item :   E<lt>expressionE<gt>

=item     E<lt>expressionE<gt>

Executes E<lt>expressionE<gt> wihout printing the output.
B<This is also the default action if no directive has been specified.>

  <* : <expression> *>

or

  <* <expression>     *>

Example:

  <* : $my_var = 1 *>
  <* : &my_sub( $my_var ) *>
  <* $x = $y *>


=item IF   E<lt>conditionE<gt>

=item ELSIF   E<lt>conditionE<gt>

=item ELSE

=item END IF

Enclosed block is processed if the E<lt>conditionE<gt> is true.

  <* IF <condition>    *>
  ...
  <* ELSIF <condition> *>
  ...
  <* ELSE              *>
  ...
  <* END IF            *>

Example:

  <* if ( $rowpos % 2 ) == 0 *>
  <tr class="even">
  <* else *>
  <tr class="odd">
  <* end if *>


=item INCLUDE   E<lt>templateE<gt>

Process another template file.
Please note to "class_name" at L<new()|PAB3/new>.

  <* INCLUDE <expression> *>

Example:

  <* include banner.tpl *>
  
  - or -
  
  <* $banner = int( rand( 3 ) ) + 1 *>
  <* include banner${banner}.tpl *>

=item LOOP

=item LOOP   <id>

=item LOOP   <id> <exp1>

=item LOOP   <id> <exp1> <exp2>

=item LOOP   <exp1>

=item END LOOP

Performs a predefined loop, a loop registered by
L<register_loop|PAB3/register_loop> or an unregistered loop.
Predefined loops are ARRAY and HASH. These are using
E<lt>exp1E<gt> as source and E<lt>exp2E<gt> as record.
In registered loops E<lt>exp1E<gt> optionally can be used as record and
E<lt>exp2E<gt> as an argument.
Unregistered loops can be used with or without E<lt>idE<gt>. The loop must be
defined in E<lt>exp1E<gt> without brackets.
The difference between registered and unregistered loops is that registered
loops are defined in the perl script and unregistered loops are defined in
the template.

  <* LOOP <id> [<exp1> [<exp2>]] *>
  ...
  <* END LOOP                    *>

B<Example of a predefined ARRAY loop>

  <* LOOP ARRAY @INC $_ *>
  <*   PRINT $_ . "\n" *>
  <* END LOOP *>

B<Example of a predefined HASH loop>

  <* LOOP HASH %ENV $_ *>
  <*   PRINT $_ . ' = ' . $ENV{$_} . "\n" *>
  <* END LOOP *>

B<Example of a registered loop>

--- perl script ---

  use PAB3 qw(:const);
  
  $pab = PAB3->new( ... );
  
  @data = (
      { 'Name' => 'Smith',    'Prename' => 'John',   'Age' => 33 },
      { 'Name' => 'Thomson',  'Prename' => 'Peggy',  'Age' => 45 },
      { 'Name' => 'Johanson', 'Prename' => 'Gustav', 'Age' => 27 },
  );
  
  $pab->register_loop(
       'PERSON', 'data' => PAB_ARRAY, 'per' => PAB_HASH
  );
  
  $pab->make_script_and_run( 'template' );

--- template ---

  <* LOOP PERSON *>
  <* = $per->{'Prename'} . ' ' . $per->{'Name'} *> is <* = $per->{'Age'} *> years old
  <* END LOOP PERSON *>


B<Example of a registered loop with hashmap>

--- perl script ---

  use PAB3 qw(:const);
  
  $pab = PAB3->new( ... );
  
  @data = (
      [ 'Smith', 'John', 33 ],
      [ 'Thomson', 'Peggy', 45 ],
      [ 'Johanson', 'Gustav', 27 ],
  );
  
  @fields = ( 'Name', 'Prename', 'Age' );
  
  $pab->register_loop(
       'PERSON', 'data' => PAB_ARRAY, 'per' => PAB_ARRAY
  );
  $pab->add_hashmap( 'PERSON', 'per', \@fields );
  
  $pab->make_script_and_run( 'template' );

--- template ---

  <* LOOP PERSON *>
  <* = $per->{'Prename'} . ' ' . $per->{'Name'} *> is <* = $per->{'Age'} *> years old
  <* END LOOP PERSON *>


B<Example of unregistered loops>

--- perl script ---

  use PAB3 qw(:const);
  
  $pab = PAB3->new( ... );
  
  @h_data = (
      { 'Name' => 'Smith',    'Prename' => 'John',   'Age' => 33 },
      { 'Name' => 'Thomson',  'Prename' => 'Peggy',  'Age' => 45 },
      { 'Name' => 'Johanson', 'Prename' => 'Gustav', 'Age' => 27 },
  );
  @a_data = (
      [ 'Smith',    'John',   33 ],
      [ 'Thomson',  'Peggy',  45 ],
      [ 'Johanson', 'Gustav', 27 ],
  );
  @fields = ( 'Name', 'Prename', 'Age' );
  
  $pab->add_hashmap( 'PERSON_MAPPED', 'per', \@fields );
  
  $pab->make_script_and_run( 'template' );

--- template ---

  # without id
  <* LOOP foreach $per( @h_data ) *>
  <* = $per->{'Prename'} . ' ' . $per->{'Name'} *> is <* = $per->{'Age'} *> years old
  <* END LOOP *>
  
  # with id
  <* LOOP PERSON foreach $per( @h_data ) *>
  <* = $per->{'Prename'} . ' ' . $per->{'Name'} *> is <* = $per->{'Age'} *> years old
  <* END LOOP PERSON *>
  
  # with hashmap
  <* LOOP PERSON_MAPPED foreach $per (@a_data) *>
  <* = $per->{'Prename'} . ' ' . $per->{'Name'} *> is <* = $per->{'Age'} *> years old
  <* END LOOP *>


See also
L<register_loop()|PAB3/register_loop>, L<add_hashmap()|PAB3/add_hashmap>


=item SUB    <expression>

=item END SUB

Defines a subroutine in the style C<local E<lt>expressionE<gt> = sub { ... };>.

  <* SUB <expression> *>
  ...
  <* END SUB          *>

Example:

  <* SUB *action *>
  <* PRINT $ENV{'SCRIPT'} . '?do=' . ( $_[0] || '' ) *>
  <* END SUB *>
  
  <a href="<* &action( 'open' ) *>">Open</a>


=item COMMENTS

Comments are copied.

  <* #... *>

Example:

  # comment out directives.
  <* #print $foo *>


=item !X    <directive>

This special directive prints the content in E<lt>directiveE<gt>
as a new directive. It can be useful to generate templates
from templates.

  <* !X <directive> *>

Example:

  <* $foo = '$bar' *>
  
  <* !X print $foo *>
  
  produces: <* print $bar *>
  
  <* !X print \$foo *>
  
  produces: <* print $foo *>

=back

=head1 EXPORTS

By default nothing is exported. To export constants like PAB_SCALAR, etc use
the export tag ":const". To export functions and constants use the export tag
":default".

=head1 AUTHORS

Christian Mueller <christian_at_hbr1.com>

=head1 COPYRIGHT

The PAB3 module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=cut
