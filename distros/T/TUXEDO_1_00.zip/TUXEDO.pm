package TUXEDO;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	BADFLDID
	FADD
	FALIGNERR
	FBADACM
	FBADFLD
	FBADNAME
	FBADTBL
	FBADVIEW
	FCONCAT
	FDEL
	FEINVAL
	FEUNIX
	FFTOPEN
	FFTSYNTAX
	FIRSTFLDID
	FJOIN
	FLD_CARRAY
	FLD_CHAR
	FLD_DOUBLE
	FLD_FLOAT
	FLD_LONG
	FLD_SHORT
	FLD_STRING
	FLD_PTR
	FLD_FML32
	FLD_VIEW32
	FMALLOC
	FMAXNULLSIZE
	FMAXVAL
	FMINVAL
	FMLMOD
	FMLTYPE32
	FNOCNAME
	FNOSPACE
	FNOTFLD
	FNOTPRES
	FOJOIN
	FSTDXINT
	FSYNTAX
	FTYPERR
	FUPDATE
	FVFOPEN
	FVFSYNTAX
	FVIEWCACHESIZE
	FVIEWNAMESIZE
	F_BOTH
	F_COUNT
	F_FTOS
	F_LENGTH
	F_NONE
	F_OFF
	F_OFFSET
	F_PROP
	F_SIZE
	F_STOF
	Ferror32
	MAXFBLEN32
	MAXTIDENT
	QMEABORTED
	QMEBADMSGID
	QMEBADQUEUE
	QMEBADRMID
	QMEINUSE
	QMEINVAL
	QMENOMSG
	QMENOSPACE
	QMENOTA
	QMENOTOPEN
	QMEOS
	QMEPROTO
	QMESYSTEM
	QMETRAN
	RESERVED_BIT1
	TMCORRIDLEN
	TMMSGIDLEN
	TMQNAMELEN
	TMSRVRFLAG_COBOL
	TPABSOLUTE
	TPACK
	TPAPPAUTH
	TPCONV
	TPCONVCLTID
	TPCONVMAXSTR
	TPCONVTRANID
	TPCONVXID
	TPEABORT
	TPEBADDESC
	TPEBLOCK
	TPEDIAGNOSTIC
	TPED_MAXVAL
	TPED_MINVAL
	TPED_SVCTIMEOUT
	TPED_TERM
	TPEEVENT
	TPEHAZARD
	TPEHEURISTIC
	TPEINVAL
	TPEITYPE
	TPELIMIT
	TPEMATCH
	TPEMIB
	TPENOENT
	TPEOS
	TPEOTYPE
	TPEPERM
	TPEPROTO
	TPERELEASE
	TPERMERR
	TPESVCERR
	TPESVCFAIL
	TPESYSTEM
	TPETIME
	TPETRAN
	TPEVPERSIST
	TPEVQUEUE
	TPEVSERVICE
	TPEVTRAN
	TPEV_DISCONIMM
	TPEV_SENDONLY
	TPEV_SVCERR
	TPEV_SVCFAIL
	TPEV_SVCSUCC
	TPEXIT
	TPFAIL
	TPGETANY
	TPGOTSIG
	TPMAXVAL
	TPMINVAL
	TPMULTICONTEXTS
	TPNOAUTH
	TPNOBLOCK
	TPNOCHANGE
	TPNOFLAGS
	TPNOREPLY
	TPNOTIME
	TPNOTRAN
	TPQBEFOREMSGID
	TPQCORRID
	TPQFAILUREQ
	TPQGETBYCORRID
	TPQGETBYMSGID
	TPQMSGID
	TPQPEEK
	TPQPRIORITY
	TPQREPLYQ
	TPQTIME_ABS
	TPQTIME_REL
	TPQTOP
	TPQWAIT
	TPRECVONLY
	TPSA_FASTPATH
	TPSA_PROTECTED
	TPSENDONLY
	TPSIGRSTRT
	TPSUCCESS
	TPSYSAUTH
	TPTOSTRING
	TPTRAN
	TPUNSOLERR
	TPU_DIP
	TPU_IGN
	TPU_MASK
	TPU_SIG
	TP_CMT_COMPLETE
	TP_CMT_LOGGED
	VIEWTYPE32
	XATMI_SERVICE_NAME_LENGTH
	X_COMMON
	X_C_TYPE
	X_OCTET
	_FLDID32
	_QADDON
	_TMDLLENTRY
	_TM_FAR
	tperrno
	tpurcode
);
$VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined TUXEDO macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

bootstrap TUXEDO $VERSION;

# Preloaded methods go here.
{	package TuxedoBuffer; # ======== FML32 Buffer ==========
	use strict;
	use Carp;

	my $Debugging = 0;

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {};
		if (@_ == 3 ) 
		{ 
			$self->{BUFFER} = TUXEDO::tpalloc(shift,shift,shift);
		}
		else
		{
			$self->{BUFFER} = 0;
		}
		bless ( $self, $class);
		return $self;
	}

	sub SetBuffer
	{
		my $self = shift;
		my $buffer = shift;
		$self->free();
		$self->{BUFFER} = $buffer;
	}

	sub _buffer {
		my $self = shift;
		return $self->{BUFFER};
	}

	sub size {
		my $self = shift;
		my $size = TUXEDO::tptypes($self->{BUFFER},my $type, my $subtype);
		return $size;
	}

	sub type {
		my $self = shift;
		my $size = TUXEDO::tptypes($self->{BUFFER},my $type, my $subtype);
		return $type;
	}

	sub subtype {
		my $self = shift;
		my $size = TUXEDO::tptypes($self->{BUFFER},my $type, my $subtype);
		return $subtype;
	}

	sub print {
		my $self = shift;
		my $size = TUXEDO::tptypes($self->{BUFFER},my $type, my $subtype);
		print "TUXEDO BUFFER[$self->{BUFFER}]:type $type:subtype $subtype:size $size\n";
	}

	sub resize {
		my $self = shift;
		my $newsize = shift;
		my $newbuffer =  TUXEDO::tprealloc($self->{BUFFER},$newsize);
		if ( $newbuffer != 0 )
		{
			$self->{BUFFER} = $newbuffer;
			return 1;
		}
		return 0;
	}

	sub free {
		my $self = shift;
		if ( $self->{BUFFER} != 0 )
		{
			TUXEDO::tpfree($self->{BUFFER});
			$self->{BUFFER} = 0;
		}
	}

	sub debug {
		my $class = shift;
		if (ref $class) { confess "Class method called as object method" }
		unless (@_ == 1) { confess "usage: CLASSNAME->debug(level)" }
		$Debugging = shift;
	}

	sub DESTROY {
		my $self = shift;
		if ( $Debugging ) { carp "Destroying $self " }
		$self->free;
	}
}


{ 	package FML32Buffer;
	use strict;
	use Carp;
	use vars qw(@ISA);
	@ISA = qw(TuxedoBuffer);

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self;
		if  (@_ == 1 ) { 
			my $size = shift;
			$self = $class->SUPER::new("FML32","",$size);
		}
		else
		{
			$self = $class->SUPER::new;
		}

		bless ( $self, $class);
		return $self;
	}

	sub AddField()
	{
		my $self = shift;
		my ($fname,$fvalue) = @_;
		my $rval =  TUXEDO::AddField32($self->{BUFFER},$fname,$fvalue);
		return $rval;
	}

	sub SetField()
	{
		my $self = shift;
		my ($fname,$focc,$fvalue) = @_;
		my $rval =  TUXEDO::SetField32($self->{BUFFER},$fname,$focc,$fvalue);
		return $rval;
	}

	sub GetField()
	{
		my $self = shift;
		my ($field,$occ) = @_;
		return TUXEDO::GetField32($self->{BUFFER},$field,$occ);
	}

	sub print()
	{
		my $self = shift;
		TUXEDO::Fprint32( $self->{BUFFER} );
	}

	sub mkfldid
	{
		my $class = shift;
		my ($fldtype,$fldnum) = @_;
		return TUXEDO::Fmkfldid32($fldtype,$fldnum);
	}
}


{ 	package FMLBuffer;
	use strict;
	use Carp;
	use vars qw(@ISA);
	@ISA = qw(TuxedoBuffer);

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		unless (@_ == 1 ) { confess "usage: FMLBuffer->new(size)" }
		my $size = shift;

		# call the inherited constructor
		my $self = $class->SUPER::new("FML","",$size);
		bless ( $self, $class);
		return $self;
	}

	sub AddField()
	{
		my $self = shift;
		my ($fname,$fvalue) = @_;
		my $rval =  TUXEDO::AddField($self->{BUFFER},$fname,$fvalue);
		return $rval;
	}

	sub SetField()
	{
		my $self = shift;
		my ($fname,$focc,$fvalue) = @_;
		my $rval =  TUXEDO::SetField($self->{BUFFER},$fname,$focc,$fvalue);
		return $rval;
	}

	sub GetField()
	{
		my $self = shift;
		my ($field,$occ) = @_;
		return TUXEDO::GetField($self->{BUFFER},$field,$occ);
	}

	sub Print()
	{
		my $self = shift;
		TUXEDO::Fprint( $self->{BUFFER} );
	}
}


{ 	package TPINITBuffer;
	use strict;
	use Carp;
	use vars qw(@ISA);
	@ISA = qw(TuxedoBuffer);

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		unless (@_ == 1 ) { confess "usage: TPINITBuffer->new(size)" }
		my $size = shift;

		# call the inherited constructor
		my $self = $class->SUPER::new("TPINIT","",$size);
		bless ( $self, $class);
		$self->data("");
		return $self;
	}

	sub usrname {
		my $self = shift;
		my $value;
		if (@_) { 
			$value = shift; 
			TUXEDO::SetTpinitField($self->{BUFFER},1,$value);
		}
		return TUXEDO::GetTpinitField($self->{BUFFER},1);
	}

	sub cltname {
		my $self = shift;
		my $value;
		if (@_) { 
			$value = shift; 
			TUXEDO::SetTpinitField($self->{BUFFER},2,$value);
		}
		return TUXEDO::GetTpinitField($self->{BUFFER},2);
	}

	sub passwd {
		my $self = shift;
		my $value;
		if (@_) { 
			$value = shift; 
			TUXEDO::SetTpinitField($self->{BUFFER},3,$value);
		}
		return TUXEDO::GetTpinitField($self->{BUFFER},3);
	}

	sub data {
		my $self = shift;
		my $value;
		if (@_) { 
			$value = shift; 
			TUXEDO::SetTpinitField($self->{BUFFER},4,$value);
		}
		return TUXEDO::GetTpinitField($self->{BUFFER},4);
	}

	sub flags {
		my $self = shift;
		my $value;
		if (@_) { 
			$value = shift ;
			TUXEDO::SetTpinitField($self->{BUFFER},5,$value);
		}
		return TUXEDO::GetTpinitField($self->{BUFFER},5);
	}

	sub print {
		my $self = shift;
		$self->SUPER::print;
		my $usrname = $self->usrname;
		my $cltname = $self->cltname;
		my $passwd = $self->passwd;
		my $data = $self->data;
		my $flags = $self->flags;
		print "usrname: $usrname\n";
		print "cltname: $cltname\n";
		print "passwd:  $passwd\n";
		print "data:    $data\n";
		print "flags:   $flags\n";
	}
}

#This just contains class methods common to a client and a server
{ 	package TuxedoMessenger;
	use strict;
	use Carp;

	sub call
	{
		my $class = shift;
		my ($svcname,$inbuf,$outbuf,$flags) = @_;
		return TUXEDO::tpcall($svcname,$inbuf->{BUFFER},$inbuf->size,$outbuf->{BUFFER},my $len,0);
	}
}

{ 	package TuxedoClient;
	use strict;
	use Carp;
	use vars qw(@ISA);
	@ISA = qw(TuxedoMessenger);

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {};
		$self->{ATTRIBUTES} = TPINITBuffer->new(1024);
		bless ( $self, $class);
		return $self;
	}

	sub attributes {
		my $self = shift;
		return $self->{ATTRIBUTES};
	}

	sub logon {
		my $self = shift;
		return TUXEDO::tpinit($self->{ATTRIBUTES}->{BUFFER});
	}

	sub logoff {
		my $self = shift;
		TUXEDO::tpterm();
	}

	sub print {
	}
}


{ 	package TuxedoServer;
	use strict;
	use Carp;
	use vars qw(@ISA);
	@ISA = qw(TuxedoMessenger);

	sub return
	{
		my $class = shift;
		my ($rval,$rcode,$rbuf,$flags) = @_;

		#I have to set the rbuf->{BUFFER} value to zero so the
		#rbuf destructor doesn't try to free the tuxedo buffer.  This
		#is because tpreturn will automatically free this buffer for us.
		my $tmpbuf = $rbuf->{BUFFER};
		my $size = $rbuf->size;
		$rbuf->{BUFFER} = 0;
		
		TUXEDO::tpreturn($rval,$rcode,$tmpbuf,$size,$flags);
	}
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

TuxedoBuffer - Perl class to represent a Tuxedo Buffer. 

=head1 SYNOPSIS

  use TUXEDO;

  #################
  # class methods #
  #################
  $tuxbuf = TuxedoBuffer->new( type, subtype, size );
  eg. $tuxbuf = TuxedoBuffer->new( "FML32", "", 1024 );

  ####################
  # instance methods #
  ####################

  $tuxbuf->SetBuffer( $buffer )
   This makes the TuxedoBuffer encapsulate the 'real' tuxedo buffer
   specified by $buffer.  The methods of the TuxedoBuffer $tuxbuf 
   will then be used on the internal $buffer held by $tuxbuf.  This
   method should not be needed by most Tuxedo client applications.  Its
   main purpose is for use in a tuxedo service where the TPSVCINFO->data
   element is to be encapsulated by a perl TuxedoBuffer object.

  $tuxbuf->size
   Returns the size in bytes of the TuxedoBuffer.

  $tuxbuf->type
   Returns the type of the TuxedoBuffer.

  $tuxbuf->subtype
   Returns the subtype of the TuxedoBuffer.

  $tuxbuf->print
   Prints out the type, subtype and size of the buffer using
   the perl 'print' function ( ie. prints to STDOUT ).

  $tuxbuf->resize( $newsize )
   Resizes the TuxedoBuffer to $newsize.

  $tuxbuf->free
   Frees the actual tuxedo buffer held internally by TuxedoBuffer.  This
   shouldn't have to be explicitly called by a perl program because the
   TuxedoBuffer destructor will call this method.

=head1 DESCRIPTION

   The TuxedoBuffer class should be thought of as an interface for all
   the other Tuxedo buffer classes, such as FML32Buffer or TPINITBuffer.
   Any new Tuxedo buffer types implemented in this perl module should
   have a new class created for them, and have that class inherit from
   the TuxedoBuffer class.  The TuxedoBuffer class can still be used 
   directly within a perl program.

=head1 NAME

FML32Buffer - Perl class representation of a Tuxedo FML32 Buffer. 
            - Inherits from TuxedoBuffer.

=head1 SYNOPSIS

  use TUXEDO;

  #################
  # class methods #
  #################
  $fml32buf = FML32Buffer->new( size );
  eg. $fml32buf = FML32Buffer->new( 1024 );

  ####################
  # instance methods #
  ####################
  $fml32buf->AddField( $fname, $fvalue );
  eg. $fml32buf->AddField( "TA_CLASS", "T_CLIENT" );
   This adds the field to the FML32Buffer.  This will do optimistic
   buffer reallocation if required.  That is this method will attempt
   to add the field to the buffer.  If the field failed to
   be added to the buffer because of an FNOSPACE error, then the
   buffer will be automatically resized to allow the field to be added.
   Returns -1 on error.

  $fml32buf->SetField( $fname, $focc, $fvalue );
  eg. $fml32buf->SetField( "TA_CLASS", 0, "T_CLIENT" );
   This method is identical to $fml32buf->AddField except that you can
   specify the occurrence at which the field is added to the buffer.

  $fml32buf->GetField( $fname, $focc );
  eg. my $value = $fml32buf->GetField( "TA_CLASS", 0 );
   This method will return you the value of the field at the specified
   occurrence.  At the moment, if the field is not found, it will
   return you an empty string ( ie. "" ).  It does this because I put this 
   module together in about 1 day and haven't implemented proper error handling.

  $fml32buf->print
   This prints out the contents of the FML32 buffer.


=head1 NAME

FMLBuffer - Perl class representation of a Tuxedo FML Buffer. 
          - Inherits from TuxedoBuffer.

=head1 SYNOPSIS

  use TUXEDO;

  #################
  # class methods #
  #################
  $fmlbuf = FMLBuffer->new( size );
  eg. $fmlbuf = FMLBuffer->new( 1024 );

  ####################
  # instance methods #
  ####################
  $fmlbuf->AddField( $fname, $fvalue );
  eg. $fmlbuf->AddField( "REPNAME", "SVC/*" );
   This adds the field to the FMLBuffer.  This will do optimistic
   buffer reallocation if required.  That is this method will attempt
   to add the field to the buffer.  If the field failed to
   be added to the buffer because of an FNOSPACE error, then the
   buffer will be automatically resized to allow the field to be added.
   Returns -1 on error.

  $fmlbuf->SetField( $fname, $focc, $fvalue );
  eg. $fmlbuf->SetField( "REPNAME", 0, "SVC/*" );
   This method is identical to $fmlbuf->AddField except that you can
   specify the occurrence at which the field is added to the buffer.

  $fmlbuf->GetField( $fname, $focc );
  eg. my $value = $fmlbuf->GetField( "REPVALUE", 0 );
   This method will return you the value of the field at the specified
   occurrence.  At the moment, if the field is not found, it will
   return you an empty string ( ie. "" ).  It does this because I put this 
   module together in about 1 day and haven't implemented proper 
   error handling.

  $fmlbuf->print
   This prints out the contents of the FML buffer.

=head1 NAME

TPINITBuffer - Perl class representation of a Tuxedo TPINIT Buffer. 
             - Inherits from TuxedoBuffer.

=head1 SYNOPSIS

  use TUXEDO;

  #################
  # class methods #
  #################
  $tpinitbuf = TPINITBuffer->new( size );
  eg. $tpinitbuf = TPINITBuffer->new( 1024 );

  ####################
  # instance methods #
  ####################
  $tpinitbuf->usrname
  get: $usrname = $tpinitbuf->usrname;
  set: $tpinit->usrname( "FRED" );

  $tpinitbuf->cltname
  get: $cltname = $tpinitbuf->cltname;
  set: $tpinit->cltname( "PERL" );

  $tpinitbuf->passwd
  get: $passwd = $tpinitbuf->passwd;
  set: $tpinit->passwd( "1234678" );

  $tpinitbuf->data
  get: $data = $tpinitbuf->data;
  set: $tpinit->data( "qwertyui" );
   Note that although tuxedo allows binary data to be inserted into the
   data element of a tpinit buffer, the current implementation of this
   method only allows a string to be inserted into the data element.  This
   will be modified in a future release.

  $tpinitbuf->flags
  get: $flags = $tpinitbuf->flags;
  set: $tpinit->flags( "0" );
    flags is usually a long value but I got lazy.  This method will convert the
    specified string into a long on insertion and visa versa on retrieval.  This
    will also be updated in a later version.

  $tpinitbuf->print
    This will print out the value of the elements in the TPINIT buffer.

=head1 NAME

TuxedoMessenger - Perl class representation of a Tuxedo Messenger. 
    A messenger is an abstraction of the things that a tuxedo client and
    server have in common.  They can both call services, start and end
    transactions, queue and dequeue requests.  This class should be
    considered abstract and never used directly.  Instead the TuxedoClient
    or TuxedoServer classes that inherit from this class should be used.

=head1 SYNOPSIS

  use TUXEDO;

  #################
  # class methods #
  #################
  TuxedoMessenger->call( servicename, inbuf, outbuf, flags );
  eg.
    my $tuxclient = TuxedoClient->new;
    my $fml32buf = FML32Buffer->new(1024);
    $fml32buf->AddField( "TA_CLASS", "T_CLIENT" );
    $fml32buf->AddField( "TA_OPERATION", "GET" );
    $tuxclient->call( ".TMIB",$fml32buf,$fml32buf, 0 );
    $fml32buf->print

   In the above example, the call method comes from a TuxedoClient object.
   This is deliberate.  DO NOT USE THE TuxedoMessenger CLASS DIRECTLY.  It
   should be considered as an abstract class ( C++ terminology ), and only
   those objects that inherit from this class can call the methods inside
   of it.

=head1 NAME

TuxedoClient - Perl class representation of a Tuxedo Client. 
             - Inherits from TuxedoMessenger.

=head1 SYNOPSIS

  use TUXEDO;

  #################
  # class methods #
  #################
  TuxedoClient->new();
  eg. $tuxclient = TuxedoClient->new();
  Creates a new TuxedoClient instance.

  ####################
  # instance methods #
  ####################
  $tuxclient->attributes
   This returns the TPINITBuffer object held internally by the TuxedoClient.
   This should be used to set client attributes before logging onto a
   tuxedo system.  See TPINITBuffer for a description of the methods that can
   be used on the return value from this method.
  eg.
    $tuxclient->attributes->usrname("FRED");
    $tuxclient->attributes->cltname("PERL");
    $tuxclient->attributes->passwd("12345678");
    $tuxclient->logon;

  $tuxclient->logon
    This logs the client onto the tuxedo system.  For the native version ( which
    is the only version at the moment ), this will use the TUXCONFIG environment
    variable to determine which tuxedo system to connect to.

  $tuxclient->logoff
    Disconnects the client from the tuxedo system.


=head1 NAME

TuxedoServer - Perl class representation of a Tuxedo Server. 
             - Inherits from TuxedoMessenger.

=head1 SYNOPSIS

  use TUXEDO;

  #################
  # class methods #
  #################
  TuxedoServer->return( rval, rcode, rbuf, flags );
  eg. TuxedoServer->return( TUXEDO::TPSUCCESS, 0, $fml32buf, 0 );
   This Invokes the Tuxedo tpreturn function to return from a service.
   rbuf has to be a TuxedoBuffer ( or inherited from it ).  This
   method tells the rbuf destructor not to free the buffer held
   internally by the object, because it is automatically freed by
   the tpreturn function.  This method only makes sense in a perl
   interpreted Tuxedo service.

=head1 COPYRIGHT

The TUXEDO module is Copyright (c) 1999 Anthony Fryer.  Australia.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 Exported constants.  

The constanst below can be access by prefixing with TUXEDO::
eg. TUXEDO::TPSUCCESS

  ATMI_H
  BADFLDID
  FADD
  FALIGNERR
  FBADACM
  FBADFLD
  FBADNAME
  FBADTBL
  FBADVIEW
  FCONCAT
  FDEL
  FEINVAL
  FEUNIX
  FFTOPEN
  FFTSYNTAX
  FIRSTFLDID
  FJOIN
  FLD_CARRAY
  FLD_CHAR
  FLD_DOUBLE
  FLD_FLOAT
  FLD_LONG
  FLD_SHORT
  FLD_STRING
  FMALLOC
  FMAXNULLSIZE
  FMAXVAL
  FMINVAL
  FML32_H
  FMLMOD
  FMLTYPE32
  FNOCNAME
  FNOSPACE
  FNOTFLD
  FNOTPRES
  FOJOIN
  FSTDXINT
  FSYNTAX
  FTYPERR
  FUPDATE
  FVFOPEN
  FVFSYNTAX
  FVIEWCACHESIZE
  FVIEWNAMESIZE
  F_BOTH
  F_COUNT
  F_FTOS
  F_LENGTH
  F_NONE
  F_OFF
  F_OFFSET
  F_PROP
  F_SIZE
  F_STOF
  Ferror32
  MAXFBLEN32
  MAXTIDENT
  QMEABORTED
  QMEBADMSGID
  QMEBADQUEUE
  QMEBADRMID
  QMEINUSE
  QMEINVAL
  QMENOMSG
  QMENOSPACE
  QMENOTA
  QMENOTOPEN
  QMEOS
  QMEPROTO
  QMESYSTEM
  QMETRAN
  RESERVED_BIT1
  TMCORRIDLEN
  TMMSGIDLEN
  TMQNAMELEN
  TMSRVRFLAG_COBOL
  TPABSOLUTE
  TPACK
  TPAPPAUTH
  TPCONV
  TPCONVCLTID
  TPCONVMAXSTR
  TPCONVTRANID
  TPCONVXID
  TPEABORT
  TPEBADDESC
  TPEBLOCK
  TPEDIAGNOSTIC
  TPED_MAXVAL
  TPED_MINVAL
  TPED_SVCTIMEOUT
  TPED_TERM
  TPEEVENT
  TPEHAZARD
  TPEHEURISTIC
  TPEINVAL
  TPEITYPE
  TPELIMIT
  TPEMATCH
  TPEMIB
  TPENOENT
  TPEOS
  TPEOTYPE
  TPEPERM
  TPEPROTO
  TPERELEASE
  TPERMERR
  TPESVCERR
  TPESVCFAIL
  TPESYSTEM
  TPETIME
  TPETRAN
  TPEVPERSIST
  TPEVQUEUE
  TPEVSERVICE
  TPEVTRAN
  TPEV_DISCONIMM
  TPEV_SENDONLY
  TPEV_SVCERR
  TPEV_SVCFAIL
  TPEV_SVCSUCC
  TPEXIT
  TPFAIL
  TPGETANY
  TPGOTSIG
  TPMAXVAL
  TPMINVAL
  TPMULTICONTEXTS
  TPNOAUTH
  TPNOBLOCK
  TPNOCHANGE
  TPNOFLAGS
  TPNOREPLY
  TPNOTIME
  TPNOTRAN
  TPQBEFOREMSGID
  TPQCORRID
  TPQFAILUREQ
  TPQGETBYCORRID
  TPQGETBYMSGID
  TPQMSGID
  TPQPEEK
  TPQPRIORITY
  TPQREPLYQ
  TPQTIME_ABS
  TPQTIME_REL
  TPQTOP
  TPQWAIT
  TPRECVONLY
  TPSA_FASTPATH
  TPSA_PROTECTED
  TPSENDONLY
  TPSIGRSTRT
  TPSUCCESS
  TPSYSAUTH
  TPTOSTRING
  TPTRAN
  TPUNSOLERR
  TPU_DIP
  TPU_IGN
  TPU_MASK
  TPU_SIG
  TP_CMT_COMPLETE
  TP_CMT_LOGGED
  VIEWTYPE32
  XATMI_SERVICE_NAME_LENGTH
  X_COMMON
  X_C_TYPE
  X_OCTET
  _FLDID32
  _QADDON
  _TMDLLENTRY
  _TM_FAR
  tperrno
  tpurcode


=head1 AUTHOR

Anthony Fryer, apfryer@hotmail.com

=head1 SEE ALSO

perl(1).

=cut
