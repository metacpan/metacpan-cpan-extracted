## -*- perl -*-
##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic.pm
## Version 0.11.6
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/08/24
## Modified 2020/03/27
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic;
BEGIN
{
    require 5.6.0;
    use strict;
    use Scalar::Util qw( openhandle );
    use Data::Dumper;
    use Data::Printer 
    {
    	sort_keys => 1,
    	filters => 
    	{
    		'DateTime' => sub{ $_[0]->stringify },
    	}
    };
    use Devel::StackTrace;
	# use Class::Struct qw( struct );
	use Text::Number;
	use Number::Format;
	use TryCatch;
	use B;
	## To get some context on what the caller expect. This is used in our error() method to allow chaining without breaking
	use Want;
	use Class::Load ();
    our( @ISA, @EXPORT_OK, @EXPORT, %EXPORT_TAGS, $AUTOLOAD );
    our( $VERSION, $ERROR, $SILENT_AUTOLOAD, $VERBOSE, $DEBUG, $MOD_PERL );
    our( $PARAM_CHECKER_LOAD_ERROR, $PARAM_CHECKER_LOADED, $CALLER_LEVEL );
    our( $OPTIMIZE_MESG_SUB );
    use Exporter ();
    @ISA         = qw( Exporter );
    @EXPORT      = qw( );
    @EXPORT_OK   = qw( subclasses );
    %EXPORT_TAGS = ();
    $VERSION     = '0.11.6';
    $VERBOSE     = 0;
    $DEBUG       = 0;
    $SILENT_AUTOLOAD      = 1;
    $PARAM_CHECKER_LOADED = 0;
    $CALLER_LEVEL         = 0;
    $OPTIMIZE_MESG_SUB    = 0;
    local $^W;
    no strict qw(refs);
    #our $true  = ${"Module::Generic::Boolean::true"};
    #our $false = ${"Module::Generic::Boolean::false"};
};

INIT
{
    our $true  = ${"Module::Generic::Boolean::true"};
    our $false = ${"Module::Generic::Boolean::false"};
};

{
	## mod_perl/2.0.10
    if( exists( $ENV{ 'MOD_PERL' } )
        &&
        ( $MOD_PERL = $ENV{ 'MOD_PERL' } =~ /^mod_perl\/\d+\.[\d\.]+/ ) )
    {
        select( ( select( STDOUT ), $| = 1 )[ 0 ] );
        require Apache2::Log;
        require Apache2::ServerUtil;
        require Apache2::RequestUtil;
        require Apache2::ServerRec;
    }
	
	our $DEBUG_LOG_IO = undef();
	
	our $DB_NAME = $DATABASE;
	our $DB_HOST = $SQL_SERVER;
	our $DB_USER = $DB_LOGIN;
	our $DB_PWD  = $DB_PASSWD;
	our $DB_RAISE_ERROR = $SQL_RAISE_ERROR;
	our $DB_AUTO_COMMIT = $SQL_AUTO_COMMIT;

# 	struct Module::Error => 
# 	{
# 	'type'		=> '$',
# 	'code'		=> '$',
# 	'message'	=> '$',
# 	'file'		=> '$',
# 	'line'		=> '$',
# 	'package'	=> '$',
# 	'sub'		=> '$',
# 	'trace'		=> '$',
# 	'retry_after' => '$',
# 	};
}

sub import
{
    my $self = shift( @_ );
    my( $pkg, $file, $line ) = caller();
    local $Exporter::ExportLevel = 1;
    ## local $Exporter::Verbose = $VERBOSE;
    Exporter::import( $self, @_ );
    
    ##print( STDERR "Module::Generic::import(): called from package '$pkg' in file '$file' at line '$line'.\n" ) if( $DEBUG );
    ( my $dir = $pkg ) =~ s/::/\//g;
    my $path  = $INC{ $dir . '.pm' };
    ##print( STDERR "Module::Generic::import(): using primary path of '$path'.\n" ) if( $DEBUG );
    if( defined( $path ) )
    {
        ## Try absolute path name
        $path =~ s/^(.*)$dir\.pm$/$1auto\/$dir\/autosplit.ix/;
        ##print( STDERR "Module::Generic::import(): using treated path of '$path'.\n" ) if( $DEBUG );
        eval
        {
            local $SIG{ '__DIE__' }  = sub{ };
            local $SIG{ '__WARN__' } = sub{ };
            require $path;
        };
        if( $@ )
        {
            $path = "auto/$dir/autosplit.ix";
            eval
            {
                local $SIG{ '__DIE__' }  = sub{ };
				local $SIG{ '__WARN__' } = sub{ };
				require $path;
            };
        }
        if( $@ )
        {
            CORE::warn( $@ ) unless( $SILENT_AUTOLOAD );
        }
        ##print( STDERR "Module::Generic::import(): '$path' ", $@ ? 'not ' : '', "loaded.\n" ) if( $DEBUG );
    }
}

sub new
{
    my $that  = shift( @_ );
    my $class = ref( $that ) || $that;
    ## my $pkg   = ( caller() )[ 0 ];
    ## print( STDERR __PACKAGE__ . "::new(): our calling package is '", ( caller() )[ 0 ], "', our class is '$class'.\n" );
    my $self  = {};
    ## print( STDERR "${class}::OBJECT_READONLY: ", ${ "${class}\::OBJECT_READONLY" }, "\n" );
    if( defined( ${ "${class}\::OBJECT_PERMS" } ) )
    {
        my %hash  = ();
        my $obj   = tie(
        %hash, 
        'Module::Generic::Tie', 
        'pkg'        => [ __PACKAGE__, $class ],
        'perms'        => ${ "${class}::OBJECT_PERMS" },
        );
        $self  = \%hash;
    }
    bless( $self, $class );
    if( $MOD_PERL )
    {
        my $r = Apache2::RequestUtil->request;
        $r->pool->cleanup_register
        (
          sub
          {
          ## my( $pkg, $file, $line ) = caller();
          ## print( STDERR "Apache procedure: Deleting all the object keys for object '$self' and package '$class' called within package '$pkg' in file '$file' at line '$line'.\n" );
          map{ delete( $self->{ $_ } ) } keys( %$self );
          undef( %$self );
          }
        );
    }
    if( defined( ${ "${class}\::LOG_DEBUG" } ) )
    {
    	$self->{ 'log_debug' } = ${ "${class}::LOG_DEBUG" };
    }
    return( $self->init( @_ ) );
}

## This is used to transform package data set into hash refer suitable for api calls
## If package use AUTOLOAD, those AUtILOAD should make sure to create methods on the fly so they become defined
sub as_hash
{
	my $self = shift( @_ );
    my $this = $self->_obj2h;
	my $p = {};
	$p = shift( @_ ) if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' );
	# $self->message( 3, "Parameters are: ", sub{ $self->dumper( $p ) } );
	my $class = ref( $self );
	no strict 'refs';
	my @methods = grep{ defined &{"${class}::$_"} } keys( %{"${class}::"} );
	# $self->messagef( 3, "The following methods found in package $class: '%s'.", join( "', '", sort( @methods ) ) );
	use strict 'refs';
	my $ref = {};
	foreach my $meth ( sort( @methods ) )
	{
		next if( substr( $meth, 0, 1 ) eq '_' );
		my $rv = eval{ $self->$meth };
		if( $@ )
		{
			warn( "An error occured while accessing method $meth: $@\n" );
			next;
		}
		no overloading;
		# $self->message( 3, "Value for method '$meth' is '$rv'." );
		use overloading;
		if( $p->{json} && ( ref( $rv ) eq 'JSON::PP::Boolean' || ref( $rv ) eq 'Module::Generic::Boolean' ) )
		{
			# $self->message( 3, "Encoding boolean to true or false for method '$meth'." );
			$ref->{ $meth } = Module::Generic::Boolean::TO_JSON( $ref->{ $meth } );
			next;
		}
		elsif( $self->_is_object( $rv ) )
		{
			if( $rv->can( 'as_hash' ) && overload::Overloaded( $rv ) && overload::Method( $rv, '""' ) )
			{
				$rv = $rv . '';
			}
			elsif( $rv->can( 'as_hash' ) )
			{
				# $self->message( 3, "$rv is an object (", ref( $rv ), ") capable of as_hash, calling it." );
				$rv = $rv->as_hash( $p );
			}
		}
		
		## $self->message( 3, "Checking field '$meth' with value '$rv'." );
		
		if( ref( $rv ) eq 'HASH' )
		{
			$ref->{ $meth } = $rv if( scalar( keys( %$rv ) ) );
		}
		## If method call returned an array, like array of string or array of object such as in data from Net::API::Stripe::List
		elsif( ref( $rv ) eq 'ARRAY' )
		{
			my $arr = [];
			foreach my $this_ref ( @$rv )
			{
				my $that_ref = ( $self->_is_object( $this_ref ) && $this_ref->can( 'as_hash' ) ) ? $this_ref->as_hash : $this_ref;
				CORE::push( @$arr, $that_ref );
			}
			$ref->{ $meth } = $arr if( scalar( @$arr ) );
		}
		elsif( !ref( $rv ) )
		{
			$ref->{ $meth } = $rv if( CORE::length( $rv ) );
		}
		elsif( CORE::length( "$rv" ) )
		{
			$self->message( 3, "Adding value '$rv' to field '$meth' in hash \$ref" );
			$ref->{ $meth } = $rv;
		}
	}
	return( $ref );
}

sub clear
{
	goto( &clear_error );
}

sub clear_error
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    $this->{error} = ${ "$class\::ERROR" } = '';
    return( 1 );
}

sub clone
{
    my $self  = shift( @_ );
    if( UNIVERSAL::isa( $self, 'HASH' ) )
    {
    	return( bless( { %$self } => ( ref( $self ) || $self ) ) );
    }
    elsif( UNIVERSAL::isa( $self, 'ARRAY' ) )
    {
    	return( bless( [ @$self ] => ( ref( $self ) || $self ) ) );
    }
    else
    {
    	return( $self->error( "Cloning is unsupported for type \"", ref( $self ), "\". Only hash or array references are supported." ) );
    }
}

sub debug
{
    my $self  = shift( @_ );
    my $class = ref( $self );
    my $this  = $self->_obj2h;
    if( @_ )
    {
        my $flag = shift( @_ );
        $this->{debug} = $flag;
        $self->message_switch( $flag ) if( $OPTIMIZE_MESG_SUB );
        if( $this->{debug} &&
            !$this->{debug_level} )
        {
            $this->{debug_level} = $this->{debug};
        }
    }
    return( $this->{debug} || ${"$class\:\:DEBUG"} );
}

sub dump { return( shift->printer( @_ ) ); }

## For backward compatibility and traceability
sub dump_print { return( shift->dumpto_printer( @_ ) ); }

sub dumper
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' );
    # local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Maxdepth = $opts->{depth} if( CORE::length( $opts->{depth} ) );
	local $Data::Dumper::Sortkeys = sub
	{
		my $h = shift( @_ );
		return( [ sort( grep{ ref( $h->{ $_ } ) !~ /^(DateTime|DateTime\:\:)/ } keys( %$h ) ) ] );
	};
    return( Data::Dumper::Dumper( @_ ) );
}

sub printer
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' );
    local $SIG{__WARN__} = sub{ };
    if( scalar( keys( %$opts ) ) )
    {
		return( Data::Printer::np( @_, %$opts ) );
    }
    else
    {
		return( Data::Printer::np( @_ ) );
    }
}

*dumpto = \&dumpto_dumper;

sub dumpto_printer
{
    my $self  = shift( @_ );
    my( $data, $file ) = @_;
    my $fh = IO::File->new( ">$file" ) || die( "Unable to create file '$file': $!\n" );
	$fh->binmode( ':utf8' );
	$fh->print( Data::Printer::np( $data ), "\n" );
    $fh->close;
    ## 666 so it can work under command line and web alike
    chmod( 0666, $file );
    return( 1 );
}

sub dumpto_dumper
{
    my $self  = shift( @_ );
    my( $data, $file ) = @_;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Useqq = 1;
    my $fh = IO::File->new( ">$file" ) || die( "Unable to create file '$file': $!\n" );
    if( ref( $data ) )
    {
		$fh->print( Data::Dumper::Dumper( $data ), "\n" );
    }
    else
    {
    	$fh->binmode( ':utf8' );
    	$fh->print( $data );
    }
    $fh->close;
    ## 666 so it can work under command line and web alike
    chmod( 0666, $file );
    return( 1 );
}

sub errno
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    if( @_ )
    {
        $this->{errno} = shift( @_ ) if( $_[ 0 ] =~ /^\-?\d+$/ );
        return( $self->error( @_ ) ) if( @_ );
    }
    return( $this->{errno} );
}

sub error
{
	my $self = shift( @_ );
	my $class = ref( $self ) || $self;
    my $this = $self->_obj2h;
	if( @_ )
	{
		my $args = {};
		if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) )
		{
			$args->{object} = shift( @_ );
		}
		elsif( ref( $_[0] ) eq 'HASH' )
		{
			$args  = shift( @_ );
		}
		else
		{
			$args->{message} = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @_ ) );
		}
		$args->{message} = substr( $args->{message}, 0, $this->{error_max_length} ) if( $this->{error_max_length} > 0 && length( $args->{message} ) > $this->{error_max_length} );
        $this->{_msg_no_exec_sub} = 0;
		my $n = 1;
		$n++ while( ( caller( $n ) )[0] eq 'Module::Generic' );
		$args->{skip_frames} = $n + 1;
		## my( $p, $f, $l ) = caller( $n );
		## my( $sub ) = ( caller( $n + 1 ) )[3];
		my $o = $this->{error} = ${ $class . '::ERROR' } = Module::Generic::Exception->new( $args );
		## printf( STDERR "%s::error() called from package %s ($p) in file %s ($f) at line %d ($l) from sub %s ($sub)\n", __PACKAGE__, $o->package, $o->file, $o->line, $o->subroutine );
		
		my $r;
		$r = Apache2::RequestUtil->request if( $MOD_PERL );
		# $r->log_error( "Called for error $o" ) if( $r );
		$r->warn( $o->as_string ) if( $r );
		my $err_handler = $self->error_handler;
		if( $err_handler && ref( $err_handler ) eq 'CODE' )
		{
			# $r->log_error( "Module::Generic::error(): called for object error hanler" ) if( $r );
			$err_handler->( $o );
		}
        elsif( $r )
        {
			# $r->log_error( "Module::Generic::error(): called for Apache mod_perl error hanler" ) if( $r );
        	if( my $log_handler = $r->get_handlers( 'PerlPrivateErrorHandler' ) )
        	{
        		$log_handler->( $o );
        	}
        	else
        	{
				# $r->log_error( "Module::Generic::error(): No Apache mod_perl error handler set, reverting to log_error" ) if( $r );
				# $r->log_error( "$o" );
				$r->warn( $o->as_string );
        	}
        }
        elsif( $this->{fatal} )
        {
            ## die( sprintf( "Within package %s in file %s at line %d: %s\n", $o->package, $o->file, $o->line, $o->message ) );
			# $r->log_error( "Module::Generic::error(): called calling die" ) if( $r );
            die( $o );
        }
        elsif( !exists( $this->{quiet} ) || !$this->{quiet} )
        {
			# $r->log_error( "Module::Generic::error(): calling warn" ) if( $r );
			if( $r )
			{
				$r->warn( $o->as_string );
			}
			else
			{
				warn( $o );
			}
        }
        ## https://metacpan.org/pod/Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef
        ## https://perlmonks.org/index.pl?node_id=741847
        ## Because in list context this would create a lit with one element undef()
        ## A bare return will return an empty list or an undef scalar
		## return( undef() );
		## return;
		## As of 2019-10-13, Module::Generic version 0.6, we use this special package Module::Generic::Null to be returned in chain without perl causing the error that a method was called on an undefined value
		if( want( 'OBJECT' ) )
		{
			my $null = Module::Generic::Null->new( $o, { debug => $this->{debug}, has_error => 1 });
			rreturn( $null );
		}
		return;
	}
	return( ref( $self ) ? $this->{error} : ${ $class . '::ERROR' } );
}

sub error_handler { return( shift->_set_get_code( '_error_handler', @_ ) ); }

*errstr = \&error;

sub get
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my @data = map{ $data->{ $_ } } @_;
    return( wantarray() ? @data : $data[ 0 ] );
}

sub init
{
    my $self = shift( @_ );
    my $pkg  = ref( $self );
    my $this = $self->_obj2h;
    $this->{verbose} = ${ $pkg . '::VERBOSE' } if( !length( $this->{verbose} ) );
    $this->{debug}   = ${ $pkg . '::DEBUG' } if( !length( $this->{debug} ) );
    $this->{version} = ${ $pkg . '::VERSION' } if( !defined( $this->{version} ) );
    $this->{level}   = 0;
    ## If no debug level was provided when calling message, this level will be assumed
    ## Example: message( "Hello" );
    ## If _message_default_level was set to 3, this would be equivalent to message( 3, "Hello" )
    $this->{ '_message_default_level' } = 0;
    my $data = $this;
    if( $this->{_data_repo} )
    {
    	$this->{ $this->{_data_repo} } = {} if( !$this->{ $this->{_data_repo} } );
    	$data = $this->{ $this->{_data_repo} };
    }
    if( @_ )
    {
    	my @args = @_;
    	my $vals;
    	if( ref( $args[0] ) eq 'HASH' )
    	{
    		## $self->_message( 3, "Got an hash ref" );
    		my $h = shift( @args );
    		$vals = [ %$h ];
    		## $vals = [ %{$_[0]} ];
    	}
    	elsif( ref( $args[0] ) eq 'ARRAY' )
    	{
    		## $self->_message( 3, "Got an array ref" );
    		$vals = $args[0];
    	}
    	## Special case when there is an undefined value passed (null) even though it is declared as a hash or object
    	elsif( scalar( @args ) == 1 && !defined( $args[0] ) )
    	{
    		# return( undef() );
    		return;
    	}
    	elsif( ( scalar( @args ) % 2 ) )
    	{
    		return( $self->error( sprintf( "Uneven number of parameters provided (%d). Should receive key => value pairs. Parameters provideds are: %s", scalar( @args ), join( ', ', @args ) ) ) );
    	}
    	else
    	{
    		## $self->message( 3, "Got an array: ", sub{ $self->dumper( \@args ) } );
    		$vals = \@args;
    	}
    	## Check if there is a debug parameter, and if we find one, set it first so that that 
    	## calls to the package subroutines can produce verbose feedback as necessary
    	for( my $i = 0; $i < scalar( @$vals ); $i++ )
    	{
    		if( $vals->[$i] eq 'debug' )
    		{
    			my $v = $vals->[$i + 1];
    			$self->debug( $v );
    			CORE::splice( @$vals, $i, 2 );
    		}
    	}
    	
    	for( my $i = 0; $i < scalar( @$vals ); $i++ )
    	{
    		my $name = $vals->[ $i ];
    		my $val  = $vals->[ ++$i ];
    		my $meth = $self->can( $name );
    		# $self->message( 3, "Does the object from class (", ref( $self ), ") has a method $name? ", ( defined( $meth ) ? 'yes' : 'no' ) );
    		if( defined( $meth ) )
    		{
				$self->$name( $val );
				next;
    		}
			elsif( $this->{_init_strict_use_sub} )
			{
				# $self->message( 3, "Checking if method $name exist in class ", ref( $self ), ": ", $self->can( $name ) ? 'yes' : 'no' );
				#if( !defined( $meth = $self->can( $name ) ) )
				#{
					$self->error( "Unknown method $name in class $pkg" );
					next;
				#}
				# $self->message( 3, "Calling method $name with value $val" );
				# $self->$meth( $val );
				# $meth->( $self, $val );
				#$self->$name( $val );
				#next;
			}
    		elsif( exists( $data->{ $name } ) )
    		{
    			if( index( $data->{ $name }, '::' ) != -1 || $data->{ $name } =~ /^[a-zA-Z][a-zA-Z\_]*[a-zA-Z]$/ )
    			{
    				my $thisPack = $data->{ $name };
    				if( !Scalar::Util::blessed( $val ) )
    				{
    					return( $self->error( "$name parameter expects a package $thisPack object, but instead got '$val'." ) );
    				}
    				elsif( !$val->isa( $thisPack ) )
    				{
    					return( $self->error( "$name parameter expects a package $thisPack object, but instead got an object from package '", ref( $val ), "'." ) );
    				}
    			}
    			elsif( $this->{_init_strict} )
    			{
    				if( ref( $data->{ $name } ) eq 'ARRAY' )
    				{
    					return( $self->error( "$name parameter expects an array reference, but instead got '$val'." ) ) if( ref( $val ) ne 'ARRAY' );
    				}
    				elsif( ref( $data->{ $name } ) eq 'HASH' )
    				{
    					return( $self->error( "$name parameter expects an hash reference, but instead got '$val'." ) ) if( ref( $val ) ne 'HASH' );
    				}
    				elsif( ref( $data->{ $name } ) eq 'SCALAR' )
    				{
    					return( $self->error( "$name parameter expects a scalar reference, but instead got '$val'." ) ) if( ref( $val ) ne 'SCALAR' );
    				}
    			}
    		}
    		## The name parameter does not exist
    		else
    		{
    			## If we are strict, we reject
    			next if( $this->{_init_strict} );
    		}
    		## We passed all tests
    		$data->{ $name } = $val;
    	}
    }
    if( $OPTIMIZE_MESG_SUB && !$this->{verbose} && !$this->{debug} )
    {
        if( defined( &{ "$pkg\::message" } ) )
        {
            *{ "$pkg\::message_off" } = \&{ "$pkg\::message" } unless( defined( &{ "$pkg\::message_off" } ) );
            *{ "$pkg\::message" } = sub { 1 };
        }
    }
    return( $self );
}

sub log_handler { return( shift->_set_get_code( '_log_handler', @_ ) ); }

# sub log4perl
# {
# 	my $self = shift( @_ );
# 	if( @_ )
# 	{
# 		require Log::Log4perl;
# 		my $ref = shift( @_ );
# 		Log::Log4perl::init( $ref->{ 'config_file' } );
# 		my $log = Log::Log4perl->get_logger( $ref->{ 'domain' } );
# 		$self->{ 'log4perl' } = $log;
# 	}
# 	else
# 	{
# 		$self->{ 'log4perl' };
# 	}
# }

sub message
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    ## my( $pack, $file, $line ) = caller;
    my $this = $self->_obj2h;
    ## print( STDERR __PACKAGE__ . "::message(): Called from package $pack in file $file at line $line with debug value '$hash->{debug}', package DEBUG value '", ${ $class . '::DEBUG' }, "' and params '", join( "', '", @_ ), "'\n" );
    my $r;
    $r = Apache2::RequestUtil->request if( $MOD_PERL );
    if( $this->{verbose} || $this->{debug} || ${ $class . '::DEBUG' } )
    {
    	# $r->log_error( "Got here in Module::Generic::message before checking message." ) if( $r );
        my $ref;
        $ref = $self->message_check( @_ );
    	## print( STDERR __PACKAGE__ . "::message(): message_check() returns '$ref' (", join( '', @$ref ), ")\n" );
        ## return( 1 ) if( !( $ref = $self->message_check( @_ ) ) );
        return( 1 ) if( !$ref );
        
        my $opts = {};
        $opts = pop( @$ref ) if( ref( $ref->[-1] ) eq 'HASH' );
        ## print( STDERR __PACKAGE__ . "::message(): \$opts contains: ", $self->dumper( $opts ), "\n" );
        
        ## By now, we should have a reference to @_ in $ref
        ## my $class = ref( $self ) || $self;
        ## print( STDERR __PACKAGE__ . "::message(): caller at 0 is ", (caller(0))[3], " and at 1 is ", (caller(1))[3], "\n" );
    	## $r->log_error( "Got here in Module::Generic::message checking frames stack." ) if( $r );
        my $stackFrame = $self->message_frame( (caller(1))[3] ) || 1;
        $stackFrame = 1 unless( $stackFrame =~ /^\d+$/ );
        $stackFrame-- if( $stackFrame );
        $stackFrame++ if( (caller(1))[3] eq 'Module::Generic::messagef' );
        my( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
        my $sub = ( caller( $stackFrame + 1 ) )[3];
        my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
        if( ref( $this->{_message_frame} ) eq 'HASH' )
        {
        	if( exists( $this->{_message_frame}->{ $sub2 } ) )
        	{
        		my $frameNo = int( $this->{_message_frame}->{ $sub2 } );
        		if( $frameNo > 0 )
        		{
        			( $pkg, $file, $line, $sub ) = caller( $frameNo );
					$sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
        		}
        	}
        }
        ## $r->log_error( "Called from package $pkg in file $file at line $line from sub $sub2 ($sub)" ) if( $r );
        if( $sub2 eq 'message' )
        {
            $stackFrame++;
            ( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
			my $sub = ( caller( $stackFrame + 1 ) )[3];
            $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
        }
    	## $r->log_error( "Got here in Module::Generic::message building the message string." ) if( $r );
        my $txt;
        if( $opts->{message} )
        {
        	if( ref( $opts->{message} ) eq 'ARRAY' )
        	{
        		$txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @{$opts->{message}} ) );
        	}
        	else
        	{
        		$txt = $opts->{message};
        	}
        }
        else
        {
			$txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @$ref ) );
        }
        ## Reset it
        $this->{_msg_no_exec_sub} = 0;
    	## $r->log_error( "Got here in Module::Generic::message with message string '$txt'." ) if( $r );
        no overloading;
        my $mesg = "${pkg}::${sub2}( $self ) [$line]: " . $txt;
        $mesg    =~ s/\n$//gs;
        $mesg = '## ' . join( "\n## ", split( /\n/, $mesg ) );
        
        my $info = 
        {
        'formatted'	=> $mesg,
		'message'	=> $txt,
		'file'		=> $file,
		'line'		=> $line,
		'package'	=> $class,
		'sub'		=> $sub2,
		'level'		=> ( $_[0] =~ /^\d+$/ ? $_[0] : CORE::exists( $opts->{level} ) ? $opts->{level} : 0 ),
        };
        $info->{type} = $opts->{type} if( $opts->{type} );
        
    	## $r->log_error( "Got here in Module::Generic::message checkin if we run under ModPerl." ) if( $r );
        ## If Mod perl is activated AND we are not using a private log
        ## my $r;
        ## if( $MOD_PERL && !${ "${class}::LOG_DEBUG" } && ( $r = eval{ require Apache2::RequestUtil; Apache2::RequestUtil->request; } ) )
        if( $r && !${ "${class}::LOG_DEBUG" } )
        {
        	## $r->log_error( "Got here in Module::Generic::message, going to call our log handler." );
        	if( my $log_handler = $r->get_handlers( 'PerlPrivateLogHandler' ) )
        	{
				# my $meta = B::svref_2object( $log_handler );
				# $r->log_error( "Module::Generic::message(): Log handler code routine name is " . $meta->GV->NAME . " called in file " . $meta->GV->FILE . " at line " . $meta->GV->LINE );
        		$log_handler->( $mesg );
        	}
        	else
        	{
				$r->log_error( $mesg );
        	}
        }
        ## Using ModPerl Server to log
        elsif( $MOD_PERL && !${ "${class}::LOG_DEBUG" } )
        {
			require Apache2::ServerUtil;
			my $s = Apache2::ServerUtil->server;
			$s->log_error( $mesg );
        }
        ## e.g. in our package, we could set the handler using the curry module like $self->{_log_handler} = $self->curry::log
        elsif( !-t( STDIN ) && $this->{_log_handler} && ref( $this->{_log_handler} ) eq 'CODE' )
        {
        	# $r = Apache2::RequestUtil->request;
        	# $r->log_error( "Got here in Module::Generic::message, going to call our log handler without using Apache callbacks." );
			# my $meta = B::svref_2object( $self->{_log_handler} );
			# $r->log_error( "Log handler code routine name is " . $meta->GV->NAME . " called in file " . $meta->GV->FILE . " at line " . $meta->GV->LINE );
        	$this->{_log_handler}->( $info );
        }
        elsif( !-t( STDIN ) && ${ $class . '::MESSAGE_HANDLER' } && ref( ${ $class . '::MESSAGE_HANDLER' } ) eq 'CODE' )
        {
        	my $h = ${ $class . '::MESSAGE_HANDLER' };
        	$h->( $info );
        }
        ## Or maybe then into a private log file?
        ## This way, even if the log method is superseeded, we can keep using ours without interfering with the other one
        elsif( $self->message_log( $mesg, "\n" ) )
        {
        	return( 1 );
        }
        ## Otherwise just on the stderr
        else
        {
			my $err = IO::File->new;
			$err->fdopen( fileno( STDERR ), 'w' );
			$err->binmode( ":utf8" ) unless( $opts->{no_encoding} );
			$err->autoflush( 1 );
			$err->print( $mesg, "\n" );
        }
    }
    return( 1 );
}

sub messagef
{
	my $self  = shift( @_ );
	## print( STDERR "got here: ", ref( $self ), "::messagef\n" );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    if( $this->{verbose} || $this->{debug} || ${ $class . '::DEBUG' } )
    {
    	my $level = ( $_[0] =~ /^\d+$/ ? shift( @_ ) : undef() );
    	my $opts = {};
    	if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' && ( CORE::exists( $_[-1]->{level} ) || CORE::exists( $_[-1]->{type} ) || CORE::exists( $_[-1]->{message} ) ) )
    	{
    		$opts = pop( @_ );
    	}
    	$level = $opts->{level} if( !defined( $level ) && CORE::exists( $opts->{level} ) );
    	my( $ref, $fmt );
    	if( $opts->{message} )
    	{
    		if( ref( $opts->{message} ) eq 'ARRAY' )
    		{
    			$ref = $opts->{message};
    			$fmt = shift( @$ref );
    		}
    		else
    		{
    			$fmt = $opts->{message};
    			$ref = \@_;
    		}
    	}
    	else
    	{
			$ref = \@_;
			$fmt = shift( @$ref );
        }
		my $txt = sprintf( $fmt, map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @$ref ) );
		## print( STDERR ref( $self ), "::messagef \$txt is '$txt'\n" );
		$opts->{message} = $txt;
		$opts->{level} = $level if( defined( $level ) );
        # return( $self->message( defined( $level ) ? ( $level, $txt ) : $txt ) );
        return( $self->message( ( $level || 0 ), $opts ) );
    }
    return( 1 );
}

sub message_check
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this = $self->_obj2h;
    ## printf( STDERR "Our class is $class and DEBUG_TARGET contains: '%s' and debug value is %s\n", join( ', ', @${ "${class}::DEBUG_TARGET" } ), $hash->{ 'debug' } );
    if( @_ )
    {
    	if( $_[0] !~ /^\d/ )
    	{
    		## The last parameter is an options parameter which has the level property set
    		if( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) )
    		{
    			## Then let's use this
    		}
    		elsif( $this->{ '_message_default_level' } =~ /^\d+$/ &&
    			$this->{ '_message_default_level' } > 0 )
			{
				unshift( @_, $this->{ '_message_default_level' } );
			}
			else
			{
				unshift( @_, 1 );
			}
		}
        ## If the first argument looks line a number, and there is more than 1 argument
        ## and it is greater than 1, and greater than our current debug level
        ## well, we do not output anything then...
        if( ( $_[ 0 ] =~ /^\d+$/ || ( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) ) ) && 
        	@_ > 1 )
        {
        	my $message_level;
        	if( $_[ 0 ] =~ /^\d+$/ )
        	{
        		$message_level = shift( @_ );
        	}
        	elsif( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) )
        	{
        		$message_level = $_[-1]->{level};
        	}
        	my $target_re = '';
        	if( ref( ${ "${class}::DEBUG_TARGET" } ) eq 'ARRAY' )
        	{
				$target_re = scalar( @${ "${class}::DEBUG_TARGET" } ) ? join( '|', @${ "${class}::DEBUG_TARGET" } ) : '';
        	}
        	if( $this->{debug} >= $message_level ||
        		$this->{verbose} >= $message_level ||
        		${ $class . '::DEBUG' } >= $message_level ||
        		$this->{debug_level} >= $message_level ||
        		$this->{debug} >= 100 || 
        		( length( $target_re ) && $class =~ /^$target_re$/ && ${ $class . '::GLOBAL_DEBUG' } >= $message_level ) )
        	{
        		## print( STDERR ref( $self ) . "::message_check(): debug is '$hash->{debug}', verbose '$hash->{verbose}', DEBUG '", ${ $class . '::DEBUG' }, "', debug_level = $hash->{debug_level}\n" );
				return( \@_ );
        	}
        	else
        	{
        		return( 0 );
        	}
        }
    }
    return( 0 );
}

sub message_frame
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    $this->{_message_frame } = {} if( !exists( $this->{_message_frame} ) );
    my $mf = $this->{_message_frame};
    if( @_ )
    {
    	my $args = {};
    	if( ref( $_[0] ) eq 'HASH' )
    	{
    		$args = shift( @_ );
    		my @k = keys( %$args );
    		@$mf{ @k } = @$args{ @k };
    	}
    	elsif( !( @_ % 2 ) )
    	{
    		$args = { @_ };
    		my @k = keys( %$args );
    		@$mf{ @k } = @$args{ @k };
    	}
    	elsif( scalar( @_ ) == 1 )
    	{
    		my $sub = shift( @_ );
			$sub = substr( $sub, rindex( $sub, '::' ) + 2 ) if( index( $sub, '::' ) != -1 );
    		return( $mf->{ $sub } );
    	}
    	else
    	{
    		return( $self->error( "I was expecting a key => value pair such as routine => stack frame (integer)" ) );
    	}
    }
    return( $mf );
}

sub message_log
{
	my $self = shift( @_ );
	my $io   = $self->message_log_io;
	#print( STDERR "Module::Generic::log: \$io now is '$io'\n" );
	return( undef() ) if( !$io );
	#print( STDERR "Module::Generic::log: \$io is not an open handle\n" ) if( !openhandle( $io ) && $io );
	return( undef() ) if( !Scalar::Util::openhandle( $io ) && $io );
	## 2019-06-14: I decided to remove this test, because if a log is provided it should print to it
	## If we are on the command line, we can easily just do tail -f log_file.txt for example and get the same result as
	## if it were printed directly on the console
# 	my $rc = CORE::print( $io @_ ) || return( $self->error( "Unable to print to log file: $!" ) );
	my $rc = $io->print( scalar( localtime( time() ) ), " [$$]: ", @_ ) || return( $self->error( "Unable to print to log file: $!" ) );
	## print( STDERR "Module::Generic::log (", ref( $self ), "): successfully printed to debug log file. \$rc is $rc, \$io is '$io' and message is: ", join( '', @_ ), "\n" );
	return( $rc );
}

sub message_log_io
{
	#return( shift->_set_get( 'log_io', @_ ) );
	my $self  = shift( @_ );
	my $class = ref( $self );
	my $this  = $self->_obj2h;
	if( @_ )
	{
		my $io = shift( @_ );
		$self->_set_get( 'log_io', $io );
	}
	elsif( ${ "${class}::LOG_DEBUG" } && 
		!$self->_set_get( 'log_io' ) && 
		${ "${class}::DEB_LOG" } )
	{
		our $DEB_LOG = ${ "${class}::DEB_LOG" };
		unless( $DEBUG_LOG_IO )
		{
			$DEBUG_LOG_IO = IO::File->new( ">>$DEB_LOG" ) || die( "Unable to open debug log file $DEB_LOG in append mode: $!\n" );
			$DEBUG_LOG_IO->binmode( ':utf8' );
			$DEBUG_LOG_IO->autoflush( 1 );
		}
		$self->_set_get( 'log_io', $DEBUG_LOG_IO );
	}
	return( $self->_set_get( 'log_io' ) );
}

sub message_switch
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
	my $this = $self->_obj2h;
    if( @_ )
    {
        my $flag = shift( @_ );
        if( $flag )
        {
            if( defined( &{ "$pkg\::message_off" } ) )
            {
            	## Restore previous backup
                *{ "${pkg}::message" } = \&{ "${pkg}::message_off" };
            }
            else
            {
                *{ "${pkg}::message" } = \&{ "Module::Generic::message" };
            }
        }
        ## We switch it down if nobody is going to use it
        elsif( !$flag && !$this->{verbose} && !$this->{debug} )
        {
            *{ "${pkg}::message_off" } = \&{ "${pkg}::message" } unless( defined( &{ "${pkg}::message_off" } ) );
            *{ "${pkg}::message" } = sub { 1 };
        }
    }
    return( 1 );
}

sub noexec { $_[0]->{_msg_no_exec_sub} = 1; return( $_[0] ); }

## Purpose is to get an error object thrown from another package, and make it ours and pass it along
sub pass_error
{
	my $self = shift( @_ );
	my $this = $self->_obj2h;
	my $err  = shift( @_ );
	return if( !ref( $err ) || !Scalar::Util::blessed( $err ) );
	$this->{error} = ${ $class . '::ERROR' } = $err;
	if( want( 'OBJECT' ) )
	{
		my $null = Module::Generic::Null->new( $err, { debug => $this->{debug}, has_error => 1 });
		rreturn( $null );
	}
	return;
}

sub quiet {	return( shift->_set_get( 'quiet', @_ ) ); }

sub save
{
	my $self = shift( @_ );
    my $this = $self->_obj2h;
	my $opts = {};
	$opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
	my( $file, $data );
	if( @_ == 2 )
	{
		$opts->{data} = shift( @_ );
		$opts->{file} = shift( @_ );
	}
	return( $self->error( "No file was provided to save data to." ) ) if( !$opts->{file} );
	my $fh = IO::File->new( ">$opts->{file}" ) || return( $self->error( "Unable to open file \"$opts->{file}\" in write mode: $!" ) );
	$fh->binmode( ':' . $opts->{encoding} ) if( $opts->{encoding} );
	$fh->autoflush( 1 );
	if( !defined( $fh->print( ref( $opts->{data} ) eq 'SCALAR' ? ${$opts->{data}} : $opts->{data} ) ) )
	{
		return( $self->error( "Unable to write data to file \"$opts->{file}\": $!" ) )
	}
	$fh->close;
	my $bytes = -s( $opts->{file} );
	return( $bytes );
}

sub set
{
    my $self = shift( @_ );
    my %arg  = ();
    if( @_ )
    {
        %arg = ( @_ );
        my $this = $self->_obj2h;
        my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
        my @keys = keys( %arg );
        @$data{ @keys } = @arg{ @keys };
    }
    return( scalar( keys( %arg ) ) );
}

sub subclasses
{
    my $self  = shift( @_ );
    my $that  = '';
    $that     = @_ ? shift( @_ ) : $self;
    my $base  = ref( $that ) || $that;
    $base  =~ s,::,/,g;
    $base .= '.pm';
    
    require IO::Dir;
    ## remove '.pm'
    my $dir = substr( $INC{ $base }, 0, ( length( $INC{ $base } ) ) - 3 );
    
    my @packages = ();
    my $io = IO::Dir->open( $dir );
    if( defined( $io ) )
    {
        @packages = map{ substr( $_, 0, length( $_ ) - 3 ) } grep{ substr( $_, -3 ) eq '.pm' && -f( "$dir/$_" ) } $io->read();
        $io->close ||
        warn( "Unable to close directory \"$dir\": $!\n" );
    }
    else
    {
        warn( "Unable to open directory \"$dir\": $!\n" );
    }
    return( wantarray() ? @packages : \@packages );
}

sub true  { ${"Module::Generic::Boolean::true"} }

sub false { ${"Module::Generic::Boolean::false"} }

sub verbose
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    if( @_ )
    {
        my $flag = shift( @_ );
        $this->{verbose} = $flag;
        $self->message_switch( $flag ) if( $OPTIMIZE_MESG_SUB );
    }
    return( $this->{verbose} );
}

sub will
{
    ( @_ >= 2 && @_ <= 3 ) || die( 'Usage: $obj->can( "method" ) or Module::Generic::will( $obj, "method" )' );
    my( $obj, $meth, $level );
    ## $obj->will( $other_obj, 'method' );
    if( @_ == 3 && ref( $_[ 1 ] ) )
    {
        $obj  = $_[ 1 ];
        $meth = $_[ 2 ];
    }
    else
    {
        ( $obj, $meth, $level ) = @_;
    }
    return( undef() ) if( !ref( $obj ) && index( $obj, '::' ) == -1 );
    ## Give a chance to UNIVERSAL::can
    my $ref = undef;
    if( Scalar::Util::blessed( $obj ) && ( $ref = $obj->can( $meth ) ) )
    {
    	return( $ref );
    }
    my $class = ref( $obj ) || $obj;
    my $origi = $class;
    if( index( $meth, '::' ) != -1 )
    {
        $origi = substr( $meth, 0, rindex( $meth, '::' ) );
        $meth  = substr( $meth, rindex( $meth, '::' ) + 2 );
    }
    $ref = \&{ "$class\::$meth" } if( defined( &{ "$class\::$meth" } ) );
    ## print( $err "\t" x $level, "UNIVERSAL::can ", defined( $ref ) ? "succeeded" : "failed", " in finding the method \"$meth\" in object/class $obj.\n" );
    ## print( $err "\t" x $level, defined( $ref ) ? "succeeded" : "failed", " in finding the method \"$meth\" in object/class $obj.\n" );
    return( $ref ) if( defined( $ref ) );
    ## We do not go further down the rabbit hole if level is greater or equal to 10
    $level ||= 0;
    return( undef() ) if( $level >= 10 );
    $level++;
    ## Let's see what Alice has got for us... :-)
    ## We look in the @ISA to see if the method exists in the package from which we
    ## possibly inherited
    if( @{ "$class\::ISA" } )
    {
        ## print( STDERR "\t" x $level, "Checking ", scalar( @{ "$class\::ISA" } ), " entries in \"\@${class}\:\:ISA\".\n" );
        foreach my $pack ( @{ "$class\::ISA" } )
        {
            ## print( STDERR "\t" x $level, "Looking up method \"$meth\" in inherited package \"$pack\".\n" );
            my $ref = &will( $pack, "$origi\::$meth", $level );
            return( $ref ) if( defined( $ref ) );
        }
    }
    ## Then, maybe there is an AUTOLOAD to trap undefined routine?
    ## But, we do not want any loop, do we?
    ## Since will() is called from Module::Generic::AUTOLOAD to check if EXTRA_AUTOLOAD exists
    ## we are not going to call Module::Generic::AUTOLOAD for EXTRA_AUTOLOAD...
    if( $class ne 'Module::Generic' && $meth ne 'EXTRA_AUTOLOAD' && defined( &{ "$class\::AUTOLOAD" } ) )
    {
        ## print( STDERR "\t" x ( $level - 1 ), "Found an AUTOLOAD in class \"$class\". Ok.\n" );
        my $sub = sub
        {
            $class::AUTOLOAD = "$origi\::$meth";
            &{ "$class::AUTOLOAD" }( @_ );
        };
        return( $sub );
    }
    return( undef() );
}

sub __instantiate_object
{
	my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
	my $this  = $self->_obj2h;
	my $o;
	try
	{
		## https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
		## require $class unless( defined( *{"${class}::"} ) );
		my $rc = eval{ Class::Load::load_class( $class ); };
		return( $self->error( "Unable to load class $class: $@" ) ) if( $@ );
		# $self->message( 3, "Called with args: ", sub{ $self->dumper( \@_ ) } );
		$o = @_ ? $class->new( @_ ) : $class->new;
		$o->debug( $this->{debug} ) if( $o->can( 'debug' ) );
		return( $self->pass_error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
	}
	catch( $e ) 
	{
		return( $self->error({ code => 500, message => $e }) );
	}
	return( $o );
}

## Call to the actual method doing the work
## The reason for doing so is because _instantiate_object() may be inherited, but
## _set_get_class or _set_get_hash_as_object created dynamic class which requires to call _instantiate_object
## If _instantiate_object is inherited, it will yield unpredictable results
sub _instantiate_object { return( shift->__instantiate_object( @_ ) ); }

sub _is_class_loaded { shift( @_ ); return( Class::Load::is_class_loaded( @_ ) ); }

## UNIVERSAL::isa works for both array or array as objects
## sub _is_array { return( UNIVERSAL::isa( $_[1], 'ARRAY' ) ); }
sub _is_array { return( Scalar::Util::reftype( $_[1] ) eq 'ARRAY' ); }

## sub _is_hash { return( UNIVERSAL::isa( $_[1], 'HASH' ) ); }
sub _is_hash { return( Scalar::Util::reftype( $_[1] ) eq 'HASH' ); }

sub _is_object { return( Scalar::Util::blessed( $_[1] ) ); }

sub _load_class { shift( @_ ); return( Class::Load::load_class( @_ ) ); }

sub _obj2h
{
    my $self = shift( @_ );
    ## print( STDERR "_obj2h(): Getting a hash refernece out of the object '$self'\n" );
    if( UNIVERSAL::isa( $self, 'HASH' ) )
    {
        return( $self );
    }
    elsif( UNIVERSAL::isa( $self, 'GLOB' ) )
    {
    	## print( STDERR "Returning a reference to an hash for glob $self\n" );
        return( \%{*$self} );
    }
    ## The method that called message was itself called using the package name like My::Package->some_method
    ## We are going to check if global $DEBUG or $VERBOSE variables are set and create the related debug and verbose entry into the hash we return
    elsif( !ref( $self ) )
    {
    	my $class = $self;
    	my $hash =
    	{
    	'debug' => ${ "${class}\::DEBUG" },
    	'verbose' => ${ "${class}\::VERBOSE" },
    	'error' => ${ "${class}\::ERROR" },
    	};
    	## XXX 
    	## print( STDERR "Called with '$self' with debug value '$hash->{debug}' and verbose '$hash->{verbose}'\n" );
    	return( $hash );
    }
    ## Because object may be accessed as My::Package->method or My::Package::method
    ## there is not always an object available, so we need to fake it to avoid error
    ## This is primarly itended for generic methods error(), errstr() to work under any conditions.
    else
    {
        return( {} );
    }
}

sub _parse_timestamp
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    ## No value was actually provided
    return( undef() ) if( !length( $str ) );
	my $this = $self->_obj2h;
	my $tz = DateTime::TimeZone->new( name => 'local' );
	my $error = 0;
	my $opt = 
	{
	pattern   => '%Y-%m-%d %T',
	locale    => 'en_GB',
	time_zone => $tz->name,
	on_error => sub{ $error++ },
	};
	# $self->message( 3, "Checking timestamp string '$str' for appropriate pattern" );
	## 2019-06-19 23:23:57.000000000+0900
	## From PostgreSQL: 2019-06-20 11:02:36.306917+09
	## ISO 8601: 2019-06-20T11:08:27
	if( $str =~ /(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})(?:[[:blank:]]+|T)(\d{1,2}:\d{1,2}:\d{1,2})(?:\.\d+)?((?:\+|\-)\d{2,4})?/ )
	{
		my( $date, $time, $zone ) = ( "$1-$2-$3", $4, $5 );
		if( !length( $zone ) )
		{
			my $dt = DateTime->now( time_zone => $tz );
			my $offset = $dt->offset;
			## e.g. 9 or possibly 9.5
			my $offset_hour = ( $offset / 3600 );
			## e.g. 9.5 => 0.5 * 60 = 30
			my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
			$zone  = sprintf( '%+03d%02d', $offset_hour, $offset_min );
		}
		# $self->message( 3, "\tMatched pattern #1 with date '$date', time '$time' and time zone '$zone'." );
		$date =~ tr/\//-/;
		$zone .= '00' if( length( $zone ) == 3 );
		$str = "$date $time$zone";
		$self->message( 3, "\tChanging string to '$str'" );
		$opt->{pattern} = '%Y-%m-%d %T%z';
	}
	## From SQLite: 2019-06-20 02:03:14
	## From MySQL: 2019-06-20 11:04:01
	elsif( $str =~ /(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})(?:[[:blank:]]+|T)(\d{1,2}:\d{1,2}:\d{1,2})/ )
	{
		my( $date, $time ) = ( "$1-$2-$3", $4 );
		# $self->message( 3, "\tMatched pattern #2 with date '$date', time '$time' and without time zone." );
		my $dt = DateTime->now( time_zone => $tz );
		my $offset = $dt->offset;
		## e.g. 9 or possibly 9.5
		my $offset_hour = ( $offset / 3600 );
		## e.g. 9.5 => 0.5 * 60 = 30
		my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
		my $offset_str  = sprintf( '%+03d%02d', $offset_hour, $offset_min );
		$date =~ tr/\//-/;
		$str = "$date $time$offset_str";
		$self->message( 3, "\tAdding time zone '", $tz->name, "' offset of $offset_str with result: '$str'." );
		$opt->{pattern} = '%Y-%m-%d %T%z';
	}
	elsif( $str =~ /^(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})$/ )
	{
		$str = "$1-$2-$3";
		# $self->message( 3, "\tMatched pattern #3 with date '$date' only." );
		$opt->{pattern} = '%Y-%m-%d';
	}
	else
	{
		return( '' );
	}
	my $strp = DateTime::Format::Strptime->new( %$opt );
	my $dt = $strp->parse_datetime( $str );
	return( $dt );
}

sub _set_get
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
        $data->{ $field } = $val;
    }
    if( wantarray() )
    {
        if( ref( $data->{ $field } ) eq 'ARRAY' )
        {
            return( @{ $data->{ $field } } );
        }
        elsif( ref( $data->{ $field } ) eq 'HASH' )
        {
            return( %{ $data->{ $field } } );
        }
        else
        {
            return( ( $data->{ $field } ) );
        }
    }
    else
    {
        return( $data->{ $field } );
    }
}

sub _set_get_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
        $data->{ $field } = $val;
    }
	return( $data->{ $field } );
}

sub _set_get_array_as_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
        my $o = $data->{ $field };
        ## Some existing data, like maybe default value
        if( $o )
        {
        	if( !$self->_is_object( $o ) )
        	{
        		my $tmp = $o;
        		$o = Module::Generic::Array->new( $tmp );
        	}
        	$o->set( $val );
        }
        else
        {
			$o = Module::Generic::Array->new( $val );
			$data->{ $field } = $o;
        }
    }
	if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
	{
        my $o = Module::Generic::Array->new( $data->{ $field } );
		$data->{ $field } = $o;
	}
	return( $data->{ $field } );
}

sub _set_get_boolean
{
	my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
	if( @_ )
	{
		my $val = shift( @_ );
		# $self->message( 3, "Value provided for field '$field' is '$val' of reference (", ref( $val ), ")." );
		if( Scalar::Util::blessed( $val ) && 
			( $val->isa( 'JSON::PP::Boolean' ) || $val->isa( 'Module::Generic::Boolean' ) ) )
		{
			$data->{ $field } = $val;
		}
		elsif( ref( $val ) eq 'SCALAR' )
		{
			$data->{ $field } = $$val ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
		}
		elsif( lc( $val ) eq 'true' || lc( $val ) eq 'false' )
		{
			$data->{ $field } = lc( $val ) eq 'true' ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
		}
		else
		{
			$data->{ $field } = $val ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
		}
		# $self->message( 3, "Boolean field now has value $self->{$field} (", ref( $self->{ $field } ), ")." );
	}
	## If there is a value set, like a default value and it is not an object or at least not one we recognise
	## We transform it into a Module::Generic::Boolean object
	if( CORE::length( $data->{ $field } ) && 
		( 
			!Scalar::Util::blessed( $data->{ $field } ) || 
			( 
				Scalar::Util::blessed( $data->{ $field } ) && 
				!$data->{ $field }->isa( 'Module::Generic::Boolean' ) && 
				!$data->{ $field }->isa( 'JSON::PP::Boolean' ) 
			) 
		) )
	{
		my $val = $data->{ $field };
		$data->{ $field } = $val ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
	}
	return( $data->{ $field } );
}

sub __create_class
{
	my $self  = shift( @_ );
	my $field = shift( @_ ) || return( $self->error( "No field was provided to create a dynamic class." ) );
	my $def   = shift( @_ );
    my $class;
    if( $def->{_class} )
    {
    	$class = $def->{_class};
    }
    else
    {
		my $new_class = $field;
		$new_class =~ tr/-/_/;
		$new_class =~ s/\_{2,}/_/g;
		$new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
		$class = ref( $self ) . "\::${new_class}";
	}
	unless( Class::Load::is_class_loaded( $class ) )
	{
		# $self->message( 3, "Class '$class' is not created yet, creating it." );
		my $type2func =
		{
		array		=> '_set_get_array',
		array_as_object => '_set_get_array_as_object',
		boolean		=> '_set_get_boolean',
		class		=> '_set_get_class',
		class_array	=> '_set_get_class_array',
		datetime	=> '_set_get_datetime',
		hash		=> '_set_get_hash',
		number		=> '_set_get_number',
		object		=> '_set_get_object',
		object_array => '_set_get_object_array',
		object_array_object => '_set_get_object_array_object',
		scalar		=> '_set_get_scalar',
		scalar_or_object => '_set_get_scalar_or_object',
		uri			=> '_set_get_uri',
		};
		
		my $perl = <<EOT;
package $class;
BEGIN
{
	use strict;
	use Module::Generic;
	use parent -norequire, qw( Module::Generic );
};

EOT
		my $call_sub = ( split( /::/, ( caller(1) )[3] ) )[-1];
		my $call_frame = $call_sub eq '_set_get_class' ? 1 : 0;
		my( $pack, $file, $line ) = caller( $call_frame );
		my $code_lines = [];
		foreach my $f ( sort( keys( %$def ) ) )
		{
			# $self->message( 3, "Checking field '$f'." );
			my $info = $def->{ $f };
			my $type = lc( $info->{type} );
			if( !CORE::exists( $type2func->{ $type } ) )
			{
				warn( "Warning only: _set_get_class was called from package $pack at line $line in file $file, but the type provided \"$type\" is unknown to us, so we are skipping this field \"$f\" in the creation of our virtual class.\n" );
				next;
			}
			my $func = $type2func->{ $type };
			if( $type eq 'object' || 
				$type eq 'scalar_or_object' || 
				$type eq 'object_array' )
			{
				if( !$info->{class} )
				{
					warn( "Warning only: _set_get_class was called from package $pack at line $line in file $file, and class \"$class\" field \"$f\" is to require an object, but no object class name was provided. Use the \"class\" property parameter. So we are skipping this field \"$f\" in the creation of our virtual class.\n" );
					next;
				}
				my $this_class = $info->{class};
				CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', '$this_class', \@_ ) ); }" );
			}
			elsif( $type eq 'class' || $type eq 'class_array' )
			{
				my $this_def = $info->{definition};
				if( !CORE::exists( $info->{definition} ) )
				{
					warn( "Warning only: No dynamic class fields definition was provided for this field \"$f\". Skipping this field.\n" );
					next;
				}
				elsif( ref( $this_def ) ne 'HASH' )
				{
					warn( "Warning only: I was expecting a fields definition hash reference for dynamic class field \"$f\", but instead got '$this_def'. Skipping this field.\n" );
					next;
				}
				my $d = Data::Dumper->new( [ $this_def ] );
				$d->Indent( 0 );
				$d->Purity( 1 );
				$d->Pad( '' );
				$d->Terse( 1 );
				$d->Sortkeys( 1 );
				my $hash_str = $d->Dump;
				CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', $hash_str, \@_ ) ); }" );
			}
			else
			{
				CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', \@_ ) ); }" );
			}
		}
		$perl .= join( "\n\n", @$code_lines );

		$perl .= <<EOT;


1;

EOT
		# $self->message( 3, "Evaluating code:\n$perl" );
		# print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Evaluating\n$perl\n" );
		my $rc = eval( $perl );
		# print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
		die( "Unable to dynamically create module $class: $@" ) if( $@ );
	}
	return( $class );
}

## $self->_set_get_class( 'my_field', {
## _class => 'My::Class',
## field1 => { type => 'datetime' },
## field2 => { type => 'scalar' },
## field3 => { type => 'boolean' },
## field4 => { type => 'object', class => 'Some::Class' },
## }, @_ );
sub _set_get_class
{
	my $self  = shift( @_ );
	# $self->message( 3, "Got here with arguments: '", join( "', '", @_ ), "'." );
    my $field = shift( @_ );
    my $def   = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( ref( $def ) ne 'HASH' )
    {
    	CORE::warn( "Warning only: dynamic class field definition hash ($def) for field \"$field\" is not a hash reference.\n" );
    	return;
    }
    
    my $class = $self->__create_class( $field, $def ) || die( "Failed to create the dynamic class for field \"$field\".\n" );
	
	if( @_ )
	{
		my $hash = shift( @_ );
		# my $o = $class->new( $hash );
		$self->messagef( 3, "Instantiating object of class '$class' with hash '$hash' containing %d elements: '%s'", scalar( keys( %$hash ) ), join( "', '", map{ "$_ => $hash->{$_}" } sort( keys( %$hash ) ) ) );
		## $self->messagef( 3, "Instantiating object of class '$class' with hash '$hash' containing %d elements: '%s'", scalar( keys( %$hash ) ), $self->dumper( $hash ) );
		my $o = $self->__instantiate_object( $field, $class, $hash );
		# $self->message( 3, "\tReturning object for field '$field' and class '$class': '$o'." );
		$data->{ $field } = $o;
	}
	
	if( !$data->{ $field } )
	{
		my $o = $self->__instantiate_object( $field, $class );
		$data->{ $field } = $o;
	}
	return( $data->{ $field } );
}

sub _set_get_class_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $def   = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( ref( $def ) ne 'HASH' )
    {
    	CORE::warn( "Warning only: dynamic class field definition hash ($def) for field \"$field\" is not a hash reference.\n" );
    	return;
    }
	@_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    my $class = $self->__create_class( $field, $def ) || die( "Failed to create the dynamic class for field \"$field\".\n" );
    ## return( $self->_set_get_object_array( $field, $class, @_ ) );
    if( @_ )
    {
    	my $ref = shift( @_ );
    	return( $self->error( "I was expecting an array ref, but instead got '$ref'" ) ) if( ref( $ref ) ne 'ARRAY' );
    	my $arr = [];
    	for( my $i = 0; $i < scalar( @$ref ); $i++ )
    	{
    		if( ref( $ref->[$i] ) ne 'HASH' )
    		{
				return( $self->error( "Array offset $i is not a hash reference. I was expecting a hash reference to instantiate an object of class $class." ) );
    		}
			my $o = $self->__instantiate_object( $field, $class, $ref->[$i] );
			CORE::push( @$arr, $o );
		}
    	$data->{ $field } = $arr;
    }
	return( $data->{ $field } );
}

sub _set_get_code
{
	my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
	if( @_ )
	{
		my $v = shift( @_ );
		return( $self->error( "Value provided for \"$field\" ($v) is not an anonymous subroutine (code). You can pass as argument something like \$self->curry::my_sub or something like sub { some_code_here; }" ) ) if( ref( $v ) ne 'CODE' );
		$data->{ $field } = $v;
	}
	return( $data->{ $field } );
}

sub _set_get_datetime
{
	my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
	if( @_ )
	{
		my $time = shift( @_ );
		# $self->message( 3, "Processing time stamp $time possibly of ref (", ref( $time ), ")." );
		my $now;
		if( !defined( $time ) )
		{
			$data->{ $field } = $time;
			return( $data->{ $field } );
		}
		elsif( Scalar::Util::blessed( $time ) )
		{
			return( $self->error( "Object provided as value for $field, but this is not a DateTime object" ) ) if( !$time->isa( 'DateTime' ) );
			$data->{ $field } = $time;
			return( $data->{ $field } );
		}
		elsif( $time =~ /^\d+$/ && $time !~ /^\d{10}$/ )
		{
			return( $self->error( "DateTime value ($time) provided for field $field does not look like a unix timestamp" ) );
		}
		elsif( $now = $self->_parse_timestamp( $time ) )
		{
			## Found a parsed datetime value
			$data->{ $field } = $now;
			return( $now );
		}
		
		# $self->message( 3, "Creating a DateTime object out of $time\n" );
		eval
		{
			require DateTime;
			require DateTime::Format::Strptime;
			$now = DateTime->from_epoch(
				epoch => $time,
				time_zone => 'local',
			);
			my $strp = DateTime::Format::Strptime->new(
				pattern => '%s',
				locale => 'en_GB',
				time_zone => 'local',
			);
			$now->set_formatter( $strp );
		};
		if( $@ )
		{
			$self->message( "Error while trying to get the DateTime object for field $k with value $time" );
		}
		else
		{
			# $self->message( 3, "Returning the DateTime object '$now'" );
			$data->{ $field } = $now;
		}
	}
	## So that a call to this field will not trigger an error: "Can't call method "xxx" on an undefined value"
	if( !$data->{ $field } && want( 'OBJECT' ) )
	{
		my $null = Module::Generic::Null->new( $o, { debug => $this->{debug}, has_error => 1 });
		rreturn( $null );
	}
	return( $data->{ $field } );
}

sub _set_get_hash
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
	# $self->message( 3, "Called for field '$field' with data '", join( "', '", @_ ), "'." );
	@_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( @_ )
    {
        my $val;
        if( ref( $_[0] ) eq 'HASH' )
        {
        	$val = shift( @_ );
        }
        elsif( ( @_ % 2 ) )
        {
        	$val = { @_ };
        }
        else
        {
        	my $val = shift( @_ );
        	return( $self->error( "Method $field takes only a hash or reference to a hash, but value provided ($val) is not supported" ) );
        }
        # $self->message( 3, "Setting value $val for field $field" );
        $data->{ $field } = $val;
    }
	return( $data->{ $field } );
}

sub _set_get_hash_as_object
{
	my $self = shift( @_ );
	my $this = $self->_obj2h;
	# $self->message( 3, "Called with args: ", $self->dumper( \@_ ) );
	my $field = shift( @_ ) || return( $self->error( "No field provided for _set_get_hash_as_object" ) );
	my $class;
	if( @_ )
	{
		## No class was provided
		# if( ref( $_[0] ) eq 'HASH' )
		if( UNIVERSAL::isa( $_[0], 'HASH' ) )
		{
			my $new_class = $field;
			$new_class =~ tr/-/_/;
			$new_class =~ s/\_{2,}/_/g;
			$new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
			$class = ref( $self ) . "\::${new_class}";
		}
		elsif( ref( $_[0] ) )
		{
			return( $self->error( "Class name in _set_get_hash_as_object helper method cannot be a reference. Received: \"", overload::StrVal( $_[0] ), "\"." ) );
		}
		else
		{
			$class = shift( @_ );
		}
	}
	else
	{
		my $new_class = $field;
		$new_class =~ tr/-/_/;
		$new_class =~ s/\_{2,}/_/g;
		$new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
		$class = ref( $self ) . "\::${new_class}";
	}
	# my $class = shift( @_ );
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
	## Remove any @_ if there is just one entry and it is undef
	@_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
	unless( Class::Load::is_class_loaded( $class ) )
	{
		my $perl = <<EOT;
package $class;
BEGIN
{
	use strict;
	use Module::Generic;
	use parent -norequire, qw( Module::Generic::Dynamic );
};

1;

EOT
		# print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Evaluating\n$perl\n" );
		my $rc = eval( $perl );
		# print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
		die( "Unable to dynamically create module $class: $@" ) if( $@ );
	}
	
	if( @_ )
	{
		my $hash = shift( @_ );
		# my $o = $class->new( $hash );
		my $o = $self->__instantiate_object( $field, $class, $hash );
		$data->{ $field } = $o;
	}
	
	if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
	{
		my $o = $data->{ $field } = $self->__instantiate_object( $field, $class, $data->{ $field } );
	}
	return( $data->{ $field } );
}

sub _set_get_number
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
	@_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( @_ )
    {
    	$data->{ $field } = Text::Number->new( shift( @_ ) );
    }
    return( $data->{ $field } );
}

sub _set_get_number_or_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
    	if( ref( $_[0] ) eq 'HASH' || Scalar::Util::blessed( $_[0] ) )
    	{
    		return( $self->_set_get_object( $field, $class, @_ ) );
    	}
    	else
    	{
    		return( $self->_set_get_number( $field, @_ ) );
    	}
    }
    return( $data->{ $field } );
}

sub _set_get_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    no overloading;
    # $self->message( 3, "Called for field '$field' and class '$class'." );
    if( @_ )
    {
    	if( scalar( @_ ) == 1 )
    	{
    		## User removed the value by passing it an undefined value
    		if( !defined( $_[0] ) )
    		{
    			$data->{ $field } = undef();
    		}
			## User pass an object
    		elsif( Scalar::Util::blessed( $_[0] ) )
    		{
				my $o = shift( @_ );
				return( $self->error( "Object provided (", ref( $o ), ") for $field is not a valid $class object" ) ) if( !$o->isa( "$class" ) );
				## XXX Bad idea:
				## $o->debug( $this->{debug} ) if( $o->can( 'debug' ) );
				$data->{ $field } = $o;
    		}
    		else
    		{
				my $o = $self->_instantiate_object( $field, $class, @_ ) || return( $self->pass_error( $class->error ) );
				# $self->message( 3, "Setting field $field value to $o" );
				$data->{ $field } = $o;
    		}
    	}
    	else
    	{
			my $o = $self->_instantiate_object( $field, $class, @_ ) || return( $self->pass_error( $class->error ) );
			# $self->message( 3, "Setting field $field value to $o" );
			$data->{ $field } = $o;
    	}
    }
    ## If nothing has been set for this field, ie no object, but we are called in chain
    ## we set a dummy object that will just call itself to avoid perl complaining about undefined value calling a method
	if( !$data->{ $field } && want( 'OBJECT' ) )
	{
		# print( STDERR __PACKAGE__, "::_set_get_object(): Called in a chain for field $field and class $class, but no object is set, reverting to dummy object\n" );
		# $self->message( 3, "Called in a chain, but no object is set, reverting to dummy object." );
		## my $null = Module::Generic::Null->new( $o, { debug => $self->{debug}, has_error => 1 });
		## rreturn( $null );
		my $o = $self->_instantiate_object( $field, $class, @_ ) || return( $self->pass_error( $class->error ) );
		$data->{ $field } = $o;
		return( $o );
	}
	# $self->message( 3, "Returning for field '$field' value: ", $self->{ $field } );
	return( $data->{ $field } );
}

sub _set_get_object_array2
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
    	my $data_to_process = shift( @_ );
    	return( $self->error( "I was expecting an array ref, but instead got '$this'" ) ) if( ref( $data_to_process ) ne 'ARRAY' );
    	my $arr1 = [];
    	foreach my $ref ( @$data_to_process )
    	{
    		return( $self->error( "I was expecting an embeded array ref, but instead got '$ref'." ) ) if( ref( $ref ) ne 'ARRAY' );
			my $arr = [];
			for( my $i = 0; $i < scalar( @$ref ); $i++ )
			{
				my $o;
				if( defined( $ref->[$i] ) )
				{
					return( $self->error( "Parameter provided for adding object of class $class is not a reference." ) ) if( !ref( $ref->[$i] ) );
					if( Scalar::Util::blessed( $ref->[$i] ) )
					{
						return( $self->error( "Array offset $i contains an object from class $pack, but was expecting an object of class $class." ) ) if( !$ref->[$i]->isa( $class ) );
						$o = $ref->[$i];
					}
					elsif( ref( $ref->[$i] ) eq 'HASH' )
					{
						#$o = $class->new( $h, $ref->[$i] );
						$o = $self->_instantiate_object( $field, $class, $ref->[$i] );
					}
					else
					{
						$self->error( "Warning only: data provided to instaantiate object of class $class is not a hash reference" );
					}
				}
				else
				{
					#$o = $class->new( $h );
					$o = $self->_instantiate_object( $field, $class );
				}
				return( $self->error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
				# $o->{ '_parent' } = $self->{ '_parent' };
				push( @$arr, $o );
			}
			push( @$arr1, $arr );
    	}
    	$data->{ $field } = $arr1;
    }
	return( $data->{ $field } );
}

sub _set_get_object_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
	@_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( @_ )
    {
    	my $ref = shift( @_ );
    	return( $self->error( "I was expecting an array ref, but instead got '$ref'" ) ) if( ref( $ref ) ne 'ARRAY' );
    	my $arr = [];
    	for( my $i = 0; $i < scalar( @$ref ); $i++ )
    	{
			if( defined( $ref->[$i] ) )
			{
				return( $self->error( "Array offset $i is not a reference. I was expecting an object of class $class or an hash reference to instantiate an object." ) ) if( !ref( $ref->[$i] ) );
				if( Scalar::Util::blessed( $ref->[$i] ) )
				{
					return( $self->error( "Array offset $i contains an object from class $pack, but was expecting an object of class $class." ) ) if( !$ref->[$i]->isa( $class ) );
					push( @$arr, $ref->[$i] );
				}
				elsif( ref( $ref->[$i] ) eq 'HASH' )
				{
					#$o = $class->new( $h, $ref->[$i] );
					$o = $self->_instantiate_object( $field, $class, $ref->[$i] ) || return;
					push( @$arr, $o );
				}
				else
				{
					$self->error( "Warning only: data provided to instantiate object of class $class is not a hash reference" );
				}
			}
			else
			{
				return( $self->error( "Array offset $i contains an undefined value. I was expecting an object of class $class." ) );
				$o = $self->_instantiate_object( $field, $class ) || return;
				push( @$arr, $o );
			}
    	}
    	$data->{ $field } = $arr;
    }
	return( $data->{ $field } );
}

sub _set_get_object_array_object
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field name was provided for this array of object." ) );
    my $class = shift( @_ ) || return( $self->error( "No class was provided for this array of objects." ) );
	my $this = $self->_obj2h;
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
	@_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( @_ )
    {
    	my $that = ( scalar( @_ ) == 1 && UNIVERSAL::isa( $_[0], 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
    	## $self->message( 3, "Received following data to store as array object: ", sub{ $self->dump( $that ) } );
		my $ref = $self->_set_get_object_array( $field, $class, $that );
		## $self->message( 3, "Object array returned is: ", sub{ $self->dump( $ref ) } );
		$data->{ $field } = Module::Generic::Array->new( $ref );
		## $self->message( 3, "Now value for field '$field' is: ", $data->{ $field }, " which contains: '", $data->{ $field }->join( "', '" ), "'." );
    }
    ## Default value so that call to the caller's method like my_sub->length will not produce something like "Can't call method "length" on an undefined value"
    ## Also, this will make i possible to set default value in caller's object and we would turn it into array object.
	if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
	{
        my $o = Module::Generic::Array->new( $data->{ $field } );
		$data->{ $field } = $o;
	}
	return( $data->{ $field } );
}

sub _set_get_object_variant
{
	my $self  = shift( @_ );
    my $field = shift( @_ );
    ## The class precisely depends on what we find looking ahead
    my $class = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
	if( @_ )
	{
		if( ref( $_[0] ) eq 'HASH' )
		{
			my $o = $self->_instantiate_object( $field, $class, @_ );
		}
		## AN array of objects hash
		elsif( ref( $_[0] ) eq 'ARRAY' )
		{
			my $arr = shift( @_ );
			my $res = [];
			foreach my $data ( @$arr )
			{
				my $o = $self->_instantiate_object( $field, $class, $data ) || return( $self->error( "Unable to create object: ", $self->error ) );
				push( @$res, $o );
			}
			$data->{ $field } = $res;
		}
	}
	return( $data->{ $field } );
}

sub _set_get_scalar
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 ) ? shift( @_ ) : join( '', @_ );
        ## Just in case, we force stringification
        ## $val = "$val" if( defined( $val ) );
        return( $self->error( "Method $field takes only a scalar, but value provided ($val) is a reference" ) ) if( ref( $val ) eq 'HASH' || ref( $val ) eq 'ARRAY' );
        $data->{ $field } = $val;
    }
	return( $data->{ $field } );
}

sub _set_get_scalar_as_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val;
        if( ref( $val ) eq 'SCALAR' || UNIVERSAL::isa( $val, 'SCALAR' ) )
        {
        	$val = $$_[0];
        }
        elsif( ref( $val ) )
        {
        	return( $self->error( "I was expecting a string or a scalar reference, but instead got '$val'" ) );
        }
        else
        {
        	$val = shift( @_ );
        }
        my $o = $data->{ $field };
        # $self->message( 3, "Value to use is '$val' and current object is '", ref( $o ), "'." );
        if( ref( $o ) )
        {
        	$o->set( $val );
        }
        else
        {
			$o = Module::Generic::Scalar->new( $val );
			$data->{ $field } = $o;
        }
        # $self->message( 3, "Object now is: '", ref( $data->{ $field } ), "'." );
    }
    # $self->message( 3, "Checking if object '", ref( $data->{ $field } ), "' is set. Is it an object? ", $self->_is_object( $data->{ $field } ) ? 'yes' : 'no', " and its stringified value is '", $data->{ $field }, "'." );
	if( !$self->_is_object( $data->{ $field } ) )
	{
		# $self->message( 3, "No object is set yet, initiating one." );
        my $o = Module::Generic::Scalar->new( $data->{ $field } );
		$data->{ $field } = $o;
	}
	return( $data->{ $field } );
}

sub _set_get_scalar_or_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
    	if( ref( $_[0] ) eq 'HASH' || Scalar::Util::blessed( $_[0] ) )
    	{
    		return( $self->_set_get_object( $field, $class, @_ ) );
    	}
    	else
    	{
    		return( $self->_set_get_scalar( $field, @_ ) );
    	}
    }
	if( !$data->{ $field } && want( 'OBJECT' ) )
	{
		# $self->message( 3, "Called in a chain for field $field and class $class, but no object is set, reverting to dummy object." );
		# $self->messagef( 3, "Expecting void? '%s'. Want scalar? '%s'. Want hash? '%s', wantref: '%s'", want('VOID'), want('SCALAR'), Want::want('HASH'), Want::wantref() );
		my $null = Module::Generic::Null->new( $o, { debug => $this->{debug}, has_error => 1 });
		rreturn( $null );
	}
	return( $data->{ $field } );
}

sub _set_get_uri
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
	my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
    	try
    	{
    		require URI if( !$self->_is_class_loaded( 'URI' ) );
    	}
    	catch( $e )
    	{
    		return( $self->error( "Error trying to load module URI: $e" ) );
    	}
    	
		my $str = shift( @_ );
		if( Scalar::Util::blessed( $str ) && $str->isa( 'URI' ) )
		{
			$data->{ $field } = $str;
		}
		elsif( defined( $str ) && ( $str =~ /^[a-zA-Z]+:\/{2}/ || $str =~ /^urn\:[a-z]+\:/ || $str =~ /^[a-z]+\:/ ) )
		{
			$data->{ $field } = URI->new( $str );
			warn( "URI subclass is missing to handle this specific URI '$str'\n" ) if( !$data->{ $field }->has_recognized_scheme );
		}
		## Is it an absolute path?
		elsif( substr( $str, 0, 1 ) eq '/' )
		{
			$data->{ $field } = URI->new( $str );
		}
		elsif( defined( $str ) )
		{
			return( $self->error( "URI value provided '$str' does not look like an URI, so I do not know what to do with it." ) );
		}
		else
		{
			$data->{ $field } = undef();
		}
    }
    return( $data->{ $field } );
}

sub __dbh
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
	my $this  = $self->_obj2h;
	if( !$this->{ '__dbh' } )
	{
		return( '' ) if( !${ "$class\::DB_DSN" } );
		require DBI;
		## Connecting to database
		my $db_opt = {};
		$db_opt->{RaiseError} = ${ "$class\::DB_RAISE_ERROR" } if( length( ${ "$class\::DB_RAISE_ERROR" } ) );
		$db_opt->{AutoCommit} = ${ "$class\::DB_AUTO_COMMIT" } if( length( ${ "$class\::DB_AUTO_COMMIT" } ) );
		$db_opt->{PrintError} = ${ "$class\::DB_PRINT_ERROR" } if( length( ${ "$class\::DB_PRINT_ERROR" } ) );
		$db_opt->{ShowErrorStatement} = ${ "$class\::DB_SHOW_ERROR_STATEMENT" } if( length( ${ "$class\::DB_SHOW_ERROR_STATEMENT" } ) );
		$db_opt->{client_encoding} = ${ "$class\::DB_CLIENT_ENCODING" } if( length( ${ "$class\::DB_CLIENT_ENCODING" } ) );
		my $dbh = DBI->connect_cached( ${ "$class\::DB_DSN" } ) ||
		die( "Unable to connect to sql database with dsn '", ${ "$class\::DB_DSN" }, "'\n" );
		$dbh->{pg_server_prepare} = 1 if( ${ "$class\::DB_SERVER_PREPARE" } );
		$this->{ '__dbh' } = $dbh;
	}
	return( $this->{ '__dbh' } );
}

sub DEBUG
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
	my $this = $self->_obj2h;
    return( ${ $pkg . '::DEBUG' } );
}

sub VERBOSE
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
	my $this = $self->_obj2h;
    return( ${ $pkg . '::VERBOSE' } );
}

AUTOLOAD
{
    my $self;
    # $self = shift( @_ ) if( ref( $_[ 0 ] ) && index( ref( $_[ 0 ] ), 'Module::' ) != -1 );
    $self = shift( @_ ) if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic' ) );
    my( $class, $meth );
    $class = ref( $self ) || $self;
    ## Leave this commented out as we need it a little bit lower
    my( $pkg, $file, $line ) = caller();
    my $sub = ( caller( 1 ) )[ 3 ];
    no overloading;
    if( $sub eq 'Module::Generic::AUTOLOAD' )
    {
    	my $mesg = "Module::Generic::AUTOLOAD (called at line '$line') is looping for autoloadable method '$AUTOLOAD' and args '" . join( "', '", @_ ) . "'.";
        if( $MOD_PERL )
        {
        	my $r = Apache2::RequestUtil->request;
        	$r->log_error( $mesg );
        }
        else
        {
			print( $err $mesg, "\n" );
        }
        exit( 0 );
    }
    $meth = $AUTOLOAD;
    if( CORE::index( $meth, '::' ) != -1 )
    {
        my $idx = rindex( $meth, '::' );
        $class = substr( $meth, 0, $idx );
        $meth  = substr( $meth, $idx + 2 );
    }
    
    if( $self && $self->can( 'autoload' ) )
    {
    	if( my $code = $self->autoload( $meth ) )
    	{
    		return( $code->( $self ) ) if( $code );
    	}
    }
    
    $meth = lc( $meth );
    my $this;
    $this = $self->_obj2h if( defined( $self ) );
    my $data;
    if( $this )
    {
		$data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    }
    ## CORE::print( STDERR "Storing '$meth' with value ", join( ', ', @_ ), "\n" );
    if( $data && CORE::exists( $data->{ $meth } ) )
    {
        if( @_ )
        {
            my $val = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
            $data->{ $meth } = $val;
        }
        if( wantarray() )
        {
            if( ref( $data->{ $meth } ) eq 'ARRAY' )
            {
                return( @{ $data->{ $meth } } );
            }
            elsif( ref( $data->{ $meth } ) eq 'HASH' )
            {
                return( %{ $data->{ $meth } } );
            }
            else
            {
                return( ( $data->{ $meth } ) );
            }
        }
        else
        {
            return( $data->{ $meth } );
        }
    }
    ## Because, if it does not exist in the caller's package, 
    ## calling the method will get us here infinitly,
    ## since UNIVERSAL::can will somehow return true even if it does not exist
    elsif( $self && $self->can( $meth ) && defined( &{ "$class\::$meth" } ) )
    {
        return( $self->$meth( @_ ) );
    }
    elsif( defined( &$meth ) )
    {
        no strict 'refs';
        *$meth = \&$meth;
        return( &$meth( @_ ) );
    }
    else
    {
        my $sub = $AUTOLOAD;
        my( $pkg, $func ) = ( $sub =~ /(.*)::([^:]+)$/ );
        my $mesg = "Module::Generic::AUTOLOAD(): Searching for routine '$func' from package '$pkg'.";
        if( $MOD_PERL )
        {
        	my $r = Apache2::RequestUtil->request;
        	$r->log_error( $mesg );
        }
        else
        {
			print( STDERR $mesg . "\n" ) if( $DEBUG );
        }
        $pkg =~ s/::/\//g;
        if( defined( $filename = $INC{ "$pkg.pm" } ) )
        {
            $filename =~ s/^(.*)$pkg\.pm\z/$1auto\/$pkg\/$func.al/s;
            ## print( STDERR "Found possible autoloadable file '$filename'.\n" );
            if( -r( $filename ) )
            {
                unless( $filename =~ m|^/|s )
                {
                    $filename = "./$filename";
                }
            }
            else
            {
                $filename = undef();
            }
        }
        if( !defined( $filename ) )
        {
            $filename = "auto/$sub.al";
            $filename =~ s/::/\//g;
        }
        my $save = $@;
        eval
        {
            local $SIG{ '__DIE__' }  = sub{ };
            local $SIG{ '__WARN__' } = sub{ };
            require $filename;
        };
        if( $@ )
        {
            if( substr( $sub, -9 ) eq '::DESTROY' )
            {
                *$sub = sub {};
            }
            else
            {
                # The load might just have failed because the filename was too
                # long for some old SVR3 systems which treat long names as errors.
                # If we can succesfully truncate a long name then it's worth a go.
                # There is a slight risk that we could pick up the wrong file here
                # but autosplit should have warned about that when splitting.
                if( $filename =~ s/(\w{12,})\.al$/substr( $1, 0, 11 ) . ".al"/e )
                {
                    eval
                    {
                        local $SIG{ '__DIE__' }  = sub{ };
                        local $SIG{ '__WARN__' } = sub{ };
                        require $filename
                    };
                }
                if( $@ )
                {
                    #$@ =~ s/ at .*\n//;
                    #my $error = $@;
                    #CORE::die( $error );
                    ## die( "Method $meth() is not defined in class $class and not autoloadable.\n" );
                    ## print( $err "EXTRA_AUTOLOAD is ", defined( &{ "${class}::EXTRA_AUTOLOAD" } ) ? "defined" : "not defined", " in package '$class'.\n" );
                    ## if( $self && defined( &{ "${class}::EXTRA_AUTOLOAD" } ) )
                    ## Look up in our caller's @ISA to see if there is any package that has this special
                    ## EXTRA_AUTOLOAD() sub routine
                    my $sub_ref = '';
                    die( "EXTRA_AUTOLOAD: ", join( "', '", @_ ), "\n" ) if( $func eq 'EXTRA_AUTOLOAD' );
                    if( $self && $func ne 'EXTRA_AUTOLOAD' && ( $sub_ref = $self->will( 'EXTRA_AUTOLOAD' ) ) )
                    {
                        ## return( &{ "${class}::EXTRA_AUTOLOAD" }( $self, $meth ) );
                        ## return( $self->EXTRA_AUTOLOAD( $AUTOLOAD, @_ ) );
                        return( $sub_ref->( $self, $AUTOLOAD, @_ ) );
                    }
                    else
                    {
						my $keys = CORE::join( ',', keys( %$data ) );
						my $msg  = "Method $func() is not defined in class $class and not autoloadable in package $pkg in file $file at line $line.\n";
						$msg    .= "There are actually the following fields in the object '$self': '$keys'\n";
						die( $msg );
                    }
                }
            }
        }
        $@ = $save;
        if( $DEBUG )
        {
        	my $mesg = "unshifting '$self' to args for sub '$sub'.";
			if( $MOD_PERL )
			{
				my $r = Apache2::RequestUtil->request;
				$r->log_error( $mesg );
			}
			else
			{
				print( $err "$mesg\n" );
			}
        }
        unshift( @_, $self ) if( $self );
        #use overloading;
        goto &$sub;
        ## die( "Method $meth() is not defined in class $class and not autoloadable.\n" );
        ## my $mesg = "Method $meth() is not defined in class $class and not autoloadable.";
        ## $self->{ 'fatal' } ? die( $mesg ) : return( $self->error( $mesg ) );
    }
};

DESTROY
{
    ## Do nothing
};

package Module::Generic::Exception;
BEGIN
{
	use strict;
	use parent qw( Module::Generic );
	use Scalar::Util;
	use Devel::StackTrace;
	use overload ('""'     => 'as_string',
				  '=='     => sub { _obj_eq(@_) },
				  '!='     => sub { !_obj_eq(@_) },
				  fallback => 1,
				 );
	our( $VERSION ) = '0.1';
};

sub init
{
	my $self = shift( @_ );
	# require Data::Dumper::Concise;
	# print( STDERR __PACKAGE__, "::init() Got here with args: ", Data::Dumper::Concise::Dumper( \@_ ), "\n" );
	$self->{code} = '';
	$self->{type} = '';
	$self->{file} = '';
	$self->{line} = '';
	$self->{message} = '';
	$self->{package} = '';
	$self->{retry_after} = '';
	$self->{subroutine} = '';
	my $args = {};
	if( @_ )
	{
		if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) )
		{
			$args->{object} = shift( @_ );
		}
		elsif( ref( $_[0] ) eq 'HASH' )
		{
			$args  = shift( @_ );
		}
		else
		{
			$args->{message} = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
		}
	}
	# $self->SUPER::init( @_ );
	my $skip_frame = $args->{skip_frames} || 0;
	## Skip one frame to exclude us
	$skip_frame++;
    my $trace = Devel::StackTrace->new( skip_frames => $skip_frame, indent => 1 );
    my $frame = $trace->next_frame;
    my $frame2 = $trace->next_frame;
    $trace->reset_pointer;
    if( ref( $args->{object} ) && Scalar::Util::blessed( $args->{object} ) && $args->{object}->isa( 'Module::Generic::Exception' ) )
    {
    	my $o = $args->{object};
		$self->{message} = $o->message;
		$self->{code} = $o->code;
		$self->{type} = $o->type;
		$self->{retry_after} = $o->retry_after;
    }
    else
    {
		# print( STDERR __PACKAGE__, "::init() Got here with args: ", Data::Dumper::Concise::Dumper( $args ), "\n" );
		$self->{message} = $args->{message} || '';
		$self->{code} = $args->{code} if( exists( $args->{code} ) );
		$self->{type} = $args->{type} if( exists( $args->{type} ) );
		$self->{retry_after} = $args->{retry_after} if( exists( $args->{retry_after} ) );
		## I do not want to alter the original hash reference, which may adversely affect the calling code if they depend on its content for further execution for example.
		my $copy = {};
		%$copy = %$args;
		CORE::delete( @$copy{ qw( message code type retry_after skip_frames ) } );
		# print( STDERR __PACKAGE__, "::init() Following non-standard keys to set up: '", join( "', '", sort( keys( %$copy ) ) ), "'\n" );
		## Do we have some non-standard parameters?
		foreach my $p ( keys( %$copy ) )
		{
			my $p2 = $p;
			$p2 =~ tr/-/_/;
			$p2 =~ s/[^a-zA-Z0-9\_]+//g;
			$p2 =~ s/^\d+//g;
			$self->$p2( $copy->{ $p } );
		}
    }
    $self->{file} = $frame->filename;
	$self->{line} = $frame->line;
	## The caller sub routine ( caller( n ) )[3] returns the sub called by our caller instead of the sub that called our caller, so we go one frame back to get it
	$self->{subroutine} = $frame2->subroutine;
	$self->{package} = $frame->package;
	$self->{trace} = $trace;
	return( $self );
}

#sub as_string { return( $_[0]->{message} ); }
## This is important as stringification is called by die, so as per the manual page, we need to end with new line
## And will add the stack trace
sub as_string
{
	no overloading;
	my $self = shift( @_ );
	my $str = $self->message;
	$str =~ s/\r?\n$//g;
	$str .= sprintf( " within package %s at line %d in file %s\n%s", $self->package, $self->line, $self->file, $self->trace->as_string );
	return( $str );
}

sub caught 
{
    my( $class, $e ) = @_;
    return if( ref( $class ) );
    return unless( Scalar::Util::blessed( $e ) && $e->isa( $class ) );
    return( $e );
}

sub code { return( shift->_set_get_scalar( 'code', @_ ) ); }

sub file { return( shift->_set_get_scalar( 'file', @_ ) ); }

sub line { return( shift->_set_get_scalar( 'line', @_ ) ); }

sub message { return( shift->_set_get_scalar( 'message', @_ ) ); }

sub package { return( shift->_set_get_scalar( 'package', @_ ) ); }

sub rethrow 
{
	my $self = shift( @_ );
	return if( !Scalar::Util::blessed( $self ) );
	die( $self );
}

sub retry_after { return( shift->_set_get_scalar( 'retry_after', @_ ) ); }

sub subroutine { return( shift->_set_get_scalar( 'subroutine', @_ ) ); }

sub throw
{
    my $self = shift( @_ );
    my $msg  = shift( @_ );
    my $e = $self->new({
    	skip_frames => 1,
    	message => $msg,
    });
    die( $e );
}

## Devel::StackTrace has a stringification overloaded so users can use the object to get more information or simply use it as a string to get the stack trace equivalent of doing $trace->as_string
sub trace { return( shift->_set_get_object( 'trace', 'Devel::StackTrace', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub _obj_eq 
{
    ##return overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] );
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $me;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Exception' ) )
    {
    	if( $self->message eq $other->message &&
    		$self->file eq $other->file &&
    		$self->line == $other->line )
    	{
    		return( 1 );
    	}
    	else
    	{
    		return( 0 );
    	}
    }
    ## Compare error message
    elsif( !ref( $other ) )
    {
    	my $me = $self->message;
    	return( $me eq $other );
    }
    ## Otherwise some reference data to which we cannot compare
    return( 0 ) ;
}

AUTOLOAD
{
	my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
	# my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
	no overloading;
	my $self = shift( @_ );
	my $class = ref( $self ) || $self;
	my $code;
	# print( STDERR __PACKAGE__, "::$method(): Called with value '$_[0]'\n" );
	if( $code = $self->can( $method ) )
	{
		return( $code->( @_ ) );
	}
	## elsif( CORE::exists( $self->{ $method } ) )
	else
	{
		eval( "sub ${class}::${method} { return( shift->_set_get_scalar( '$method', \@_ ) ); }" );
		die( $@ ) if( $@ );
		return( $self->$method( @_ ) );
	}
};

## Purpose of this package is to provide an object that will be invoked in chain without breaking and then return undef at the end
## Normally if a method in the chain returns undef, perl will then complain that the following method in the chain was called on an undefined value. This Null package alleviate this problem.
## This is an original idea from https://stackoverflow.com/users/2766176/brian-d-foy as document in this Stackoverflow thread here: https://stackoverflow.com/a/7068271/4814971
## And also by user "particle" in this perl monks discussion here: https://www.perlmonks.org/?node_id=265214
package Module::Generic::Null;
BEGIN
{
	use strict;
	use Want;
	use overload ('""'     => sub{ '' },
				  'eq'     => sub { _obj_eq(@_) },
				  'ne'     => sub { !_obj_eq(@_) },
				  fallback => 1,
				 );
	our( $VERSION ) = '0.2';
};

sub new
{
	my $this = shift( @_ );
	my $class = ref( $this ) || $this;
	my $error_object = shift( @_ );
	my $hash = ( @_ == 1 && ref( $_[0] ) ? shift( @_ ) : { @_ } );
	$hash->{has_error} = $error_object;
	return( bless( $hash => $class ) );
}

sub _obj_eq 
{
    ##return overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] );
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $me;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Null' ) )
    {
    	return( $self eq $other );
    }
    ## Compare error message
    elsif( !ref( $other ) )
    {
    	return( '' eq $other );
    }
    ## Otherwise some reference data to which we cannot compare
    return( 0 ) ;
}

AUTOLOAD
{
	my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
	# my $debug = $_[0]->{debug};
	# my( $pack, $file, $file ) = caller;
	# my $sub = ( caller( 1 ) )[3];
	# print( STDERR __PACKAGE__, ": Method $method called in package $pack in file $file at line $line from subroutine $sub (AUTOLOAD = $AUTOLOAD)\n" ) if( $debug );
	## If we are chained, return our null object, so the chain continues to work
	if( want( 'OBJECT' ) )
	{
		## No, this is NOT a typo. rreturn() is a function of module Want
		rreturn( $_[0] );
	}
	## Otherwise, we return undef; Empty return returns undef in scalar context and empty list in list context
	return;
};

DESTROY {};

package Module::Generic::Dynamic;
BEGIN
{
	use strict;
	use parent qw( Module::Generic );
	use Scalar::Util ();
	# use Class::ISA;
	our( $VERSION ) = '0.1';
};

sub new
{
	my $this = shift( @_ );
	my $class = ref( $this ) || $this;
	my $self = bless( {} => $class );
	my $data = $self->{_data} = {};
	## A Module::Generic object standard parameter
	$self->{_data_repo} = '_data';
	my $hash = {};
	$hash = shift( @_ ) if( scalar( @_ ) && ref( $_[0] ) eq 'HASH' );
	## print( STDERR __PACKAGE__, "::new(): Got for hash: '", join( "', '", sort( keys( %$hash ) ) ), "'\n" );
	local $make_class = sub
	{
		my $k = shift( @_ );
		my $new_class = $k;
		$new_class =~ tr/-/_/;
		$new_class =~ s/\_{2,}/_/g;
		$new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
		$new_class = "${class}\::${new_class}";
		## Sanitise the key which will serve as a method name
		my $clean_field = $k;
		$clean_field =~ tr/-/_/;
		$clean_field =~ s/\_{2,}/_/g;
		$clean_field =~ s/[^a-zA-Z0-9\_]+//g;
		$clean_field =~ s/^\d+//g;
		## print( STDERR __PACKAGE__, "::new(): \$clean_field now is '$clean_field'\n" );
		my $perl = <<EOT;
package $new_class;
BEGIN
{
	use strict;
	use Module::Generic;
	use parent -norequire, qw( Module::Generic::Dynamic );
};

1;

EOT
		# print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Evaluating\n$perl\n" );
		my $rc = eval( $perl );
		# print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
		die( "Unable to dynamically create module $new_class: $@" ) if( $@ );
		return( $new_class, $clean_field );
	};
	
	foreach my $k ( sort( keys( %$hash ) ) )
	{
		if( ref( $hash->{ $k } ) eq 'HASH' )
		{
			my( $new_class, $clean_field ) = $make_class->( $k );
			# print( STDERR __PACKAGE__, "::new(): Is hash looping? ", ( $hash->{ $k }->{_looping} ? 'yes' : 'no' ), " (", ref( $hash->{ $k }->{_looping} ), ")\n" );
			my $o = $hash->{ $k }->{_looping} ? $hash->{ $k }->{_looping} : $new_class->new( $hash->{ $k } );
			$data->{ $clean_field } = $o;
			$hash->{ $k }->{_looping} = $o;
			eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object( $clean_field, '$new_class', \@_ ) ); }" );
			die( $@ ) if( $@ );
		}
		elsif( ref( $hash->{ $k } ) eq 'ARRAY' )
		{
			my( $new_class, $clean_field ) = $make_class->( $k );
			# print( STDERR __PACKAGE__, "::new() found an array for key $k, creating objects for class $new_class\n" );
			## We take a peek at what we have to determine how we will handle the data
			my $mode = lc( scalar( @{$hash->{ $k }} ) ? ref( $hash->{ $k }->[0] ) : '' );
			if( $mode eq 'hash' )
			{
				my $all = [];
				foreach my $this ( @{$hash->{ $k }} )
				{
					my $o = $this->{_looping} ? $this->{_looping} : $new_class->new( $this );
					$this->{_looping} = $o;
					CORE::push( @$all, $o );
				}
				$data->{ $clean_field } = $all;
				eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object_array( '$clean_field', '$new_class', \@_ ) ); }" );
			}
			else
			{
				$data->{ $clean_field } = $hash->{ $k };
				eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_array( '$clean_field', \@_ ) ); }" );
			}
		}
		else
		{
			$self->$k( $hash->{ $k } );
		}
	}
	return( $self );
}

AUTOLOAD
{
	my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
	# my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
	no overloading;
	my $self = shift( @_ );
	my $class = ref( $self ) || $self;
	my $code;
	# print( STDERR __PACKAGE__, "::$method(): Called\n" );
	if( $code = $self->can( $method ) )
	{
		return( $code->( @_ ) );
	}
	## elsif( CORE::exists( $self->{ $method } ) )
	else
	{
		my $ref = lc( ref( $_[0] ) );
		my $handler = '_set_get_scalar';
		# if( @_ && ( $ref eq 'hash' || $ref eq 'array' ) )
		if( $ref eq 'hash' || $ref eq 'array' )
		{
			# print( STDERR __PACKAGE__, "::$method(): using handler $handler for type $ref\n" );
			$handler = "_set_get_${ref}";
		}
		elsif( $ref eq 'json::pp::boolean' || 
			$ref eq 'module::generic::boolean' ||
			( $ref eq 'scalar' && ( $$ref == 1 || $$ref == 0 ) ) )
		{
			$handler = '_set_get_boolean';
		}
		eval( "sub ${class}::${method} { return( shift->$handler( '$method', \@_ ) ); }" );
		die( $@ ) if( $@ );
		return( $self->$method( @_ ) );
	}
};

package Module::Generic::Boolean;
BEGIN
{
	use common::sense;
	use overload
      "0+"     => sub { ${$_[0]} },
      "++"     => sub { $_[0] = ${$_[0]} + 1 },
      "--"     => sub { $_[0] = ${$_[0]} - 1 },
      fallback => 1;
	# *Module::Generic::Boolean:: = *JSON::PP::Boolean::;
	our( $VERSION ) = '0.1';
};

our $true  = do{ bless( \( my $dummy = 1 ) => Module::Generic::Boolean ) };
our $false = do{ bless( \( my $dummy = 0 ) => Module::Generic::Boolean ) };

sub true  () { $true  }
sub false () { $false }

sub is_bool  ($) {           UNIVERSAL::isa( $_[0], Module::Generic::Boolean ) }
sub is_true  ($) {  $_[0] && UNIVERSAL::isa( $_[0], Module::Generic::Boolean ) }
sub is_false ($) { !$_[0] && UNIVERSAL::isa( $_[0], Module::Generic::Boolean ) }

sub TO_JSON
{
	## JSON does not check that the value is a proper true or false. It stupidly assumes this is a string
	## The only way to make it understand is to return a scalar ref of 1 or 0
	# return( $_[0] ? 'true' : 'false' );
	return( $_[0] ? \1 : \0 );
}

package Module::Generic::Array;
BEGIN
{
	use common::sense;
	use Scalar::Util ();
	our( $VERSION ) = '0.1';
};

sub new
{
	my $this = CORE::shift( @_ );
	my $init = [];
	$init = CORE::shift( @_ ) if( @_ && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) );
	return( bless( $init => ( ref( $this ) || $this ) ) );
}

sub as_hash
{
	my $self = CORE::shift( @_ );
	my $ref = {};
	my( @offsets ) = $self->keys;
	@$ref{ @$self } = @offsets;
	return( $ref );
}

sub delete
{
	my $self = CORE::shift( @_ );
	my( $offset, $length ) = @_;
	if( defined( $offset ) )
	{
		my @removed = CORE::splice( @$self, $offset, defined( $length ) ? int( $length ) : 1 );
		return( wantarray() ? @removed : $self->new( \@removed ) );
	}
	return;
}

sub each
{
	my $self = CORE::shift( @_ );
	return( CORE::each( @$self ) );
}

sub exists
{
	my $self = CORE::shift( @_ );
	my $this = shift( @_ );
	return( scalar( CORE::grep( /^$this$/, @$self ) ) );
}

sub for
{
	my $self = CORE::shift( @_ );
	my $code = shift( @_ );
	return if( ref( $code ) ne 'CODE' );
	CORE::for( my $i; $i < scalar( @$self ); $i++ )
	{
		$code->( $i, $self->[ $i ] );
	}
	return( $self );
}

sub foreach
{
	my $self = CORE::shift( @_ );
	my $code = shift( @_ );
	return if( ref( $code ) ne 'CODE' );
	CORE::foreach my $v ( @$self )
	{
		$code->( $v );
	}
	return( $self );
}

sub grep
{
	my $self = CORE::shift( @_ );
	my $ref = [ CORE::grep( $_[0], @$self ) ];
	if( wantarray() )
	{
		return( @$ref );
	}
	else
	{
		return( $self->new( $ref ) );
	}
}

sub join
{
	my $self = CORE::shift( @_ );
	return( CORE::join( $_[0], @$self ) );
}

sub keys
{
	my $self = CORE::shift( @_ );
	return( CORE::keys( @$self ) );
}

sub length { return( scalar( @{$_[0]} ) ); }

sub map
{
	my $self = CORE::shift( @_ );
	my $code = shift( @_ );
	return if( ref( $code ) ne 'CODE' );
	return( CORE::map( $code->( $_ ), @$self ) );
}

sub pop
{
	my $self = CORE::shift( @_ );
	return( CORE::pop( @$self ) );
}

sub push
{
	my $self = CORE::shift( @_ );
	return( CORE::push( @$self, @_ ) );
}

sub push_arrayref
{
	my $self = CORE::shift( @_ );
	my $ref = CORE::shift( @_ );
	return( $self->error( "Data provided ($ref) is not an array reference." ) ) if( !UNIVERSAL::isa( $ref, 'ARRAY' ) );
	return( CORE::push( @$self, @$ref ) );
}

sub reset
{
	my $self = CORE::shift( @_ );
	@$self = ();
	return( $self );
}

sub reverse
{
	my $self = CORE::shift( @_ );
	my $ref = [ CORE::reverse( @$self ) ];
	if( wantarray() )
	{
		return( @$ref );
	}
	else
	{
		return( $self->new( $ref ) );
	}
}

sub set
{
	my $self = CORE::shift( @_ );
	my $ref = ( scalar( @_ ) == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? CORE::shift( @_ ) : [ @_ ];
	@$self = @$ref;
	return( $self );
}

sub shift
{
	my $self = CORE::shift( @_ );
	return( CORE::shift( @$self ) );
}

sub size { return( shift->length ); }

sub sort
{
	my $self = CORE::shift( @_ );
	my $ref = [ CORE::sort( @$self ) ];
	if( wantarray() )
	{
		return( @$ref );
	}
	else
	{
		return( $self->new( $ref ) );
	}
}

sub splice
{
	my $self = CORE::shift( @_ );
	return( CORE::splice( @$self, @_ ) );
}

sub split
{
	my $self = CORE::shift( @_ );
	my $ref = [ CORE::split( @_ ) ];
	if( wantarray() )
	{
		return( @$ref );
	}
	else
	{
		return( $self->new( $ref ) );
	}
}

sub undef
{
	my $self = CORE::shift( @_ );
	@$self = ();
	return( $self );
}

sub unshift
{
	my $self = CORE::shift( @_ );
	return( CORE::unshift( @$self, @_ ) );
}

sub values
{
	my $self = CORE::shift( @_ );
	my $ref = [ CORE::values( @$self ) ];
	if( wantarray() )
	{
		return( @$ref );
	}
	else
	{
		return( $self->new( $ref ) );
	}
}

package Module::Generic::Scalar;
BEGIN
{
	use common::sense;
	use Scalar::Util ();
	use overload ('""'     => 'as_string',
				  fallback => 1,
				 );
	our( $VERSION ) = '0.1';
};

sub new
{
	my $this = CORE::shift( @_ );
	my $init = '';
	if( ref( $_[0] ) eq 'SCALAR' || UNIVERSAL::isa( $_[0], 'SCALAR' ) )
	{
		$init = ${$_[0]};
	}
	elsif( ref( $_[0] ) eq 'ARRAY' || UNIVERSAL::isa( $_[0], 'ARRAY' ) )
	{
		$init = CORE::join( '', @{$_[0]} );
	}
	elsif( ref( $_[0] ) )
	{
		warn( "I do not know what to do with \"", $_[0], "\"\n" );
		return;
	}
	else
	{
		$init = shift( @_ );
	}
	return( bless( \$init => ( ref( $this ) || $this ) ) );
}

sub as_string { return( ${$_[0]} ); }

sub hex { return( CORE::hex( ${$_[0]} ) ); }

sub index
{
	my $self = shift( @_ );
	my( $substr, $pos ) = @_;
	return( CORE::index( ${$self}, $substr, $pos ) ) if( CORE::defined( $pos ) );
	return( CORE::index( ${$self}, $substr ) );
}

sub lc { return( __PACKAGE__->new( CORE::lc( ${$_[0]} ) ) ); }

sub lcfirst { return( __PACKAGE__->new( CORE::lcfirst( ${$_[0]} ) ) ); }

sub length { return( CORE::length( ${$_[0]} ) ); }

sub ord { return( CORE::ord( ${$_[0]} ) ); }

sub quotemeta { return( __PACKAGE__->new( CORE::quotemeta( ${$_[0]} ) ) ); }

sub reset { ${$_[0]} = ''; return( $_[0] ); }

sub reverse { return( __PACKAGE__->new( scalar( CORE::reverse( ${$_[0]} ) ) ) ); }

sub rindex
{
	my $self = shift( @_ );
	my( $substr, $pos ) = @_;
	return( CORE::rindex( ${$self}, $substr, $pos ) ) if( CORE::defined( $pos ) );
	return( CORE::rindex( ${$self}, $substr ) );
}

sub set
{
	my $self = CORE::shift( @_ );
	my $init;
	if( ref( $_[0] ) eq 'SCALAR' || UNIVERSAL::isa( $_[0], 'SCALAR' ) )
	{
		$init = ${$_[0]};
	}
	elsif( ref( $_[0] ) eq 'ARRAY' || UNIVERSAL::isa( $_[0], 'ARRAY' ) )
	{
		$init = CORE::join( '', @{$_[0]} );
	}
	elsif( ref( $_[0] ) )
	{
		warn( "I do not know what to do with \"", $_[0], "\"\n" );
		return;
	}
	else
	{
		$init = shift( @_ );
	}
	$$self = $init;
	return( $self );
}

sub split { return( CORE::split( $_[1], ${$_[0]} ) ); }

sub sprintf { return( __PACKAGE__->new( CORE::sprintf( ${$_[0]}, @_[1..$#_] ) ) ); }

sub substr
{
	my $self = CORE::shift( @_ );
	my( $offset, $length, $replacement ) = @_;
	return( __PACKAGE__->new( CORE::substr( ${$self}, $offset, $length, $replace ) ) ) if( CORE::defined( $length ) && CORE::defined( $replacement ) );
	return( __PACKAGE__->new( CORE::substr( ${$self}, $offset, $length ) ) ) if( CORE::defined( $length ) );
	return( __PACKAGE__->new( CORE::substr( ${$self}, $offset ) ) );
}

sub uc { return( __PACKAGE__->new( CORE::uc( ${$_[0]} ) ) ); }

sub ucfirst { return( __PACKAGE__->new( CORE::ucfirst( ${$_[0]} ) ) ); }

package Module::Generic::Tie;
use Tie::Hash;
our( @ISA ) = qw( Tie::Hash );

sub TIEHASH
{
    my $self = shift( @_ );
    my $pkg  = ( caller() )[ 0 ];
    ## print( STDERR __PACKAGE__ . "::TIEHASH() called with following arguments: '", join( ', ', @_ ), "'.\n" );
    my %arg  = ( @_ );
    my $auth = [ $pkg, __PACKAGE__ ];
    if( $arg{ 'pkg' } )
    {
        my $ok = delete( $arg{ 'pkg' } );
        push( @$auth, ref( $ok ) eq 'ARRAY' ? @$ok : $ok );
    }
    my $priv = { 'pkg' => $auth };
    my $data = { '__priv__' => $priv };
    my @keys = keys( %arg );
    @$priv{ @keys } = @arg{ @keys };
    return( bless( $data, ref( $self ) || $self ) );
}

sub CLEAR
{
    my $self = shift( @_ );
    my $pkg = ( caller() )[ 0 ];
    ## print( $err __PACKAGE__ . "::CLEAR() called by package '$pkg'.\n" );
    my $data = $self->{ '__priv__' };
    return() if( $data->{ 'readonly' } && $pkg ne __PACKAGE__ );
    ## if( $data->{ 'readonly' } || $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 2 ) )
    {
        return() if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    my $key  = $self->FIRSTKEY( @_ );
    my @keys = ();
    while( defined( $key ) )
    {
        push( @keys, $key );
        $key = $self->NEXTKEY( @_, $key );
    }
    foreach $key ( @keys )
    {
        $self->DELETE( @_, $key );
    }
}

sub DELETE
{
    my $self = shift( @_ );
    my $pkg  = ( caller() )[ 0 ];
    $pkg     = ( caller( 1 ) )[ 0 ] if( $pkg eq 'Module::Generic' );
    ## print( STDERR __PACKAGE__ . "::DELETE() package '$pkg' tries to delete '$_[ 0 ]'\n" );
    my $data = $self->{ '__priv__' };
    return() if( $_[ 0 ] eq '__priv__' && $pkg ne __PACKAGE__ );
    ## if( $data->{ 'readonly' } || $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 2 ) )
    {
        return() if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    return( delete( $self->{ shift( @_ ) } ) );
}

sub EXISTS
{
    my $self = shift( @_ );
    ## print( STDERR __PACKAGE__ . "::EXISTS() called from package '", ( caller() )[ 0 ], "'.\n" );
    return( 0 ) if( $_[ 0 ] eq '__priv__' && $pkg ne __PACKAGE__ );
    my $data = $self->{ '__priv__' };
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller() )[ 0 ];
        return( 0 ) if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    ## print( STDERR __PACKAGE__ . "::EXISTS() returns: '", exists( $self->{ $_[ 0 ] } ), "'.\n" );
    return( exists( $self->{ shift( @_ ) } ) );
}

sub FETCH
{
    ## return( shift->{ shift( @_ ) } );
    ## print( STDERR __PACKAGE__ . "::FETCH() called with arguments: '", join( ', ', @_ ), "'.\n" );
    my $self = shift( @_ );
    ## This is a hidden entry, we return nothing
    return() if( $_[ 0 ] eq '__priv__' && $pkg ne __PACKAGE__ );
    my $data = $self->{ '__priv__' };
    ## If we have to protect our object, we hide its inner content if our caller is not our creator
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller() )[ 0 ];
        ## print( STDERR __PACKAGE__ . "::FETCH() package '$pkg' wants to fetch the value of '$_[ 0 ]'\n" );
        return() if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    return( $self->{ shift( @_ ) } );
}

sub FIRSTKEY
{
    my $self = shift( @_ );
    ## my $a    = scalar( keys( %$hash ) );
    ## return( each( %$hash ) );
    my $data = $self->{ '__priv__' };
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller( 0 ) )[ 0 ];
        ## print( STDERR __PACKAGE__ . "::FIRSTKEY() called by package '$pkg'\n" );
        return() if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    ## print( STDERR __PACKAGE__ . "::FIRSTKEY(): gathering object's keys.\n" );
    my( @keys ) = grep( !/^__priv__$/, keys( %$self ) );
    $self->{ '__priv__' }->{ 'ITERATOR' } = \@keys;
    ## print( STDERR __PACKAGE__ . "::FIRSTKEY(): keys are: '", join( ', ', @keys ), "'.\n" );
    ## print( STDERR __PACKAGE__ . "::FIRSTKEY() returns '$keys[ 0 ]'.\n" );
    return( shift( @keys ) );
}

sub NEXTKEY
{
    my $self = shift( @_ );
    ## return( each( %$hash ) );
    my $data = $self->{ '__priv__' };
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller( 0 ) )[ 0 ];
        ## print( STDERR __PACKAGE__ . "::NEXTKEY() called by package '$pkg'\n" );
        return() if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    my $keys = $self->{ '__priv__' }->{ 'ITERATOR' };
    ## print( STDERR __PACKAGE__ . "::NEXTKEY() returns '$_[ 0 ]'.\n" );
    return( shift( @$keys ) );
}

sub STORE
{
    my $self = shift( @_ );
    return() if( $_[ 0 ] eq '__priv__' );
    my $data = $self->{ '__priv__' };
    #if( $data->{ 'readonly' } || 
    #    $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 2 ) )
    {
        my $pkg  = ( caller() )[ 0 ];
        $pkg     = ( caller( 1 ) )[ 0 ] if( $pkg eq 'Module::Generic' );
        ## print( STDERR __PACKAGE__ . "::STORE() package '$pkg' is trying to STORE the value '$_[ 1 ]' to key '$_[ 0 ]'\n" );
        return() if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    ## print( STDERR __PACKAGE__ . "::STORE() ", ( caller() )[ 0 ], " is storing value '$_[ 1 ]' for key '$_[ 0 ]'.\n" );
    ## $self->{ shift( @_ ) } = shift( @_ );
    $self->{ $_[ 0 ] } = $_[ 1 ];
    ## print( STDERR __PACKAGE__ . "::STORE(): object '$self' now contains: '", join( ', ', map{ "$_, $self->{ $_ }" } keys( %$self ) ), "'.\n" );
}

1;

__END__

=encoding utf8

=head1 NAME

Module::Generic - Generic Module to inherit from

=head1 SYNOPSIS

    package MyModule;
    BEGIN
    {
        use strict;
        use Module::Generic;
        our( @ISA ) = qw( Module::Generic );
    };

=head1 VERSION

    v0.11.6

=head1 DESCRIPTION

C<Module::Generic> as its name says it all, is a generic module to inherit from.
It contains standard methods that may howerver be bypassed by the module using 
C<Module::Generic>.

As an added benefit, it also contains a powerfull AUTOLOAD transforming any hash 
object key into dynamic methods and also recognize the dynamic routine a la AutoLoader
from which I have shamelessly copied in the AUTOLOAD code. The reason is that while
C<AutoLoader> provides the user with a convenient AUTOLOAD, I wanted a way to also
keep the functionnality of C<Module::Generic> AUTOLOAD that were not included in
C<AutoLoader>. So the only solution was a merger.

=head1 METHODS

=over 4

=item B<import>()

B<import>() is used for the AutoLoader mechanism and hence is not a public method.
It is just mentionned here for info only.

=item B<new>()

B<new>() will create a new object for the package, pass any argument it might receive
to the special standard routine B<init> that I<must> exist. 
Then it returns what returns B<init>().

To protect object inner content from sneaking by thrid party, you can declare the 
package global variable I<OBJECT_PERMS> and give it a Unix permission.
It will then work just like Unix permission. That is, if permission is 700, then only the 
module who generated the object may read/write content of the object. However, if
you set 755, the, other may look into the content of the object, but may not modify it.
777, as you would have guessed, allow other to modify the content of an object.
If I<OBJECT_PERMS> is not defined, permissions system is not activated and hence anyone 
may access and possibibly modify the content of your object.

If the module runs under mod_perl, it is recognized and a clean up registered routine is 
declared to Apache to clean up the content of the object.

=item B<clear_error>

Clear all error from the object and from the available global variable C<$ERROR>.

This is a handy method to use at the beginning of other methods of calling package,
so the end user may do a test such as:

    $obj->some_method( 'some arguments' );
    die( $obj->error() ) if( $obj->error() );

    ## some_method() would then contain something like:
    sub some_method
    {
        my $self = shift( @_ );
        ## Clear all previous error, so we may set our own later one eventually
        $self->clear_error();
        ## ...
    }

This way the end user may be sure that if C<$obj->error()> returns true something
wrong has occured.

=item B<error>()

Set the current error, do a warn on it and returns undef():

    if( $some_condition )
    {
        return( $self->error( "Some error." ) );
    }

Note that you do not have to worry about a trailing line feed sequence.
B<error>() takes care of it.

Note also that by calling B<error>() it will not clear the current error. For that
you have to call B<clear_error>() explicitly.

Also, when an error is set, the global variable I<ERROR> is set accordingly. This is
especially usefull, when your initiating an object and that an error occured. At that
time, since the object could not be initiated, the end user can not use the object to 
get the error message, and then can get it using the global module variable 
I<ERROR>, for example:

    my $obj = Some::Package->new ||
    die( $Some::Package::ERROR, "\n" );

=item B<errors>()

Used by B<error>() to store the error sent to him for history.

It returns an array of all error that have occured in lsit context, and the last 
error in scalar context.

=item B<errstr>()

Set/get the error string, period. It does not produce any warning like B<error> would do.

=item B<get>()

Uset to get an object data key value:

    $obj->set( 'verbose' => 1, 'debug' => 0 );
    ## ...
    my $verbose = $obj->get( 'verbose' );
    my @vals = $obj->get( qw( verbose debug ) );
    print( $out "Verbose level is $vals[ 0 ] and debug level is $vals[ 1 ]\n" );

This is no more needed, as it has been more conveniently bypassed by the AUTOLOAD
generic routine with chich you may say:

    $obj->verbose( 1 );
    $obj->debug( 0 );
    ## ...
    my $verbose = $obj->verbose();

Much better, no?

=item B<init>()

This is the B<new>() package object initializer. It is called by B<new>()
and is used to set up any parameter provided in a hash like fashion:

    my $obj My::Module->new( 'verbose' => 1, 'debug' => 0 );

You may want to superseed B<init>() to have suit your needs.

B<init>() needs to returns the object it received in the first place or an error if
something went wrong, such as:

    sub init
    {
        my $self = shift( @_ );
        my $dbh  = DB::Object->connect() ||
        return( $self->error( "Unable to connect to database server." ) );
        $self->{ 'dbh' } = $dbh;
        return( $self );
    }

In this example, using B<error> will set the global variable C<$ERROR> that will
contain the error, so user can say:

    my $obj = My::Module->new() || die( $My::Module::ERROR );

If the global variable I<VERBOSE>, I<DEBUG>, I<VERSION> are defined in the module,
and that they do not exist as an object key, they will be set automatically and
accordingly to those global variable.

The supported data type of the object generated by the B<new> method may either be
a hash reference or a glob reference. Those supported data types may very well be
extended to an array reference in a near future.

=item B<message>()

B<message>() is used to display verbose/debug output. It will display something
to the extend that either I<verbose> or I<debug> are toggled on.

If so, all debugging message will be prepended by C<## > to highlight the fact
that this is a debugging message.

Addionally, if a number is provided as first argument to B<message>(), it will be 
treated as the minimum required level of debugness. So, if the current debug
state level is not equal or superior to the one provided as first argument, the
message will not be displayed.

For example:

    ## Set debugness to 3
    $obj->debug( 3 );
    ## This message will not be printed
    $obj->message( 4, "Some detailed debugging stuff that we might not want." );
    ## This will be displayed
    $obj->message( 2, "Some more common message we want the user to see." );

Now, why debug is used and not verbose level? Well, because mostly, the verbose level
needs only to be true, that is equal to 1 to be efficient. You do not really need to have
a verbose level greater than 1. However, the debug level usually may have various level.

=item B<set>()

B<set>() sets object inner data type and takes arguments in a hash like fashion:

    $obj->set( 'verbose' => 1, 'debug' => 0 );

=item B<subclasses>( [ CLASS ] )

This method try to guess all the existing sub classes of the provided I<CLASS>.

If I<CLASS> is not provided, the class into which was blessed the calling object will
be used instead.

It returns an array of subclasses in list context and a reference to an array of those
subclasses in scalar context.

If an error occured, undef is returned and an error is set accordingly. The latter can
be retrieved using the B<error> method.

=item B<AUTOLOAD>

The special B<AUTOLOAD>() routine is called by perl when no mathing routine was found
in the module.

B<AUTOLOAD>() will then try hard to process the request.
For example, let's assue we have a routine B<foo>.

It will first, check if an equivalent entry of the routine name that was called exist in
the hash reference of the object. If there is and that more than one argument were
passed to this non existing routine, those arguments will be stored as a reference to an
array as a value of the key in the object. Otherwise the single argument will simply be stored
as the value of the key of the object.

Then, if called in list context, it will return a array if the value of the key entry was an array
reference, or a hash list if the value of the key entry was a hash reference, or finally the value
of the key entry.

If this non existing routine that was called is actually defined, the routine will be redeclared and
the arguments passed to it.

If this fails too, it will try to check for an AutoLoadable file in C<auto/PackageName/routine_name.al>

If the filed exists, it will be required, the routine name linked into the package name space and finally
called with the arguments.

If the require process failed or if the AutoLoadable routine file did not exist, B<AUTOLOAD>() will
check if the special routine B<EXTRA_AUTOLOAD>() exists in the module. If it does, it will call it and pass
it the arguments. Otherwise, B<AUTOLOAD> will die with a message explaining that the called routine did 
not exist and could not be found in the current class.

=back

=head1 SPECIAL METHODS

=over 4

=item B<_set_get_class( $field, $struct_hash, @_ )>

Given a field name, a dynamic class fiels definition hash (dictionary), and optional arguments, this special method will create perl packages on the fly.

For example, consider the following:

	#!/usr/local/bin/perl
	BEGIN
	{
		use strict;
		use Data::Dumper;
	};

	{
		my $o = MyClass->new( debug => 3 );
		$o->setup->age( 42 );
		print( "Age is: ", $o->setup->age, "\n" );
		print( "Setup object is: ", $o->setup, "\n" );
		$o->setup->billing->interval( 'month' );
		print( "Billing interval is: ", $o->setup->billing->interval, "\n" );
		print( "Billing object is: ", $o->setup->billing, "\n" );
		$o->setup->rgb( 255, 122, 100 );
		print( "rgb: ", join( ', ', @{$o->setup->rgb} ), "\n" );
		exit( 0 );
	}

	package MyClass;
	BEGIN
	{
		use strict;
		use lib './lib';
		use parent qw( Module::Generic );
	};

	sub setup 
	{
		return( shift->_set_get_class( 'setup',
		{
		name => { type => 'scalar' },
		age => { type => 'number' },
		metadata => { type => 'hash' },
		rgb => { type => 'array' },
		url => { type => 'uri' },
		online => { type => 'boolean' },
		created => { type => 'datetime' },
		billing => { type => 'class', definition =>
			{
			interval => { type => 'scalar' },
			frquency => { type => 'number' },
			nickname => { type => 'scalar' },
			}}
		}) );
	}

	1;

	__END__

This will yield:

	Age is: 42
	Setup object is: MyClass::Setup=HASH(0x7fa805abcb20)
	Billing interval is: month
	Billing object is: MyClass::Setup::Billing=HASH(0x7fa804ec3f40)
	rgb: 255, 122, 100

The advantage of this over B<_set_get_hash_as_object> is that here one controls what fields / method are supported and with which data type.

=item B<_set_get_hash_as_object( $field, '$class_name', @_ )>

Given a field name, a class name and an argument list, this will create dynamically classes so that each key / value pairs can be accessed as methods.

Also it does this recursively while handling looping, in which case, it will reuse the object previously created, and also it takes care of adapting the hash key to a proper field name, so something like C<99more-options> would become C<more_options>. If the value itself is a hash, it processes it recursively transforming C<99more-options> to a proper package name C<MoreOptions> prepended by C<$class_name> provided as argument or whatever upper package was used in recursion processing.

=back

=head1 COPYRIGHT

Copyright (c) 2000-2014 DEGUEST Pte. Ltd.

=head1 CREDITS

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

=cut

