# $Date: 2003/05/31 18:16:43 $
# $Revision: 1.5 $ 


package Net::Z3950::AsyncZ::Errors;
use Event;
use Symbol;
use Exporter;
@ISA=qw (Exporter);
@EXPORT = qw(suppressErrors);
use strict;

{
my $_FH = \*STDOUT; 
my $_SAVESTDERR = \*STDERR;


sub _FH() { $_FH; }
sub _setFH { $_FH = $_[0]; }
sub _saveSTDERR { $_SAVESTDERR = $_[0]; }


my $_HOST = "";
my $_DB = "";
sub _setHost  { $_HOST = $_[0];  }
sub _getHost { $_HOST; }
sub _setDB  { $_DB = $_[0];  }
sub _getDB { $_DB; }

sub _getSaveErr { $_SAVESTDERR; }

my $_QUERY = "";
my $_SYNTAX= "";
sub _setQuery { $_QUERY = $_[0]; }
sub _setSyntax{ $_SYNTAX = $_[0]; }
sub _getQuery { $_QUERY; }
sub _getSyntax{ $_SYNTAX; }

my $ERROR_VAL = 225;
my $SUPPRESS_ERRORS = 0; 

sub suppress { $SUPPRESS_ERRORS = $_[0] if $_[0];  $SUPPRESS_ERRORS }
sub errorval { $ERROR_VAL; }

}

# when this is called, setting log=>suppressErrors(), then all error output is
# suppressed, including STDERR

sub suppressErrors { return Net::Z3950::AsyncZ::SuppressErr->new();}

sub fh { return _FH(); }

sub closelog { 
    my $fh = _FH();
    my $retv = close($fh) if $fh != \*STDOUT; 
    my $err = _getSaveErr();
    close STDERR and open STDERR, ">&SAVERR" if $err != \*STDERR;
    return $retv;
}

# To suppress errors set log => suppressErrors()

sub new {
my($class, $filespec, $server, $query, $syntax, $db) = @_;
my $handle = \*STDOUT;
_setHost($server) if $server;
_setQuery($query) if $query;
_setSyntax($syntax) if $syntax;
_setDB($db) if $db;


# DEFAULT:  write all error messages to terminal 

    if(ref $filespec eq 'Net::Z3950::AsyncZ::SuppressErr')
    {	           # redirect all system and lib messages to /dev/null
      open SAVERR, ">&STDERR" and _saveSTDERR(\*SAVERR); 
      open STDERR, ">>/dev/null" if(_getSaveErr() != \*STDERR); 
      suppress(1);
    }
    elsif($filespec) {  
        open (FH, ">>$filespec") and $handle = \*FH
 	  and open SAVERR, ">&STDERR" and _saveSTDERR(\*SAVERR);
          if(_getSaveErr() != \*STDERR) {
             open STDERR, ">>$filespec" and  select STDERR and $|=1; 
	     select STDOUT;
          }
    }
	
    _setFH($handle);

    $SIG{__WARN__} = \&sigHandler;
    $SIG{__DIE__} =  \&dieHandler;

    bless $handle, $class;

}

sub report_error {
my $parm = shift;
my $errno = shift;
my $handle;
my ($msg) = "Unspecified Error";

if (defined $errno) {
       $errno += errorval(); 
}
else { $errno = -1; }

if(ref $parm) {
  $handle = $parm;
}
else {
  $msg = $parm;
}

       if($handle) {
         $errno=$handle->errcode();
         $msg = $handle->errmsg(); 
         my $query = _getQuery();
         my $syntax = _getSyntax(); 
         if($msg) {                            
             $msg = "Error Number: $errno\n$msg\n";
             $msg .= "Query: $query\n";
             $msg .= "preferredRecordSyntax: $syntax\n" ;
             
          }
        }
    else {
      $msg = "[$errno] $msg";
   }
   sigHandler($msg);

}

sub reportNoEntries {
 my $fh = _FH();
 print $fh  "No Records for this Query\n" if(!suppress());
 pushErr("No Records for this Query");
}

sub dieHandler { 

 my ($pkg,$file, $line) = caller();
 my $errno = $! + 0; 
 sigHandler("[$errno] Die condition at $pkg; file: $file; line: $line\n" . $_[0] . "\n");


}

my $errorPrevious = 0;
sub sigHandler {
 no strict;
 local ($_sig) = @_;  
 my $sig = $_sig;
 use strict;
 my $_FH = _FH();
 _lock(_FH());

 exit $errorPrevious if  $errorPrevious;

 my $errno = errorval();
 if ($sig =~/^\[(\d+)\]/) {
      $errno = $1;
 }
 

 if(!suppress())  {    # this goes to Error Log
     print $_FH "\n--------------------\n\n"; 
     print $_FH scalar localtime, "\n";     
     my ($pkg,$file, $line, $sbr) = caller();
     my ($pkg_1,$file_1, $line_1, $sbr_1) = caller(1);
     my ($pkg_2,$file_2, $line_2, $sbr_2) = caller(2);
     my ($pkg_3,$file_3, $line_3, $sbr_3) = caller(3);
     print $_FH "Package: $pkg; file: $file; line: $line\n";

     print $_FH "Package: $pkg_1; file: $file_1; line: $line_1\n";
     print $_FH "Package: $pkg_2; file: $file_2; line: $line_2\n" if $pkg_2;
     print $_FH "Package: $pkg_3; file: $file_3; line: $line_3\n" if $pkg_3;

     print $_FH "Subroutine: $sbr\n", if $sbr; 

     print $_FH  "Host: ", _getHost(), "\n" if _getHost();
     print $_FH  "DB: ", _getDB(), "\n" if _getDB();
     print $_FH "$sig\n" if $sig;
     print $_FH "$!\n" if $errno != errorval();
     print $_FH "Unable to connect to ", _getHost(), ".\n" if !$sig;
 }
    # this is available for browser when not in async mode   
    pushErr("$!\n") if $errno != errorval();
    pushErr("Unable to connect to: ". _getHost() . "  " . _getDB());
    $errorPrevious = $errno;
   _unlock(_FH());

   exit $errno;
}



my $LOCK_EX = 2;  # Exclusive lock. 
my $LOCK_UN = 8;  # Unlock.

sub _lock {

  flock $_[0], $LOCK_EX;
  seek $_[0], 0, 2;  # seek end of file   
}


sub _unlock {
 flock $_[0], $LOCK_UN;
}


{
  my @ErrorStack=();
 
 sub pushErr { 
      foreach my $err(@_) {
         push(@ErrorStack, $err);
      }
  }

 sub popErrs {
    return if !@ErrorStack;
    foreach my $err(@ErrorStack) {
      print STDOUT  $err,"\n";
    }

  }

 sub getErrs { 
     return () if !@ErrorStack; 
     return @ErrorStack; 
 }
}


package Net::Z3950::AsyncZ::SuppressErr;

# return a blank marker class to signal suppression of error output
sub new {  bless {}, $_[0]; }
1;

