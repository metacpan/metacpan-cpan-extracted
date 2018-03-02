package Script::Toolbox::Util;

use 5.006;
use strict;
use Script::Toolbox::Util::Opt;
use Script::Toolbox::Util::Formatter;
use Script::Toolbox::Util::Menues;
use Script::Toolbox::Util::Menus;
use Script::Toolbox::TableO;
use IO::File;
use IO::Dir;
use Data::Dumper;
use Fatal qw(open close);
use POSIX qw(strftime);
use Time::ParseDate;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Script::Toolbox::Util ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(Open Log Exit Table Usage Dir
                               File FileC System Now Menu KeyMap
                               Stat TmpFile DataMenu Menue DataMenue
                               CheckBox
                               )] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

#our $VERSION = '0.50';

# Preloaded methods go here.
sub _getKV(@);
sub _getCSV(@);

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub new
{
    my $classname = shift;
    my $optDef    = shift; # options definition
    my $self = {};
    bless( $self, $classname );

    @Script::Toolbox::Util::caller = caller();
    $self->_init( $optDef, \@Script::Toolbox::Util::caller, @_ );

    return $self;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _init($)
{
    my ($self,$ops,$caller,$args) = @_;

    my $log = $caller->[1];
       $log =~ s|^.*/||;
       $log =~ s/[.].*$//;
       $Script::Toolbox::Util{'_logFH'} = undef;	# use default STDERR 

    # Install signal handler
    $self->_installSigHandlers();

    # install options
    $self->_installOps( $ops );
    Exit( 1, "Invalid option definition, 'opsDef' => {} invalid." )
      if( defined $ops && !defined $self->{'ops'});

    # init log file
    my $logdir = $self->GetOpt('logdir');
    if( defined $logdir )
    {
	    system( "mkdir -p $logdir" );
	    $Script::Toolbox::Util{'_logFH'} = Open( ">> $logdir/$log.log" );
	    $Script::Toolbox::Util{'_logFH'}->autoflush();
    }
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _installOps($)
{
    my ($self, $opsDef) = @_;

    $self->{'ops'} = Script::Toolbox::Util::Opt->new( $opsDef, \@Script::Toolbox::Util::caller );
    return if( !defined $self->{'ops'} );

    foreach my $key ( keys %{$self->{'ops'}} )
    {
	    if( defined $self->{$key} )
	    {
	        print STDERR "Script::Toolbox internal error. ";
	        print STDERR "Can't use command line option $key (internal used)\n";
	        next;
	    }
	    $self->{$key} = $self->{'ops'}->get($key);
    }
    return;
}

#------------------------------------------------------------------------------
# Signal handler.
#------------------------------------------------------------------------------
sub _sigExit($)
{
    my ($sig) = @_;
    Exit( 1, "program aborted by signal SIG$sig." );
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _installSigHandlers()
{
    my ($self) = @_;
    $SIG{'INT'} = \&_sigExit;
    $SIG{'HUP'} = \&_sigExit;
    $SIG{'QUIT'}= \&_sigExit;
    $SIG{'TERM'}= \&_sigExit;
}


#------------------------------------------------------------------------------
# Log a message and exit the programm with the given error code.
#------------------------------------------------------------------------------
sub Exit(@)
{
    my ($exitCode, $message, $file, $line) = _getParam(@_);

    $message .= sprintf "\n\tSource:%s:%s", $file, $line if( defined $line &&
                                                         defined $file );
    Log( $message );
    exit $exitCode;
}

#------------------------------------------------------------------------------
# Write 'die' messages via Log().
#------------------------------------------------------------------------------
sub _dieHook
{
	die @_ if $^S;

    my @y = split /\n/, $_[0];
    map { Log( $_ ); } @y;
};
$main::SIG{'__DIE__'} = \&_dieHook;  # install die hook


#------------------------------------------------------------------------------
# Write a log message with time stamp to a channel.
# $severity, $logtag only required for syslog.
#------------------------------------------------------------------------------
sub Log(@)
{
    my ($message, $canal, $severity, $logtag) = _getParam(@_);

	my $prog =  $0;
	   $prog =~ s|^.*/||;
    my $msg  =  sprintf "%s: %s: %s\n", $prog, scalar localtime(), $message;

    my $fh;
    my $can = *STDERR;
    
    if ( !defined $canal )
    {
	if( defined $Script::Toolbox::Util{'_logFH'}) { $can = $Script::Toolbox::Util{'_logFH'}; }
    }else{
	# canel is defined here
	if ( ref($canal) eq 'IO::File' ){ $can = $canal;  }
	elsif ( $canal eq 'STDERR') 	{ $can = *STDERR; }
	elsif ( $canal eq 'STDOUT') 	{ $can = *STDOUT; }
	elsif ( $canal eq 'syslog') 	{ $can = new IO::File "| logger -p '$severity' -t '$logtag'"; }
	else  { $can = _openFromString($canal); }
    }
    print $can $msg;
    return $msg;
}

#------------------------------------------------------------------------------
# We got a string like "/tmp/x", ">> /tmp/x" or "| someProgram".
# Try to open it as a log canal. If it fails open STDERR instead.
#------------------------------------------------------------------------------
sub _openFromString($)
{
    my ($canal) = @_;

    if( $canal !~ /^\s*>/ && $canal !~ /^\s*[|]/ ) { $canal = '>>' . $canal; }

    my $can;
    my $fh = new IO::File "$canal";
    if( !defined $fh ) 
    {
	$can = *STDERR;
	printf $can "%s: %s: %s %s\n",
		$0, scalar localtime(), "WARNING: can't write to", $canal;
    }else{
	$can = $fh;
    }
    return $can;
}

#------------------------------------------------------------------------------
# Open a file via IO::File with Fatal handling
#------------------------------------------------------------------------------
sub Open(@)
{
	my ($file, $iolayer) = _getParam(@_);
	my $fh = new IO::File;
	$fh->open( "$file" );
	#$fh->open( "$file" ) || return undef;
	return $fh;
}
use Fatal qw(IO::File::open);


#------------------------------------------------------------------------------
# Format $param as table and return a reference to the result array.
#------------------------------------------------------------------------------
sub Table(@)
{
	my ($self, $param, $separator) = @_;
    if( ref $self ne 'Script::Toolbox') { # only for compatibility
        $separator = $param;              # to versions befor 0.50
        $param     = $self;
        $self      = undef;
    }

    my $t = Script::Toolbox::TableO->new($param, $separator);
    my @T =  $t->asArray();
    return \@T;
}

#------------------------------------------------------------------------------
# $param must be a hash reference. This Hash must have a key "data".
# This key may point to:
# 		arrayref 
# 		hashref
#------------------------------------------------------------------------------
sub _noData($)
{
	my ($param) = @_;

	return 0 if( ref $param ne 'HASH' );
	return 0 if( ref $param->{'data'} eq 'HASH' );
	return 0 if( ref $param->{'data'} eq 'ARRAY');

	if( !defined $param->{'data'}[0] )
	{
	    Log( "WARNING: no input data for Table()." );
	    return 1;
	}
	return 0;
}

#------------------------------------------------------------------------------
# Valid Calls:
#	[ "csvString", "csvString",...], 				 undef
#	[ "csvString", "csvString",...], 				 separatorString
#	[ "TitelString", [headArray], [dataArray],...],  undef
#	[ [dataArray],...],  							 undef
#	{title=>"", head=>[], data=>[[],[],...] },		 undef
#	{title=>"", head=>[], data=>[{},{},...] },		 undef
#	{title=>"", head=>[], data=>{r1=>{c1=>,c2=>,},r2=>{c1=>,c2=>,},}, undef
#------------------------------------------------------------------------------
sub _normParam($$)
{
	my ($param, $separator) = @_;

	if( ref $param eq 'HASH' )
	{
	    # keine Ahnung wozu: return _sepHash($param, $separator)	if( _isCSV($param->{'data'}) );
	    return $param;
	}
	return _sepTitleHead($param)		if( _isTitleHead($param) );
	return _sepCSV($param, $separator) 	if( _isCSV($param, $separator) );
	return { 'data' => $param };
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _sepHash($$)
{
	my ($param,$separator) = @_;

	my $d = _sepCSV($param->{'data'}, $separator);
	$param->{'data'} = $d->{'data'};
	return $param;
}

# ------------------------------------------------------------------------------
# Check if we found the special data array format.
# ["TitleString", [headString,headString,...],[data,...],...]
#------------------------------------------------------------------------------
sub _isTitleHead($)
{
	my ($param) = @_;

	return 1	if( ref \$param->[0] eq 'SCALAR' && ref $param->[1] eq 'ARRAY' );
	return 0;
}

#------------------------------------------------------------------------------
# Transform the special data array
# ["TitleString", [headString,headString,...],[data,...],...]
# into hash format. 
#------------------------------------------------------------------------------
sub _sepTitleHead($)
{
	my ($param) = @_;

	my $title= splice @{$param}, 0,1;
	my $head = splice @{$param}, 0,1;

	return	{
		'title'	=> $title,
		'head'	=> $head,
		'data'	=> $param
		};
}


#------------------------------------------------------------------------------
#	[[],[],...]
#	[{},{},...]
#	{r1=>{c1=>,c2=>,},r2=>{c1=>,c2=>,},}
#------------------------------------------------------------------------------
sub _isCSV($$)
{
	my ($param, $separator) = @_;

	return 0	if( ref  $param      ne 'ARRAY' );

	$separator = ';'	unless defined $separator; #FIXME default sep
	return 1    if( $param->[0] =~ /$separator/ ); #assume it's a CSV record
	return 0;
}

#------------------------------------------------------------------------------
# Convert an array of CSV strings into an array of arrays.
#
# [ "a;b","c,d"] becomes
# [[a,b], [c,d]]
#------------------------------------------------------------------------------
sub _sepCSV($$)
{
	my ($param, $separator) = @_;

	$separator = ';'	if( !defined $separator);
	my @R;
	foreach my $l ( @{$param} )
	{
	    my @r = split /$separator/, $l;
	    push @R, \@r;
	}

	return { 'data' => \@R };
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub SetOpsDef($)
{
	my ($self,$opsDef) = @_;
	my $old = $self->{'ops'};
	$self->{'ops'} = Script::Toolbox::Util::Opt->new( $opsDef );
	return ($self->{'ops'}, $old);
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub GetOpt($)
{
	my ($self,$opt) = @_;
	return	undef if( ! defined $self->{'ops'} );
	return	$self->{'ops'}->get($opt);
}

#------------------------------------------------------------------------------
# Read the entire file into  an array.
# File can be a file name or an IO::File handle.
# Chomp all array elements.
#------------------------------------------------------------------------------
sub FileC(@)
{
	my ($filename,$newContent) = _getParam(@_);

    my $f = undef;
	   if( !defined  $newContent) 	 { $f = _ReadFile($filename); }
	elsif( ref $newContent eq 'CODE'){ $f = _ReadFile($filename,$newContent);}
    else                             { return undef; }

    chomp @{$f} if( defined $f );
    return $f;
}

#------------------------------------------------------------------------------
# Read the entire file into  an array or write the new content to the file.
# File can be a file name or an IO::File handle.
# Newcontent may be a SCALAR value, an ARRAY reference, a HASH reference or
# a reference to a callback function.
#------------------------------------------------------------------------------
sub File(@)
{
	my ($filename,$newContent,$recSep,$fieldSep) = _getParam(@_);

	   if( !defined  $newContent) 	 { return _ReadFile($filename); }
	elsif( ref $newContent eq 'CODE'){ return _ReadFile($filename,$newContent);}
	else { _WriteFile($filename,$newContent,$recSep,$fieldSep); }
}

#------------------------------------------------------------------------------
# Read the entire file into a hash or write the new content to the file.
# File can be a file name or an IO::File handle.
# Newcontent may be a reference to a keyMap HASH or a reference to a callback
# function.
# The Hash looks like:
# keyA1 => keyB1 ... =>keyN1 => value1
# keyA2 => keyB2 ... =>keyN2 => value2
#------------------------------------------------------------------------------
sub KeyMap(@)
{
	my ($filename,$fieldSep,$newContent) = _getParam(@_);

	   if( !defined  $newContent)
		 { return _ReadKeyMap($filename, $fieldSep); }
	elsif( ref $newContent eq 'CODE' )
		 { return _ReadKeyMap($filename, $fieldSep, $newContent); }
	else { _WriteKeyMap($filename,$fieldSep,$newContent); }
}

#------------------------------------------------------------------------------
# The Hash looks like:
# keyA1 => keyB1 ... =>keyN1 => value1
# keyA2 => keyB2 ... =>keyN2 => value2
#------------------------------------------------------------------------------
sub _WriteKeyMap($$$)
{
	my ($filename,$fieldSep,$newContent) = @_;

	$fieldSep = ','	if( !defined $fieldSep );

	my $TXT = '';
	_getCSV( \$TXT, '', $newContent, $fieldSep );

	File( "> $filename", $TXT );
}

#------------------------------------------------------------------------------
# Write a KeyMap (HASH) to a file.
#
# The Hash looks like:
# keyA1 => keyB1 ... =>keyN1 => value1
# keyA2 => keyB2 ... =>keyN2 => value2
#------------------------------------------------------------------------------
sub _getCSV(@)
{
	my ($txt, $prev, $newContent,$fieldSep) = @_;

	my $prefix = '';
	foreach my $k ( sort keys %{$newContent} )
	{
		$$txt .= $prefix .$k . $fieldSep;
		if( ref $newContent->{$k} ne 'HASH' )
		{
			$$txt  .= $newContent->{$k} . "\n";
			$prefix = $prev;
			next;
		}
		_getCSV($txt, "$prev$k$fieldSep", $newContent->{$k}, $fieldSep);
	}
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
sub _checkParam($$)
{
	my ( $fieldSep, $callBack) = @_;

	my $def=',';
	$$fieldSep = $def	if( !defined $$fieldSep );

	my ( $fs, $cb ) = ( $$fieldSep, $$callBack);
	my $rfs = ref $fs; my $rcb = ref $cb; 
	
	my $scalar_code	= ref $fs eq '' 	&& ref $cb eq 'CODE';
	my $scalar_undef= ref $fs eq '' 	&& !defined $cb;
	my $code_scalar = ref $fs eq 'CODE'	&& ref $cb eq '' && defined $cb;
	my $code_undef  = ref $fs eq 'CODE'	&& !defined $cb;

	if   ( $scalar_code ){return;}
	elsif( $scalar_undef){return;}
	elsif( $code_scalar ){$$fieldSep = $cb; $$callBack = $fs;}
	elsif( $code_undef  ){$$fieldSep = $def;$$callBack = $fs;}
	else { $$fieldSep = $def; $$callBack = undef;}
}

#------------------------------------------------------------------------------
# Read a CSV file into a hash. The lines of the CSV files are "\n" separated.
# Default field separator is ",".
# The Hash looks like:
# keyA1 => keyB1 ... =>keyN1 => value1
# keyA2 => keyB2 ... =>keyN2 => value2
#------------------------------------------------------------------------------
sub _ReadKeyMap($$$)
{
	my ($file, $fieldSep, $callBack) = @_;
	
	_checkParam(\$fieldSep, \$callBack);	

	my $f;
	if( defined $callBack ) { $f = File( $file,$callBack, $fieldSep ); }
	else					{ $f = File( $file ); }
	chomp( @{$f} );

	my %P;
	foreach my $line ( @{$f} )
	{
		my @L = split /$fieldSep/, $line;
		_getKV( \%P, @L );       
	}
	return \%P;
}

#------------------------------------------------------------------------------
# Add one line (from @_ array) to the hash. Hash looks like:
# key1 => key2 ... =>keyN => value1
# key1 => key2 ... =>keyX => value2
#------------------------------------------------------------------------------
sub _getKV(@)
{
	my ($P, $k, @v) = @_;
        
	return  if( ! defined $k );
	if( ref $P->{$k} eq 'HASH' ){
		_getKV( $P->{$k}, @v );
		return;
	}
	if( @v == 1 ){
		$P->{$k} = $v[0];
		return;
	}else{
		my $x = {};
		$P->{$k} = $x;
		_getKV( $x, @v );
	}
}


#------------------------------------------------------------------------------
# Open the file in required write mode (default append mode) and write the new
# content to the file.
# Newcontent can be any kind of data structure.
#------------------------------------------------------------------------------
sub _WriteFile($$)
{
	my($file,$newContent,$recSep,$fieldSep) =@_;

	my $fh;
	if( ref $file eq 'IO::File' )
	{
		$fh = $file;
	}else{
		$file =~ s/^\s+//;
		$file =~ s/^<+//;	# write mode only 
		$file = '>>' . $file	if( $file !~ /^[|>]/ );
		$fh = Open( $file ) || return undef;
	}
	   if( ref $newContent eq '' ) 	   {print $fh $newContent;}
	elsif( _simpleArray( $newContent))
	     { _printSimpleArray($newContent, $fh, $recSep)}
	elsif( _simpleHash( $newContent ))
	     { _printSimpleHash($newContent, $fh, $recSep,$fieldSep)}
	else { print $fh Dumper $newContent; }
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _printSimpleArray($$$)
{
    my ($content,$fh,$recSep) = @_;

    map
    {
	my $rs = defined $recSep   ? $recSep   : '';
    	print $fh "$_$rs";
    } @{$content};
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _printSimpleHash($$$$)
{
    my ($content,$fh,$recSep,$fieldSep) = @_;
    foreach my $key (sort keys %{$content})
    {
	my $rs = defined $recSep   ? $recSep   : '';
	my $fs = defined $fieldSep ? $fieldSep : ':';
	printf $fh "%s%s%s%s", $key, $fs, $content->{$key},$rs; 
    }
    return;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _simpleHash($)
{
    my ($content) = @_;

    return 0 if( ref $content ne 'HASH');
    foreach my $key ( keys %{$content} )
    {
    	return 0 if( ref $content->{$key} ne '' ); # scalar estimated
    }
    return 1;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _simpleArray($)
{
    my ($content) = @_;

    return 0 if( ref $content ne 'ARRAY');
    foreach my $line ( @{$content} )
    {
    	return 0 if( ref $line ne '' ); # scalar estimated
    }
    return 1;
}

#------------------------------------------------------------------------------
# Read the file content into an array and return a referenz to this array.
# Return undef if the file isn't readable.
# File can be a file name or an IO::File handle.
#------------------------------------------------------------------------------
sub _ReadFile($$)
{
	my($file,$callBack) =@_;

	my ($fh,@F);
	if( ref $file  eq 'IO::File' )
	{
	    $fh = $file;
	}else{
	    $file =~ s/^\s*>+\s*//; # read only mode
	    $fh= Open( $file )  || return undef;
	}
	@F  = <$fh>; my $rf = \@F;
	$rf = &{$callBack}( \@F )	if( defined $callBack );
	$rf = \@F					if(!defined $rf );
	return $rf;
}

#------------------------------------------------------------------------------
# Without an input argument TmpFile() returns an file handle to an new 
# temporary file.
# Otherwise read the tempfile into an array and return a reference to it.
#------------------------------------------------------------------------------
sub TmpFile(@)
{
    my ($file) = _getParam(@_);

	my ($f,@F);
	if( ref $file eq 'IO::File' ) { $file->seek(0,0); @F = <$file>; $f=\@F; }
	else			  { $f = IO::File::new_tmpfile; }
    return $f;
}


#------------------------------------------------------------------------------
# Return the filenames of a directory as array reference.
# Skip '.','..' and all filenames not matching search pattern if a search
# pattern is defined.
#------------------------------------------------------------------------------
sub Dir(@)
{
	my ($dirPath,$searchPattern) = _getParam(@_);

	my $d = IO::Dir->new($dirPath);
	return undef if( !defined $d );
	
	my @D;
	while( defined($_ = $d->read))
	{
	    next	if( _toSkip( $_, $searchPattern ));
	    push @D, $_;
	}
	@D = sort @D;
	return \@D;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _toSkip($$)
{
	my ($line,$pattern) = @_;

	return 1    if( $line =~ /^[.]{1,2}$/ ); 
	return 0    if( !defined $pattern );

	if( $pattern =~ /^\s*!/ )
	{
	    $pattern = substr($pattern, 1 );
	    return 1	if( $line =~ /$pattern/ );
	}else{
	    return 1	if( $line !~ /$pattern/ );
	}
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub Usage($$)
{
	my ($self, $add) = @_;

	return	$self->{'ops'}->usage($add);
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub SetOpt($$$)
{
	my ($self,$opt,$value) = @_;
	return	undef unless defined $self->{'ops'};
	return	undef unless ref($self->{'ops'}) eq 'Script::Toolbox::Util::Opt';
	my $old = $self->{'ops'}->set($opt,$value);
	$self->{$opt} = $value;
	return $old;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getParam(@)
{
    #if( isa( $_[0], "Script::Toolbox::Util" ))
    my $x = ref $_[0];
    if( $x =~ /Script::Toolbox/  )
    {
	    shift @_ if( $_[0]->isa("Script::Toolbox::Util" ));
    }
    return @_;
}

#------------------------------------------------------------------------------
# Start a shell command with logging.
# Return 0 if shell command failed otherwise 1.
#------------------------------------------------------------------------------
sub System($)
{
    my( $cmd ) = _getParam(@_);

    my $fh = new IO::File;
    my $pid = $fh->open("$cmd ". '2>&1; echo __RC__$? |' );

    my $rc;
    while( <$fh> )
    {
        chomp;
        $rc = $_, next  if( /^__RC__/ );
		next			if( /^\s*$/ );
        Log( " $_" );
    }

    $rc =~ s/__RC__//;

    return 1 if( $rc == 0 );
    return 0;
}

#------------------------------------------------------------------------------
# Compute the difference between NOW[+offset] and the time value given as 
# second parameter. Return a hash reference holding the difference in seconds,
# minutes, hours and days. Every value as a floating point number.
#
# The referenz time (rtime) may be an epoch value or any string parsable by
# Time::ParseDate.
#------------------------------------------------------------------------------
sub _nowDiff($$)
{
	my ($now,$rtime) = @_;

	$rtime = parsedate( $rtime ) if( $rtime !~ /^[0-9]+$/ );

	my $secDiff= $now - $rtime;
	my $D      = int $secDiff / 86400; my $x = $secDiff % 86400; 
	my $H      = int $x       /  3600;    $x = $x       %  3600;
	my $M      = int $x       /    60;    $x = $x       %    60;
	my $S      = $x;

	my %R;
	$R{seconds}= $secDiff;
	$R{minutes}= $R{seconds} / 60.0;
	$R{hours}  = $R{seconds} / 3600.0;
	$R{days}   = $R{seconds} / 86400.0;
	$R{DHMS}   = sprintf "%dd %.2d:%.2d:%.2d", $D,$H,$M,$S;
	return \%R;
}


#------------------------------------------------------------------------------
# Return the actual date and time. If $format is undef the result is a hash
# ref with keys sec,min,hour,mday,mon,year,wday,yday,isdst,epoch.
# Mon and year are corrected. Epoch is the time in seconds since 1.1.1970.
# If $format is not undef it must be a strftime() format string. The result
# of Now() is then the strftime() formated string.
# $opt may be {format=><'strftime-format'>, offset=><+-seconds>, diff=><time>} 
#------------------------------------------------------------------------------
sub Now(@)
{
    my( $opt ) = _getParam(@_);

	my $offset = defined $opt->{offset} ? $opt->{offset}+0 : 0;
	my $epoch  = time+$offset;

	return _nowDiff( $epoch, $opt->{diff} ) if( $opt->{diff} );

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($epoch);

	return strftime $opt->{format},
		   $sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst
		   if( defined $opt->{format} );

	$mon++;
	$year+=1900;
	return {sec=>$sec,min=>$min,hour=>$hour, mday=>$mday,mon=>$mon,year=>$year,
				wday=>$wday,yday=>$yday,isdst=>$isdst,epoch=>$epoch};
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _printMenuHeader($) {
    my ($head) = @_;
    return  if( ! defined $head );
    printf "%s", $head;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _printMenuFooter($) {
    my ($foot) = @_;
    return  if( ! defined $foot );
    printf "%s", $foot;
}

#------------------------------------------------------------------------------
# Compute real index if we have NON-Lable lines in the opts-array.
#------------------------------------------------------------------------------
sub _getRealIndex($$) {
    my ($o, $opts) = @_;

    my $real = 0;
    my $curr = 0;
    foreach my $op ( @{$opts} )
    {
        $real++         if( ! $op->{'label'} );
        return $real    if( $o == $curr );
        $real++;
        $curr++;
    }
    return $real;
}

#------------------------------------------------------------------------------
# Concatenate several header/footer options into header/footer strings.
# Return original options array-ref and header/footer strings.
#------------------------------------------------------------------------------
sub _normMenuOpts($){
    my ($opts) = @_;

    my $head = '';
    my $foot = '';
    my @OPTS;
    foreach my $l ( @{$opts} ){
        $head .= sprintf "%s\n", $l->{'header'}   if( defined $l->{'header'} );
        $foot .= sprintf "%s\n", $l->{'footer'}   if( defined $l->{'footer'} );
        push @OPTS, $l                          if( defined $l->{'label'}  );
    }
    $head = $head eq '' ? undef : $head;
    $foot = $foot eq '' ? undef : $foot;

    return \@OPTS, $head, $foot;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _printOption($$$) {
    my ($op,$form1,$i) = @_;

    my ($def,$form)=_getDefForm($form1,$op);
    if( defined $def ) {
        printf $form, $i,$op->{'label'},$def;
        return;
    }
    printf $form, $i,$op->{'label'};
}
#------------------------------------------------------------------------------
# Display a menu, return the selected index number and the menu data structure.
# If a VALUE or DEFAULT key of a menu option points to a value this value can
# be changed.
# If a jump target is defined, the corresponding function will be called with
# argv=> as arguments.
# Data structure: [{label=>,value=>,jump=>,argv=>},...]
# - label=> must be defined all other keys are optinal
# - jump=> must point to a subroutine if set
# - argv=> arguments for the subroutine jump points to
# - header=> an optional head line
# - footer=> an optional footer line
#------------------------------------------------------------------------------
sub Menu($) {
    my ($OPTS) = @_;

    my ($opts,$head,$foot) = _normMenuOpts($OPTS);
    my ($i,$o) = (0,0);
    my $maxLen = _maxLabelLength($opts);
    my $form1 = "%3d %-${maxLen}s ";
    system("clear");
    _printMenuHeader($head);
    ($i,$o) = (0,0);
    foreach my $op ( @{$opts} )
    {
        next if( ! $op->{'label'} );
        _printOption($op,$form1,$i++);
    }
    _printMenuFooter($foot);
    printf "\nSelect: ";
    $o = _getNumber( $i-1);
    _setValue($o, $opts);
    _jump($o, $opts); # jump to callback if defined
    return $o,$opts;
}
#------------------------------------------------------------------------------
# Deprecated Menu function. Only for compatibility with legacy software.
#------------------------------------------------------------------------------
sub Menue($){
    return Menu($_[0]);
}

#------------------------------------------------------------------------------
# Prepare input for Data Menu. Allowed input formats:
# INPUT2: [{'label'=>'Max','value'=>'foo'},{'label'=>'Tim','value'=>99}]
#------------------------------------------------------------------------------
sub _arrayHandler($$) {
    my ($dataMenu,$opts) = @_;

    foreach my $line ( @{$opts} ) {
            next    if( ref $line ne 'HASH' );
            next    if( ! defined $line-{'label'} );
            next    if( ! defined $line-{'value'} );
            push @{$dataMenu}, $line,
    }
    return 'ARRAY';
}

#------------------------------------------------------------------------------
# Prepare input for Data Menu. Allowed input formats:
# INPUT3: {}[, {'header'=>'','footer'=>''}]
#------------------------------------------------------------------------------
sub _hashHandler($$$) {
    my ($dataMenu,$opts,$frame) = @_;

    foreach my $l ( sort keys %{$opts} ) {
        next    if( ref $opts->{$l} ne '' );
        my $line = {'label' => $l, 'value' => $opts->{$l}};
        push @{$dataMenu}, $line,
    }
    return 'HASH' if( ! defined $frame );

    push @{$dataMenu}, {'header' => $frame->{'header'}} if( defined $frame->{'header'});
    push @{$dataMenu}, {'footer' => $frame->{'footer'}} if( defined $frame->{'footer'});
    return 'HASH';
}


#------------------------------------------------------------------------------
# Prepare input for Data Menu. Allowed input formats:
# INPUT1: 'value1 value2 ..'[, {'header'=>'','footer'=>''}]
#------------------------------------------------------------------------------
sub _scalarHandler($$$) {
    my ($dataMenu,$opts,$frame) = @_;

    my $i=1;
    foreach my $l ( split /\s+/, $opts ) {
        my $line = {'label' => 'V'.$i++, 'value' => $l};
        push @{$dataMenu}, $line,
    }
    return 'SCALAR' if( ! defined $frame );
    push @{$dataMenu}, {'header' => $frame->{'header'}} if( defined $frame->{'header'});
    push @{$dataMenu}, {'footer' => $frame->{'footer'}} if( defined $frame->{'footer'});
    return 'SCALAR';
}

#------------------------------------------------------------------------------
# Prepare input for Data Menu. Allowed input formats:
# INPUT1: 'value1 value2 ..'[, {'header'=>'','footer'=>''}]
# INPUT2: [{'label'=>'Max','value'=>'foo'},{'label'=>'Tim','value'=>99}]
# INPUT3: {}[, {'header'=>'','footer'=>''}]
#------------------------------------------------------------------------------
sub _addData($$$)
{
    my ($dataMenu,$opts,$frame) = @_;

    return _arrayHandler ($dataMenu,$opts)        if(ref $opts eq 'ARRAY');
    return _hashHandler  ($dataMenu,$opts,$frame) if(ref $opts eq 'HASH' );
    return _scalarHandler($dataMenu,$opts,$frame) if(ref $opts eq '' );
}

#------------------------------------------------------------------------------
# Remove {label=>"EXIT"} line.
#------------------------------------------------------------------------------
sub _returnArray($) {
    my ($dataMenu) = @_;
    splice @{$dataMenu},0,1;
    return $dataMenu;
}

#------------------------------------------------------------------------------
# Remove {label=>"EXIT"} line. Return values as white space separated string.
#------------------------------------------------------------------------------
sub _returnScalar($) {
    my ($dataMenu) = @_;

    splice @{$dataMenu},0,1;
    my     $data='';
    map { $data .= $_->{'value'} .' ' if( defined $_->{'value'})} @{$dataMenu};
    chop   $data;
    return $data;
}

#------------------------------------------------------------------------------
# Remove {label=>"EXIT"}, header and footer lines.
# Return values as white hash ref with 'label' as key and 'value' as value.
#------------------------------------------------------------------------------
sub _returnHash($) {
    my ($dataMenu) = @_;

    splice @{$dataMenu},0,1;
    my     %data;
    map {   if( defined $_->{'value'} && defined $_->{'label'} ){
                my $k = $_->{'label'};
                my $v = $_->{'value'};
                $data{$k} = $v;
            }
        } @{$dataMenu};
    return \%data;
}

#------------------------------------------------------------------------------
# Use Menu to edit small data sets. Two input formats allowed.
# INPUT1: 'value1 value2 ..'
# INPUT2: [{'label'=>'Max','value'=>'foo'},{'label'=>'Tim','value'=>99}]
#------------------------------------------------------------------------------
sub DataMenu(@) {
    my ($opts,$head) = @_;

    my $dataMenu = [{label=>"RETURN"}];
    my $format    = _addData($dataMenu, $opts,$head);

    while( 1 ) {
        my ($o,$dataMenu) = Menu($dataMenu);
        last if( $o == 0 );
    }
    return _returnArray ( $dataMenu) if( $format eq 'ARRAY' );
    return _returnScalar($dataMenu)  if( $format eq 'SCALAR');
    return _returnHash  ($dataMenu)  if( $format eq 'HASH'  );
}
#------------------------------------------------------------------------------
# Deprecated Menu function. Only for compatibility with legacy software.
#------------------------------------------------------------------------------
sub DataMenue(@){
    return DataMenu(@_);
}

#------------------------------------------------------------------------------
#  Read a directory and return a hash with filenames stat() structure infos
#  for every file. An optional pattern (regexp) may be used for selecting files.
#------------------------------------------------------------------------------
sub Stat($@)
{
    my ($path,$patt) = _getParam( @_ );

    my $dir = Dir($path,$patt);

    my $stat;
    foreach my $f ( @{$dir} )
    {
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat("$path/$f");

        $stat->{$f}{'dev'}  = $dev;
        $stat->{$f}{'ino'}  = $ino;
        $stat->{$f}{'mode'} = $mode;
        $stat->{$f}{'nlink'}= $nlink;
        $stat->{$f}{'uid'}  = $uid;
        $stat->{$f}{'gid'}  = $gid;
        $stat->{$f}{'rdev'} = $rdev;
        $stat->{$f}{'size'} = $size;
        $stat->{$f}{'atime'}= $atime;
        $stat->{$f}{'mtime'}= $mtime;
        $stat->{$f}{'ctime'}= $ctime;
        $stat->{$f}{'blksize'}  = $blksize;
        $stat->{$f}{'blocks'}   = $blocks;
    }
    return $stat;
}

#------------------------------------------------------------------------------
# Jump to a callback function of a menu option.
#------------------------------------------------------------------------------
sub _jump($$)
{
    my ($o,$menu) = @_;

    return if( !defined $menu->[$o]->{'jump'} ); #option has no callback

    my $call = $menu->[$o]->{'jump'};
    my $args = defined $menu->[$o]->{'argv'} ? $menu->[$o]->{'argv'} : undef;

    if( ref $call eq 'CODE' ) { $call->($args); return; }
    Log("\nERROR: Can't call function $call(). It's not a code reference.");
    sleep 5;
}

#------------------------------------------------------------------------------
# Compute the maximum length of all labels found in the menu array @{$opts}.
#------------------------------------------------------------------------------
sub _maxLabelLength($)
{
    my ($opts) = @_;
    my $len=0;
    foreach my $op ( @{$opts} )
    {
        next  if( ! defined $op->{'label'});
        my $l = length($op->{'label'});
        $len = $len < $l ? $l : $len;
    }
    return $len;
}

#------------------------------------------------------------------------------
# Compute the default value and the format string.
#------------------------------------------------------------------------------
sub _getDefForm($$)
{
    my ($form1,$op) = @_;

    my $def;
    $def = $op->{'value'}   if( defined $op->{'value'} );
    my $form;
    if( $op->{'readOnly'} ) { $form = defined $def ? "$form1 <%s>" : $form1 }
    else                    { $form = defined $def ? "$form1 [%s]" : $form1 }

    return $def,"$form\n";
}

#------------------------------------------------------------------------------
# Remove last entered character from input. Move cursor one position backward.
#------------------------------------------------------------------------------
sub _delLastChar(){
    printf "%c %c", 0x08, 0x08;     # backspace,blank,backspace
}

#------------------------------------------------------------------------------
# Print one character to STDOUT without buffering.
#------------------------------------------------------------------------------
sub _flushChar($){
    my ($char) = @_;
    my $old = $|;
    $| = 1;
    printf "%s", $char;
    $| = $old;
    return;
}

#------------------------------------------------------------------------------
# Check if first digit exeeds the range if used on ten-spot position. In this
# case we got a valid number in the range of 0-9.
#------------------------------------------------------------------------------
sub _unique($$){
    my ($o,$maxNum) = @_;
    return 1    if( $$o =~ s/^\n$/0/ ); # set default option 0 if we got ENTER
    return 1    if( $$o*10 > $maxNum);
}

#------------------------------------------------------------------------------
# Check if first digit is in range. \n is valid for special handling later.
#------------------------------------------------------------------------------
sub _invalid($$){
    my ($o,$maxNum) = @_;
    return 0    if( $o =~ /^\n$/ );
    return 0    if( $o <= $maxNum);
    return 1;
}

#------------------------------------------------------------------------------
# Read the next number from STDIN. Return 0 if given character is not a digit.
# Read two characters if max option number is greater than 9. 
# Valid option numbers are 0...99.
#------------------------------------------------------------------------------
sub _getNumber($) {
    my ($maxNum) = @_;

    my $o;
    while( 1 ) {
        $o=_getChar('^\d+$');
        next   if( _invalid($o,$maxNum) );
        last   if( _unique(\$o,$maxNum) );

        if( $maxNum > 9 ) {
            _flushChar($o);
            my $oo=_getChar('^\d+$');
            last    if( $oo eq "\n" );
            $o=10*$o+$oo;
        }
        last   if( $o <= $maxNum && $o > -1 );
        _delLastChar();
    }
    _delLastChar();
    _flushChar($o);
    return $o;
}
#------------------------------------------------------------------------------
# Read one character from STDIN. FIXME: stty method is not portable
#------------------------------------------------------------------------------
sub _getChar($)
{
    my ($patt) = @_;

    while( 1 ) {
        system "stty", '-echo', '-icanon', 'eol', "\001";
        my $key = getc(STDIN);
        system "stty",  'echo', 'icanon', 'eol', '^@'; # ASCII null
        return $key if( $key =~ /$patt/ );
        return $key if( $key =~ /\n/ ); # use default
    }
}

#------------------------------------------------------------------------------
# Read a line from STDIN and assign it to the "value" key of an menu option.
# Data structure: [{label=>,value=>,readOnly=>,jump=>,argv=>},...]
# After this function value=> has one of the following values:
# - the read line if not empty
# - the old value if read an empty line and an old value exists
# - the value is not changeable if the key readOnly is defined
#------------------------------------------------------------------------------
sub _setValue($)
{
    my ($o,$opts) = @_;

    return undef if( !defined $opts->[$o]{'value'} );

    my $op  = $opts->[$o];
    my $def = defined $op->{'value'} ? $op->{'value'} : '';

    return $def if( $op->{'readOnly'} );
    printf "\n%s [%s]:", $op->{'label'}, $def;

    my $resp = <STDIN>;
    chomp $resp;

    $resp = $def if( $resp eq '' );
    $resp = $op->{'default'} if( defined $op->{'default'} && $resp eq ' ' );
    $op->{'value'} = $resp;
    return $resp;
}

#------------------------------------------------------------------------------
# Return the options as array reference.
# If $opt is not already an array reference, it mut be a string like:
# '<sep><opt1><sep><opt2>...'
#------------------------------------------------------------------------------
sub _checkOptions($){
    my ($opt) = @_;

    return $opt if( ref $opt eq 'ARRAY');
    my ($sep,$opstr) = $opt =~ m/(.)(.*)/;
    my @Ops          = split /[$sep]/, $opstr;
    return \@Ops;
}

#------------------------------------------------------------------------------
# Add given $options as read only menu options to the menu with name $menuName
# in menu-container $m.
# $options: an array reference 
#           or a CSV like string (first character is the separator).
#           Such as: ',opt1,opt2,opt3'
# $defaults: a regular expression. If it matches against an option, this
# option gets into selected state.
#------------------------------------------------------------------------------
sub _ops2CheckBox($$$$){
    my ($m,$menuName,$options,$defaults) = @_;

    $options = _checkOptions($options);
    foreach my $x (@{$options}) {
        my $v = '';
           $v = $x =~ /$defaults/ ? 'x' : ''    if(defined $defaults);
        $m->addOption($menuName =>{'label'=>$x, 'value'=>$v, 'readOnly'=>1});
    }
    return;
}

#------------------------------------------------------------------------------
# Add the check box menu to the menus container $m.
#------------------------------------------------------------------------------
sub _ckeckBox2Container($$$){
    my ($m,$menuName,$header) = @_;

    $m->addMenu( {$menuName =>[{'header'=>$header}]});
    return;
}

#------------------------------------------------------------------------------
# Return the menuname if defined or a random number between 0 and 10000.
#------------------------------------------------------------------------------
sub _checkMenuName($){
    my ($name) = @_;

    return $name if( defined $name );
    return sprintf "TMP_%d", int(rand(10000));
}

#------------------------------------------------------------------------------
# Is $m  pointing to a menus container? If yes, do nothig otherwise return
# an empty menus container.
#------------------------------------------------------------------------------
sub _checkMenuContainer($){
    my ($m) = @_;
    return $m   if( ref $m eq 'Script::Toolbox::Util::Menus' ); 
    return Script::Toolbox::Util::Menus->new();
}

#------------------------------------------------------------------------------
# Return the labels of all selected and unselected options.
#------------------------------------------------------------------------------
sub _getOptStates($$){
    my ($m,$name) = @_;

    my $on = $m->getMatching($name,'.+','value','label');
    my $off= $m->getMatching($name,'^$','value','label');
    return {'on'=>$on,'off'=>$off};
}

#------------------------------------------------------------------------------
# Clear all option values of menu $menuName in container $m.
# Set the option with $label in selected state.
#------------------------------------------------------------------------------
sub _setRadioButton($$$){
    my ($m,$menuName,$label) = @_;

    my $lv = $m->getLabelValueHash($menuName);
    map { $lv->{$_} = '' } keys %{$lv};
    $lv->{$label} = 'x';
    $m->setValues($menuName,$lv);
    return;
}
#------------------------------------------------------------------------------
# Set all option value to of-state except for the selected.
#------------------------------------------------------------------------------
sub _radioButton($$){
    my ($m,$name) = @_;

    while(1) {
        my $op = $m->run($name,1);
        my $cl = $m->currLabel($name);
        last    if( $cl eq 'RETURN' );
        _setRadioButton($m,$name,$cl);
    }
    return;
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _cleanUpTmps($){
    my ($m) = @_;

    my $def = $m->{'def'};
    foreach my $x (sort keys %{$def}) {
        next    if( $x !~ /^TMP_[0-9]+/ );
        delete $m->{'def'}{$x};
    }
    return;
}

#------------------------------------------------------------------------------
# If no      radio button checkbox accept all default patterns.
# If it's a  radio button checkbox accept only the first pattern (asume
# we have patterns like 'a|b|c'). Otherwise clear all defaults.
#------------------------------------------------------------------------------
sub _checkDefaults($$$){
    my ($m,$menuName,$defaults) = @_;

    my @x     = split /[|]/, $defaults;
    _setRadioButton($m,$menuName,$x[0]);
}

#------------------------------------------------------------------------------
# Display some options via menu.
# defaults: me|dk|ek
# Return a hash with two keys 'on' and 'off'. These keys points to arrays
# with option labels. 'on' means the value of this option is not an empty
# string.
#------------------------------------------------------------------------------
sub CheckBox($$@){
    my ($header,$options,$defaults,$radio,$m,$menuName) = @_;

    $menuName = _checkMenuName($menuName);
    $m        = _checkMenuContainer($m);
    if( ! defined $m->{'def'}{$menuName} ) {
        _ckeckBox2Container($m,$menuName,$header);
        _ops2CheckBox($m,$menuName,$options,$defaults);
    }
    _checkDefaults($m, $menuName, $defaults)    if($radio);
    $m->setHeader($menuName,$header);
    if($radio) { _radioButton($m,$menuName) }
    else       { $m->run($menuName,0)       }
    
    my $ret =  _getOptStates($m,$menuName); #{selected,unselected}
    _cleanUpTmps($m);
    return $ret;
} 
1;
__END__

=head1 NAME

Script::Toolbox::Util - see documentaion of Script::Toolbox

=cut

# vim: ts=4 sw=4 ai
