#
# $Id: Startup.pm,v 0.24 1998/04/28 00:38:41 schwartz Exp $
#
# Startup, module to write batch programs easier 
#
# Copyright (C) 1997 Martin Schwartz. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Documentation at end of file.
#
# Contact: schwartz@cs.tu-berlin.de
#

package Startup;
use strict;
my $VERSION=do{my@R=('$Revision: 0.24 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};

use Cwd 'cwd';
use Symbol;

my $DEFAULT_DIRMODE  = "0700";
my $DEFAULT_FILEMODE = "0600";

##
## --- Init ---------------------------------------------------------------
##

sub new {
#
# $ref||undef = Startup->new()
#
   $|=1;
   my $proto = shift;
   my $S = bless ({}, ref($proto) || $proto);
   $S -> err_reset();
   $S -> msg_reset();
   $S -> msg_silent(0);
   $S -> forbid_logging;
   $S -> err_strpat('$err_package: $err_str');
   $S -> err_infopat('$err_info');
   $S -> log_openpat ('----------  $date, $prog_name $prog_ver '."(perl $])\n");
   $S -> log_threshold (0xffffffff);
   $S -> catch_reset;
   $S;
}

sub DESTROY {
   my ($S) = @_;
   $S->restore_output();
}

sub _member { my $S=shift; my $n=shift; $S->{$n}=shift if @_; $S->{$n} }

sub _cur_path      { shift->_member("CURPATH", @_) }
sub src_base       { shift->_member("BASEDIR", @_) }
sub dest_base      { shift->_member("DESTDIR", @_) }

sub sub_stream     { shift->_member("FLOW_SUB_STREAM", @_) }
sub sub_files      { shift->_member("FLOW_SUB_FILE", @_) }
sub from_stdin     { shift->_member("FLOW_FROM_STDIN", @_) }
sub dirmode        { shift->_member("FLOW_DIRMODE", @_) }
sub filemode       { shift->_member("FLOW_FILEMODE", @_) }
sub recurse        { shift->_member("FLOW_RECURSE", @_) }
sub relative       { shift->_member("FLOW_RELATIVE", @_) }

sub prog_date      { shift->_member("I_DATE", @_) }
sub prog_name      { shift->_member("I_NAME", @_) }
sub prog_ver       { shift->_member("I_VER", @_) }

##
## --- Flow ---------------------------------------------------------------
##

sub go {
   my $S = shift;

   return $S->_fail ("No working function for files specified!") 
      if !$S->sub_files()
   ;
   if ($S->from_stdin) {
      return $S->_fail ("Application didn't specify a stream input function!") 
         if !$S->sub_stream()
      ;
   } else {
      return 1 if !@_;
   }

   $S-> _cur_path(cwd());
   return $S -> _fail () if !$S->_mkdir ($S->dest_base);
   return $S -> _fail () if !$S->_chdir ($S->src_base);
   $S -> src_base(cwd());
   return $S -> _fail () if !$S->_chdir ($S->dest_base);
   $S -> dest_base(cwd());
   return $S -> _fail () if !$S->_chdir ($S->_cur_path);

   if ($S->from_stdin) {
      $S->msg_error() if !&{$S->sub_stream}($S->dest_base);
   } else {
      for (@_) {
         $S->msg_error() if !$S->_do_work($_);
      }
   }
1}

sub init {
   my ($S, $opt) = @_;
   $S->sub_files   ($opt->{SUB_FILES});
   $S->sub_stream  ($opt->{SUB_STREAM});

   $S->prog_date   ($opt->{PROG_DATE});
   $S->prog_name   ($opt->{PROG_NAME});
   $S->prog_ver    ($opt->{PROG_VER});
                   
   $S->dirmode     ($opt->{DIRMODE}       || $DEFAULT_DIRMODE );
   $S->filemode    ($opt->{FILEMODE}      || $DEFAULT_FILEMODE );
   $S->from_stdin  ($opt->{FROM_STDIN}    || 0 );
   $S->recurse     ($opt->{RECURSE}       || 0 );
   $S->relative    ($opt->{RELATIVE}      || 0 );
   $S->dest_base   ($opt->{DESTPATH}      || '.' );
   $S->src_base    ($opt->{SRCPATH}       || '.' );
                   
   $S->log_path    ($opt->{LOGPATH}       || $S->prog_name().".log" );
1}

sub _fail {
   my ($S, $msg) = @_;
   return $S -> msg_error ($msg);
}

sub _do_work {
   my ($S, $file) = @_;
   my ($sp, $sf, $dp) = $S->_get_real_pathes($file);
   return 0 if !$sp;
   #print "\nsp=$sp  sf=$sf\ndp=$dp\n";
   my $rp = "$sp/$sf";
   if (-f $rp) {
      return &{$S->sub_files}($sp, $sf, $dp, 1);
   } elsif (-d $rp) {
      if ($S->recurse) {
         my $dirh = gensym;
         return $S->error("Cannot open directory \"$sp/$sf\"")
            if !opendir $dirh, "$sp/$sf"
         ;
         my @files = readdir ($dirh);
         closedir $dirh;
         for (@files) {
            next if /^\.$/ || /^\.\.$/;
            $S->_do_work("$rp/$_");
         }
         return 1;
      } else {
         # Entry is a directory. Give it to applying code with status -1.
         return &{$S->sub_files}($sp, $sf, $dp, -1);
      }
   } else {
      # File doesn't exist. Give it to applying code with status 0.
      return &{$S->sub_files}($sp, $sf, $dp, 0);
   }
1}

##
## --- Error --------------------------------------------------------------
##
## Very basics. Once it will get worked out...
##

sub _error { shift->_member("E_ERR", @_) }

sub _err_member {
   my ($S, $type) = (shift, shift);
   my $Err = $S -> _err;
   $Err -> {$type} = shift if @_;
   $Err -> {$type};
}

sub err_caller { shift -> _err_member("CALLER", @_) }
sub _err_str   { shift -> _err_member("STR", @_) }
sub _err_num   { shift -> _err_member("NUM", @_) }
sub _err_info  { shift -> _err_member("INFO", @_) }

sub err_strpat     { shift -> _member("E_STRPAT", @_) }
sub err_infopat    { shift -> _member("E_INFOPAT", @_) }

sub err_prev       { shift -> _err_pop; 0 }

sub err_reset {
   my ($S) = @_;
   $S -> _error ([]);
}

sub _err_pop {
   my ($S) = @_;
   pop (@{$S->_error});
}

sub _err_push {
   my ($S, $errH) = @_;
   push (@{$S->_error}, $errH);
}

sub _err {
   my ($S) = @_;
   $S->_error->[$#{$S->_error}];
}

sub err_str { 
   my ($S, $str) = @_;
   $S -> error ($str) if $str;
   $S -> gimmick ($S->err_strpat);
}

sub err_info { 
   my ($S, $str) = @_;
   $S -> error ("", 0, $str) if $str;
   $S -> gimmick ($S->err_infopat);
}

sub err_num { 
   my ($S, $num) = @_;
   $S -> error ("", $num) if $num;
   $S -> _err_num;
}

sub error {
   my ($S, $str, $num, $long) = @_;
   my $Err = $S->_err || {};
   $S -> _err_push ({
      "CALLER" => [caller()],
      "STR"    => $str  || $Err->{"STR"},
      "NUM"    => $num  || $Err->{"NUM"},
      "INFO"   => $long || $Err->{"INFO"},
   });
0}

##
## --- Message ------------------------------------------------------------
##

sub charset        { shift->_member("M_CHARSET", @_) }

sub msg_autoindent { shift->_member("M_AUTO", @_) }
sub msg_beauty     { shift->_member("M_BEAUTY", @_) }
sub msg_indent     { shift->_member("M_INDENT", @_) }
sub msg_maxcolumn  { shift->_member("M_MAXCOLUMN", @_) }
sub msg_silent     { shift->_member("M_SILENT", @_) }
                  
sub _msg_begin     { shift->_member("M_BEGIN", @_) }
sub _msg_column    { shift->_member("M_COLUMN", @_) }
sub _msg_continue  { shift->_member("M_CONTINUE", @_) }
sub _msg_finished  { shift->_member("M_FINISHED", @_) }

sub msg_reset {
   my $S = shift;
   $S->charset($ENV{LC_CTYPE}) if $ENV{LC_CTYPE};

   $S->msg_autoindent(1);
   $S->msg_beauty(1);
   $S->msg_indent(4);
   $S->msg_maxcolumn(79);

   $S->_msg_begin(1);
   $S->_msg_column(0);
   $S->_msg_continue(1);
   $S->_msg_finished(0);
$S}

sub _print {
   my ($S, $txt) = @_;
   if ($S->_redir_stdout) {
      my $sym = $S->_real_stdout();
      print $sym $txt;
   } else {
      print STDOUT $txt;
   }
}

sub _msg {
   my ($S, $msg, $sep) = @_;
   $msg="" if !$msg;
   return 1 if $S->msg_silent();
   if ($S->_msg_continue) {
      if ($S->msg_beauty) {
         if ( (($S->_msg_column+length($msg)) > $S->msg_maxcolumn)
              && (length($msg) < $S->msg_maxcolumn)
         ) {
            $S->_print("\n" . (" "x$S->msg_indent));
            $S->_msg_column($S->msg_indent);
         } else {
            $msg = "$sep$msg" if $sep;
         }
         $S->_msg_column ($S->_msg_column+length($msg));
      } else {
         $msg = "$sep$msg" if $sep;
      }
      $S->_print("$msg") if $msg;
   } else {
      $msg =~ s/^\s*//;
      substr($msg, 0, 1) =~ tr/a-zäöü/A-ZÄÖÜ/;
      $S->_print("$msg\n") if $msg;
   }
1}

sub msg {
   my ($S, $msg, $nl) = @_;
   if ($S->_msg_continue) {
      if ($S->_msg_begin==1) {
         my $pos = length($msg)+2;
         if ($msg =~ /\s/g) {
            $pos = pos($msg); 
         }
         $S->msg_indent($pos) if $S->msg_autoindent();
         $S->_msg(ucfirst($msg).($nl?"":":"));
         $S->_msg_begin(2);
      } elsif ($S->_msg_begin==2) {
         $S->_msg(" $msg" . ($nl?"":", "));
         $S->_msg_begin(0);
      } else {
         $S->_msg($msg . ($nl?"":", "));
      }
   } else {
      $S->_msg($msg);
   }
}

sub msg_nl {
   my ($S, $msg) = @_;
   $S->msg("$msg\n", 1);
   $S->_msg_continue(0);
}

sub msg_warn {
   my ($S, $msg) = @_;
   $S->msg("$msg!");
}

sub msg_finish {
   my ($S, $msg) = @_;
   return if $S->_msg_finished;
   if ($msg) {
      $S->msg_nl("$msg.");
   } else {
      $S->msg_nl("");
   }
   $S->_msg_finished(1);
}

sub msg_error {
   my ($S, $msg) = @_;
   $S->msg_nl("error!");
   my $silent = $S->msg_silent();
   $S->msg_silent(0);
   $S->err_caller ([caller(1)]) if $msg;
   $S->msg("Error: ".$S->err_str($msg));
   $S->msg_silent($silent);
0}

##
## --- Logging ------------------------------------------------------------
##

sub allow_logging  { shift->_nolog(0) }
sub forbid_logging { shift->_nolog(1) }
sub log_openpat    { shift->_member("L_OPENPAT", @_) }
sub log_threshold  { shift->_member("L_THRESH", @_) }
sub _nolog         { shift->_member("L_NOT", @_) }
sub _log_open      { shift->_member("L_OPEN", @_) }
sub _log_path      { shift->_member("L_PATH", @_) }
sub _log_handle    { shift->_member("L_HANDLE", @_) }

sub _init_log {
   my $S = shift;
   $S->_log_open(0);
   $S->_log_handle(gensym);
   my $logfile = $S->_log_path;
   $logfile = "./$logfile" if $logfile !~ /^\//;
   my $ln = substr($logfile, rindex($logfile,'/')+1);
   return 0 if !$S->_chdir (substr($logfile, 0, rindex($logfile,'/')));
   my $lp = cwd();
   $S->_log_path ("$lp/$ln");
}

sub log_path {
   my $S = shift;
   $S->_log_path(@_) if !$S->_log_open;
   $S->_log_path();
}

sub open_log {
   my $S = shift;
   return $S->error("Logging not allowed!") if $S->_nolog;
   return $S->error("Logfile already open!") if $S->_log_open;
   $S->_init_log;
   my $ex = -e $S->_log_path;
   my $sym=$S->_log_handle();
   if (open($sym, ">>".$S->_log_path)) {
      chmod (oct($S->filemode), $S->_log_path) if !$ex;
      $_=select($sym); $|=1; select($_);
      $S->_log_open(1);
      print($sym $S->gimmick ($S->log_openpat));
      $S->log("open log");
   } else {
      $S -> forbid_logging;
      $S -> error ("Cannot open logfile \"".$S->_log_path()."\"");
   }
}

sub close_log {
   my ($S) = @_;
   if (!$S->_nolog && $S->_log_open) {
      my $sym = $S->_log_handle;
      $S->log("close log\n");
      close($sym);
   }
1}

sub log {
   my ($S, $txt, $pri, $thresh) = @_;
   return $S->error("Logging not allowed!") if $S->_nolog;
   return $S->error("No logfile!") if $S->_nolog;
   $thresh=0 if !$thresh; return 1 if $thresh > $S->log_threshold;
   my $sym = $S->_log_handle;
   print($sym (
      ($pri||" ")
      .$S->gimmick(' $H:$M:$S  '.$txt."\n")
   ));
1}

##
## --- Redirect -----------------------------------------------------------
##

sub catch_reset {
   my ($S) = @_;
   $S -> restore_output();
   $S -> catch_output_pattern ('^(.*)$');
   $S -> catch_output_sub(0);
   $S -> _redir_stdout(0);
   $S -> _redir_stderr(0);
}

sub _real_stdout      { shift->_member("RED_R1", @_) }
sub _real_stderr      { shift->_member("RED_R2", @_) }
sub _redir_stdout     { shift->_member("RED_1", @_) }
sub _redir_stderr     { shift->_member("RED_2", @_) }
sub _redir_stdout_pid { shift->_member("RED_1_PID", @_) }
sub _redir_stderr_pid { shift->_member("RED_2_PID", @_) }

sub catch_stdout_sub     { shift->_member("RED_Sub1", @_) }
sub catch_stderr_sub     { shift->_member("RED_Sub2", @_) }
sub catch_stdout_pattern { shift->_member("RED_Pat1", @_) }
sub catch_stderr_pattern { shift->_member("RED_Pat2", @_) }

sub catch_output_pattern {
   my ($S, $pattern) = @_;
   $S -> catch_stdout_pattern ($pattern);
   $S -> catch_stderr_pattern ($pattern);
}

sub catch_output_sub {
   my ($S, $Sub)=@_; $S->catch_stdout_sub($Sub); $S->catch_stderr_sub($Sub);
}

sub catch_output {
   my ($S) = @_; $S->catch_stdout(); $S->catch_stderr();
}

sub restore_output {
   my ($S) = @_; $S->restore_stdout(); $S->restore_stderr();
}

sub catch_stdout { my ($S, $modepath)=@_; $S->_catch_handle(1, $modepath) }
sub catch_stderr { my ($S, $modepath)=@_; $S->_catch_handle(2, $modepath) }

sub _catch_handle {
   no strict;
   my ($S, $type, $modepath) = @_;
   my ($handle, $mode, $n, $sym);
   $mode = ($modepath ? 1 : 2);

   if ($type==1) {
      return 1 if $S->_redir_stdout==$mode;
      $handle="STDOUT"; 
   } elsif ($type==2) {
      return 1 if $S->_redir_stderr==$mode;
      $handle="STDERR";
   } else {
      return $S->error("Bad handle type");
   }

   $S->_restore_handle($type);

   $sym = gensym;
   $n = fileno $handle;
   return $S->error("Cannot open $handle") if !open ($sym, ">&$n");

   if ($mode==1) {
      return $S->error("Cannot redirect $handle to file") 
         if !open ($handle, "$modepath")
      ;
   } else {
      my $pid; my $count=0;
      do {
         $pid = open($handle, "|-");
         unless (defined $pid) {
            return $S->error("Cannot redirect $handle to process") 
               if $count++ > 5;
            ;
            sleep 10;
         }
      } until defined $pid;
      if ($pid) {
         # Parent
         if ($type==1) {
            $S->_redir_stdout_pid($pid);
         } else {
            $S->_redir_stderr_pid($pid);
         }
      } else {
         # Child
         select STDIN; $|=1; $/="\n";
         while (<>) {
            s/^\s*//;
            s/\s*$//;
            next if !$_;
            if ($type==1) {
               my $pat = $S->catch_stdout_pattern();
               /$pat/i; $_= $1; next if !$_;
               my $sub = $S->catch_stdout_sub();
               if ($sub) {
                  &$sub($_);
               } else {
                  $S->msg($_)
               }
            } else {
               my $pat = $S->catch_stderr_pattern();
               /$pat/i; $_=$1; next if !$_;
               my $sub = $S->catch_stderr_sub();
               if ($sub) {
                  &$sub($_);
               } else {
                  $S->error($_);
                  $S->err_caller([caller(2)]);
                  $S->msg_error();
               }
            }
         }
         exit 0;
      }
   }

   select $handle; $|=1;
   if ($type == 1) {
      $S->_real_stdout($sym); $S->_redir_stdout($mode);
   } else {
      $S->_real_stderr($sym); $S->_redir_stderr($mode);
   }
1}

sub restore_stdout { shift -> _restore_handle(1) }
sub restore_stderr { shift -> _restore_handle(2) }

sub _restore_handle {
   no strict;
   my ($S, $type) = @_;
   my ($handle, $sym, $mode);

   if ($type==1) {
      return 1 if !($mode=$S->_redir_stdout);
      $handle="STDOUT"; $sym = $S->_real_stdout();
   } elsif ($type==2) {
      return 1 if !($mode=$S->_redir_stderr);
      $handle="STDERR"; $sym = $S->_real_stderr();
   } else {
      return $S->error("Bad handle type");
   }

   return $S->error("Cannot close $handle") if !close ($handle);
   my $n = fileno $sym;
   if (!open ($handle, ">&$n")) {
      close $sym; return $S->error("Cannot restore $handle");
   }
   close $sym;
   select $handle; $|=1;

   if ($mode==2) {
      my $pid = ($type==1 ? $S->_redir_stdout_pid : $S->_redir_stderr_pid);
      waitpid($pid, 0);
   }

   $type==1 ? $S->_redir_stdout(0) : $S->_redir_stderr(0);
1}


##
## --- Misc ---------------------------------------------------------------
##

sub gimmick {
   my ($S, $txt) = @_;
   return $txt if !$txt=~/\$/;

   my @date = map sprintf("%02d", $_), localtime(time);
   my @error = ();
   @error = @{$S->err_caller()} if $S->err_caller();

   my %gimmick = (
      # date / time
      "S" => $date[0],
      "M" => $date[1],
      "H" => $date[2],
      "d" => $date[3],
      "m" => $date[4]+1,
      "y" => $date[5]+1900,
      "date" => $date[3].".".($date[4]+1).".".($date[5]+1900),
      "time" => "$date[2]:$date[1]:$date[0]",

      # error
      "err_str" => $S->_err_str() || "unknown error",
      "err_num" => $S->_err_num() || 0,
      "err_info" => $S->_err_info() || "",
      "err_package" => $error[0],
      "err_filename" => $error[1],
      "err_line" => $error[2],

      # program
      "prog_name" => $S->prog_name,
      "prog_date" => $S->prog_date,
      "prog_ver" => $S->prog_ver,
   );

   for (sort {length($a) < length($b)} keys %gimmick) {
      $txt =~ s/\$$_/$gimmick{$_}/g;
   }

   $txt;
}

sub _chdir {
   my ($S, $dir) = @_;
   return $S->error("Cannot enter directory \"$dir\"!") if !chdir($dir);
1}

sub _mkdir {
   my ($S, $dp) = @_;
   if (!-d $dp) {
      if (!mkdir $dp, oct($S->dirmode)) {
         return $S->error ("Cannot create directory \"$dp\"");
      }
      $S -> msg_nl ("created directory \"$dp\"");
   }
1}

sub _mkpath {
#
# Creates one or a chain of directories, if $base is base of $dp
#
   my ($S, $dp, $base) = @_;
   if ($dp =~ /^$base/) {
      my $current=$base;
      for (grep {$_} split /\//, $') {
         $current .= "/$_";
         return 0 if !$S->_mkdir($current);
      }
   }
1}

sub _get_real_pathes {
#
# ($src_relativepath||$src_path, $src_file_without_path, $destination_path) =
#    _get_pathes ($src_file_with_path)
# ;
# 
# evaluates $opt{"relative"};
#   
   my ($S, $fn) = @_;
   my ($sp, $sf, $dp);

   my $src_base = $S->src_base;
   ($sp, $sf) = $S->_realpath($fn, $src_base);
   return 0 if !$sp;

   $dp = $S->dest_base;
   if ($S->relative) {
      $dp .= $' if $sp =~ /^$src_base/;
   } 
   return 0 if !$S->_mkpath($dp, $S->dest_base);

   $sp =~ s/^$src_base/./; 
   ($sp, $sf, $dp);
}

sub _realpath {
#
# ($file_path, $file_without_path) = _realpath ($file_with_path, $src_base)
#
   my ($S, $file, $src_base) = @_;
   $src_base = "." if !$src_base;

   # add basepath, if path is not absolute
   $file = "$src_base/$file" if $file !~ /^\//;

   my $fn = substr($file, rindex($file,'/')+1);
   return 0 if !$S->_chdir (substr($file, 0, rindex($file,'/')));
   my $fp = cwd();

   return 0 if !$S->_chdir ($S->_cur_path);
   ($fp, $fn);
}

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

Startup - A program flow utility.

I<ALPHA> version as of C<$Date: 1998/04/28 00:38:41 $>

=head1 SYNOPSIS

Have a look at demonstration utility "replace" and at more detailed
description below. It might be useful to use "replace" generally as
frame for new programs.

=head1 DESCRIPTION

As developing with perl you certainly appreciate it to write easily nifty 
programs. Unfortunately a bunch of boring problems makes life uncomfortable.
With some of them I had to deal so often, that I created this little 
collection. Imagine:

=over 4

=item -

You want to have an option to work on files recursively.

=item -

You want some modules to print some info during work, but this output
would hardly be predictable and thus might destroy your program output.

=item -

You want to have a little logfile reporting actions.

=item -

You want to report errors, but not via "die", and you dislike to write
trapping code all the time.

=back

This module shall contribute to solve those problems, making your 
your programs more valuable.

=head1 INIT METHODS

=over 4

=item new

I<$S> = new S

This is the modules constructor. Some basic initializations are done,
as there are: msg_reset and forbid_logging are called; err_strpat,
err_infopat and log_openpat are initialized and log_threshold is set
to infinity.

=item init

C<1> = I<$S> -> init ({
   SUB_FILES  => I<\&sub>,    # no default
   SUB_STREAM => I<\&sub>,    # no default
   PROG_DATE  => I<$date>,    # no default
   PROG_NAME  => I<$name>,    # no default
   PROG_VER   => I<$version>, # no default
   DIRMODE    => I<$string>,  # Default: "0700"
   FILEMODE   => I<$string>,  # Default: "0600"
   FROM_STDIN => C<1>||C<0>,     # Default: 0
   RECURSE    => C<1>||C<0>,     # Default: 0
   RELATIVE   => C<1>||C<0>,     # Default: 0
   DESTPATH   => I<$path>,    # Default: '.'
   SRCPATH    => I<$path>,    # Default: '.'
   LOGPATH    => I<$path>,    # Default: "$prog_name.log"
})

This method you normally will have to call. Via this you pass information
like recursive and / or relative mode, program name and version and so on.
Init method will provide some default values. 

Init is called with an anonymous hash as parameter list. Each parameter
you can change afterwards with an extra method. Quite necessary (but this
depends on your wishes) is to init at least SUB_FILES and PROG_NAME.

=item go

C<1>||C<0> = I<$S> -> go (I<@pathes>)

Works differently for stream mode and file mode. Anyway go will call
a function in your application, that needs to return a true value (1) 
if successful. If your function returns a zero, go will call msg_error().

Method go normally always returns 1. Zero is returned, when SUB_FILES
or SUB_STREAM is needed but not defined, or if src_base or current
directory is not available.

=over 4

=item go: stream mode

Message mode is set to silent. Function provided via SUB_STREAM is called 
with parameter dest_path.

=item go: file mode

Function provided via SUB_FILES is called for each input file. Parameters
are (Source_purepath I<$sp>, Source_purefilename I<$sf>, Destination_path
I<$dp>, I<$status>).

Thus path for input file would be: "I<$sp>/I<$sf>". I<$dp> will be the path 
provided via DESTPATH if either relative mode is unset, or the input file
path is not relative to the path provided via SRCPATH. If in relative mode
and input file has a path relative to SRCPATH, I<$dp> will get that relative
part starting from DESTPATH.

I<$status> will be C<1> if input file is a file, C<0> if file doesn't 
exist and C<-1> if file is no file but a directory.

=back

=item sub_stream

I<\&function> = I<$S> -> sub_stream ([I<\&function>])

Returns (optionally sets) the function doing the work when in stream mode.

=item sub_files

I<\&function> = I<$S> -> sub_files ([I<\&function>])

Returns (optionally sets) the function doing the work when in file mode.

=item src_base

I<$path> = I<$S> -> src_base ([I<$path>])

Returns (optionally sets) the base path for source input files. 

=item dest_base

I<$path> = I<$S> -> dest_base ([I<$path>])

Returns (optionally sets) the base destination path for your output files. 

=item from_stdin

C<1>||C<0> = I<$S> -> from_stdin ([C<1>||C<0>])

Returns (optionally sets) stream mode.

=item dir_mode

I<$mode_string> = I<$S> -> dir_mode ([I<$mode_string>])

Returns (optionally sets) the owning mode when creating a new directory.
Mode is evaluated as an octal number in string representation, e.g. "0700".

=item file_mode

I<$mode_string> = I<$S> -> file_mode ([I<$mode_string>])

Returns (optionally sets) the owning mode when creating a file (as of now
this is only when creating logfile). Mode is evaluated as an octal number 
in string representation, e.g. "0700".

=item recurse

C<1>||C<0> = I<$S> -> recurse ([C<1>||C<0>])

Returns (optionally sets) recurse mode. When in recurse mode, directories
and directories in directories and ... of input file list will be scanned 
also.

=item relative

C<1>||C<0> = I<$S> -> relative ([C<1>||C<0>])

Returns (optionally sets) relative mode. Effects only in recurse mode. When in 
relative mode, output pathes will be created according to input path structure
relatively to input base path. E.g.:

Input base path is C</cdrom>. Scan path is C</cdrom>. Output path is C<.>.
Then starting at path C<.> the same directory structure as in /cdrom/ would
be created and passed to sub_files function as output path.

=item prog_date

I<$date> = I<$S> -> prog_date ([I<$date>])

Returns (optionally sets) date of application programs creation.

=item prog_name

I<$name> = I<$S> -> prog_name ([I<$name>])

Returns (optionally sets) name of application program.

=item prog_ver

I<$ver> = I<$S> -> prog_ver ([I<$ver>])

Returns (optionally sets) version of application program.

=back

=head1 ERROR METHODS

Error is just a way to get around C<$!>. It is little more than a place to 
store an error message. It allows you to return 0 as error indicator in a 
pure procedurale way over several returns and still to comprise "last error"
information. 

=over 4

=item error

C<0> = I<$S> -> error (I<$string>, I<$number>, I<$longinfo>)

Saves error message I<$string>, error number I<$number>, extra error
information I<$longinfo> and caller() info. Returns always zero.

=item err_caller

I<\@err_caller> = I<$S> -> err_caller (I<[caller()]>)

Returns (and optionally sets) a reference to a caller() array (see: man
perlfunc). It has the entries (package, filename, line). It is 
automatically set to "caller()" when calling C<error> method.

=item err_info

I<$err_info> = I<$S> -> err_info ([I<$err_info>])

Returns (and optionally sets) error info message, formatted according to
I<err_infopat>.

=item err_infopat

I<$err_infopat> = I<$S> -> err_infopat ([I<$err_infopat>])

Gimmick pattern for method err_info. Defaults to C<'$err_info'>.
(See method gimmick below at misc section for details)

=item err_num

I<$err_num> = I<$S> -> err_num ([I<$err_num>])

Returns (and optionally sets) error number.

=item err_str

I<$err_str> = I<$S> -> err_str ([I<$err_str>])

Returns (and optionally sets) error message, formatted according to 
I<err_strpat>.

=item err_strpat

I<$err_strpat> = I<$S> -> err_strpat ([I<$err_strpat>])

Gimmick pattern for method err_str. Defaults to C<'$err_package: $err_str'>.
(See method gimmick below at misc section for details)

=back

=head1 MESSAGE METHODS

Message is a userEss interface allowing you to pass some runtime information
to C<stdout>.

=over 4

=item msg

C<1> = I<$S> -> msg (I<$str>)

Prints message I<$str>. Appends C<':'> if it is 1st message, inserts C<' '> 
if it is 2nd, appends C<', '> otherwise.

=item msg_error

C<0> = I<$S> -> msg_error ([I<str>])

Calls C<msg_nl ("error!")> and then C<msg ("Error: " . $S->err_str())>.
Latter message will be sent even in "silent" mode (see msg_silent).

=item msg_finish

C<1> = I<$S> -> msg_finish (I<$str>)

Calls C<msg_nl ("$msg.")> unless msg_finish is already called.

=item msg_nl

C<1> = I<$S> -> msg_nl (I<$str>)

Prints message I<$str> with a trailing newline C<\n>. Disables internal 
"continue" mode: further messages will always be sent as msg_nl.

=item msg_warn

C<1> = I<$S> -> msg_warn (I<$str>)

Appends a C<'!'> to message I<$str>.

=back

=head1 MESSAGE INIT METHODS

=over 4

=item charset

I<$charset_id> = I<$S> -> charset ($charset_id)

Sets standard character set to I<$charset_id>. It defaults to $ENV{LC_CTYPE}.
It's main purpose is for future releases.

=item msg_reset

I<$S> = I<$S> -> msg_reset ()

Resets message variables to default values. You will call this normally
always when starting a new work a la: 'Processing xyz'.

=item msg_autoindent

C<1>||C<0> = I<$S> -> msg_autoindent ([C<1>||C<0>])

Defaults to 1. Returns (optionally sets) autoindent mode. When set,
msg_indent will be automatically set to the position after the first 
whitespace in the first message. (see also msg_beauty)

=item msg_beauty

C<1>||C<0> = I<$S> -> msg_beauty ([C<1>||C<0>])

Defaults to 1. Returns state of (optionally sets) "beauty" mode. When an output 
line gets longer than msg_maxcolumn and internal "continue" mode is set, a 
newline and an indent is inserted. Internal continue mode is unset when calling
msg_nl method.

=item msg_indent

I<$pos> = I<$S> -> msg_indent ([I<$pos>])

Defaults to 4. Returns (optionally defines) the indent for beauty mode. This 
value is overridden when msg_autoindent is set.

=item msg_maxcolumn

I<$pos> = I<$S> -> msg_maxcolumn ([I<$pos>])

Defaults to 79. Returns (optionally sets) the maximal length of an output
line, when in beauty mode.

=item msg_silent

C<1>||C<0> = I<$S> -> msg_silent ([C<1>||C<0>])

Defaults to 0. Returns (optionally sets) silent mode. When set to 1, 
no message except error messages will be printed to stdout.

=back

=head1 LOGGING METHODS

=over 4

=item allow_logging

C<1> = I<$S> -> allow_logging ()

You have to call this to enable logging.

=item forbid_logging

C<0> = I<$S> -> forbid_logging ()

This is default. It forbids methods open_log and log, so that they will
return always an error. No logfile will be opened, no log entry being
written.

=item log_openpat

I<$pat> = I<$S> -> log_openpat ([I<$pat])

Returns (optionally sets) the gimmick pattern used for log opening entries.
Defaults to: C<'----------  $date, $prog_name $prog_ver '."(perl $])\n">

=item log_path

I<$path> = I<$S> -> log_path ([I<$path>])

Returns (optionally sets) path/name of logfile to I<$path>. This overrides
the default value set when calling S->init. Default is file
C<basename($prog_name).".log"> in current directory.

=item open_log

C<1>||C<0> = I<$S> -> open_log ()

Opens the logfile I<$S> -> log_path.

=item close_log

C<1> = I<$S> -> close_log ()

Closes logfile.

=item log

C<1>||C<0> = I<$S> -> log (I<$msg>, I<$pri>, I<$threshold>)

Adds a log message I<$msg>, getting the priority character I<$pri>.
If a threshold is given, log this entry only if threshold is smaller
or equal I<$S> -> log_threshold.

=item log_threshold

I<$threshold> = I<$S> -> log_threshold ([I<$threshold>])

Defaults to 0xffffffff. Returns (optionally sets) logging threshold. If 
set, only log calls with a threshold smaller or equal than this threshold 
will be logged.

=back

=head1 REDIRECTION METHODS

=over 4

=item catch_output

C<1>||C<0> = I<$S> -> catch_output([I<$mode_path>])

C<1>||C<0> = I<$S> -> catch_stdout([I<$mode_path>])

C<1>||C<0> = I<$S> -> catch_stderr([I<$mode_path>])

=over 4

=item catch_output File mode

If parameter I<$mode_path> is specified, STDOUT+STDERR / STDOUT / STDERR
will be redirected to a file. I<$mode_path> is simply given to an open 
call, so you might use this like: 

 $S -> catch_output(">>my_stdout_stderr.txt");

=item catch_output Pipe mode

If parameter I<$mode_path> is omitted, STDOUT+STDERR / STDOUT / STDERR 
will be sent to the input of a child process. This will check it's input
if it is according to C<catch_output_pattern>. If so, it will send STDOUT
messages to $S->msg and STDERR messages to $S->msg_error.

Note, that $S->msg and $S->msg_error are sending their output
to your STDOUT.

If you like to get the output passed catch_output_pattern yourself rather than
printing it via msg or msg_error, you can pass a code reference 
to catch_output_sub. This function will then be called with matched 
output as parameter.

=back

=item catch_output_sub

I<\&sub> = I<$S> -> catch_output_sub([I<\&sub>])

I<\&sub> = I<$S> -> catch_stdout_sub([I<\&sub>])

I<\&sub> = I<$S> -> catch_stderr_sub([I<\&sub>])

Returns (optionally sets) the code reference, that will be called when
some output passed catch_output_pattern in Pipe mode.

=item restore_output

C<1>||C<0> = I<$S> -> restore_output()

C<1>||C<0> = I<$S> -> restore_stdout()

C<1>||C<0> = I<$S> -> restore_stderr()

Restores the output that has been redirected via catch_output.

=item catch_output_pattern

I<$pattern> = I<$S> -> catch_output_pattern([I<$pattern>])

I<$pattern> = I<$S> -> catch_stdout_pattern([I<$pattern>])

I<$pattern> = I<$S> -> catch_stderr_pattern([I<$pattern>])

When output is redirected, only those output lines will be regarded, that
match $1 of this pattern. Default is: C<'^(.*)$'>.

=back

=head1 MISCELLANEOUS METHODS

=over 4

=item gimmick

I<$gimicked_string> = I<$Startup> -> gimmick (I<$control_string>)

Replaces certain strings in a control string. You can use:

   $S             Seconds
   $M             Minutes
   $H             Hour
   $d             day
   $m             month
   $y             year
   $date          '$d.$m.$y'
   $time          '$H:$M:$S'

   $err_str       current error string
   $err_num       current error number
   $err_info      current error info (longer text)
   $err_package   package calling error method
   $err_filename  filename of package
   $err_line      line in package calling error method

   $prog_name     program name (if set by application)
   $prog_date     program date (if set by application)
   $prog_ver      program version (if set by application)

=back

=head1 TO DO

Lots. 

=head1 SEE ALSO

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>

=cut

