# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and
# related or neighboring rights to the content of this file.
# Attribution is requested but is not required.

# t_TestCommon -- setup and tools specifically for tests. 
#
#   Everything not specifically test-related is in the separate
#   module t_Common (which is not necessairly just for tests).
#
#   Sets default encode/decode to UTF-8 for all file handles.
#   (this must be done before Test::More is loaded to avoid problems).
#   Then loads Test::More into your module.
#
#   If @ARGV contains -d etc. those options are removed from @ARGV
#   and the corresponding globals are set: $debug, $verbose, $silent
#   (the globals are not exported by default).
#
#   ':silent' captures stdout & stderr and dies at exit if anything was
#      written (Test::More output and output via 'note'/'diag' excepted).
#      Note: Currently incompatible with Capture::Tiny !
#
#   Exports various utilites & wrappers for ok() and like()

# This file is intended to be identical in all my module distributions.

package t_TestCommon;

# NO use strict/warnings here to avoid conflict with t_Common which sets them
use t_Common qw/oops mytempfile mytempdir/;

use v5.16; # must have PerlIO for in-memory files for ':silent';

use Carp;
BEGIN{
  # Unicode support
  # This must be done before loading Test::More to be effective
  confess "Test::More already loaded!" if defined( &Test::More::ok );

  # Maybe we should just call binmode(encoding...) on STDOUT & STDERR?
  use open IO => ':encoding(UTF-8)', ':std';

  # Disable buffering
  STDERR->autoflush(1);
  STDOUT->autoflush(1);
}
use Test::More 0.98; # see UNIVERSAL

require Exporter;
use parent 'Exporter';
our @EXPORT = qw/silent
                 bug ok_with_lineno like_with_lineno
                 rawstr showstr showcontrols displaystr 
                 show_white show_empty_string
                 fmt_codestring 
                 verif_no_internals_mentioned 
                 insert_loc_in_evalstr verif_eval_err 
                 timed_run
                 checkeq_literal expect1 check _check_end
                 arrays_eq hash_subset
                 run_perlscript
                 @quotes
                 string_to_tempfile
                /;
our @EXPORT_OK = qw/$debug $silent $verbose dprint dprintf/;

use Import::Into;
use Data::Dumper;
use Cwd qw/getcwd abs_path/;
use File::Basename qw/dirname/;

sub bug(@) { @_=("BUG FOUND:",@_); goto &Carp::confess }

# Parse manual-testing args from @ARGV 
our ($debug, $verbose, $silent);
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure("pass_through");
GetOptions(
  "d|debug"           => sub{ $debug=$verbose=1; $silent=0 },
  "s|silent"          => \$silent,
  "v|verbose"         => \$verbose,
) or die "bad args";
Getopt::Long::Configure("default");

sub import {
  my $target = caller;

  # Do an initial read of $[ so arybase will be autoloaded
  # (prevents corrupting $!/ERRNO in subsequent tests)
  eval '$[' // die;

  Test::More->import::into($target);

  if (grep{ $_ eq ':silent' } @_) {
    @_ = grep{ $_ ne ':silent' } @_;
    _start_silent();
  }

  # chain to Exporter to export any other importable items
  goto &Exporter::import
}

sub dprint(@)   { Test::More::note(@_)               if $debug };
sub dprintf($@) { Test::More::note($_[0],@_[1..$#_]) if $debug };

sub arrays_eq($$) {
  my ($a,$b) = @_;
  return 0 unless @$a == @$b;
  for(my $i=0; $i <= $#$a; $i++) {
    return 0 unless $a->[$i] eq $b->[$i];
  }
  return 1;
}

sub hash_subset($@) {
  my ($hash, @keys) = @_;
  return undef if ! defined $hash;
  return { map { exists($hash->{$_}) ? ($_ => $hash->{$_}) : () } @keys }
}

# string_to_tempfile($string, args => for-mytempfile) 
# string_to_tempfile($string, pseudo_template) # see mytempfile
#
sub string_to_tempfile($@) {
  my ($string, @tfargs) = @_;
  my ($fh, $path) = mytempfile(@tfargs);
  dprint "> Creating $path\n";
  print $fh $string; 
  $fh->flush;
  seek($fh,0,0) or die "seek $path : $!";
  wantarray ? ($path,$fh) : $path
}

# Run a Perl script in a sub-process.
# Plain 'system  path/to/script.pl' does not work in a test environment
# where the correct Perl executable is not at the front of PATH,
# and also where -I options might supply library paths.
# This is usually enclosed in Capture { ... }
sub run_perlscript(@) {
  my @cmd = @_;
  oops unless defined($cmd[0]);
  VERIF:
  { open my $fh, "<", $cmd[0] or die "$cmd[0] : $!";
    while (<$fh>) { last VERIF if /^#!.*perl|^\s*use\s+(?:warnings|\w+::)/; }
    confess "$cmd[0] does not appear to be a Perl script";
  }
  local $ENV{PERL5LIB} = join(":", @INC);
  system $^X, @cmd;
}

#--------------- :silent support ---------------------------
# N.B. It appears, experimentally, that output from ok(), like() and friends
# is not written to the test process's STDOUT or STDERR, so we do not need
# to worry about ignoring those normal outputs (somehow everything is
# merged at the right spots, presumably by a supervisory process).
#
# Therefore tests can be simply wrapped in silent{...} or the entire
# program via the ':silent' tag; however any "Silence expected..." diagnostics
# will appear at the end, perhaps long after the specific test case which
# emitted the undesired output.
my ($orig_stdOUT, $orig_stdERR, $orig_DIE_trap);
my ($inmem_stdOUT, $inmem_stdERR) = ("", "");
my $silent_mode;
use Encode qw/decode FB_WARN FB_PERLQQ FB_CROAK LEAVE_SRC/;
sub _finish_silent() {
  confess "not in silent mode" unless $silent_mode;
  close STDERR;
  open(STDERR, ">>&", $orig_stdERR) or exit(198);
  close STDOUT;
  open(STDOUT, ">>&", $orig_stdOUT) or die "orig_stdOUT: $!";
  $SIG{__DIE__} = $orig_DIE_trap;
  $silent_mode = 0;
  # The in-memory files hold octets; decode them before printing
  # them out (when they will be re-encoded for the user's terminal).
  my $errmsg;
  if ($inmem_stdOUT ne "") {
    print STDOUT "--- saved STDOUT ---\n";
    print STDOUT decode("utf8", $inmem_stdOUT, FB_PERLQQ|LEAVE_SRC);
    $errmsg //= "Silence expected on STDOUT";
  }
  if ($inmem_stdERR ne "") {
    print STDERR "--- saved STDERR ---\n";
    print STDERR decode("utf8", $inmem_stdERR, FB_PERLQQ|LEAVE_SRC);
    $errmsg = $errmsg ? "$errmsg and STDERR" : "Silence expected on STDERR";
  }
  $errmsg
}
sub _start_silent() {
  confess "nested silent treatments not supported" if $silent_mode;
  $silent_mode = 1;

  $orig_DIE_trap = $SIG{__DIE__};
  $SIG{__DIE__} = sub{ 
    my @diemsg = @_; 
    my $err=_finish_silent(); warn $err if $err;
    die @diemsg;
  }; 

  my @OUT_layers = grep{ $_ ne "unix" } PerlIO::get_layers(*STDOUT, output=>1);
  open($orig_stdOUT, ">&", \*STDOUT) or die "dup STDOUT: $!";
  close STDOUT;
  open(STDOUT, ">", \$inmem_stdOUT) or die "redir STDOUT: $!";
  binmode(STDOUT); binmode(STDOUT, ":utf8");

  my @ERR_layers = grep{ $_ ne "unix" } PerlIO::get_layers(*STDERR, output=>1);
  open($orig_stdERR, ">&", \*STDERR) or die "dup STDERR: $!";
  close STDERR;
  open(STDERR, ">", \$inmem_stdERR) or die "redir STDERR: $!";
  binmode(STDERR); binmode(STDERR, ":utf8");
}
sub silent(&) {
  my $wantarray = wantarray;
  my $code = shift;
  _start_silent();
  my @result = do{
    if (defined $wantarray) {
      return( $wantarray ? $code->() : scalar($code->()) );
    }
    $code->();
    my $dummy_result; # so previous call has null context
  };
  my $errmsg = _finish_silent();
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::More::ok(! defined($errmsg), $errmsg);
  wantarray ? @result : $result[0]
}
END{
  if ($silent_mode) {
    my $errmsg = _finish_silent();
    if ($errmsg) {
      #die $errmsg;  # it's too late to call ok(false)
      warn $errmsg;
      exit 199; # recognizable exit code in case message is lost
    }
  }
}
#--------------- (end of :silent stuff) ---------------------------

# N.B. package dir might have version like ".../ODF-lpOD_Helper-3.008/..."
dirname(abs_path(__FILE__)) =~ m#.*/(\w+)-\w[-\w\.]*/# or die "Cant intuit testee module name";
(my $testee_top_module = $1) =~ s/-/::/g;
oops unless $testee_top_module;

sub verif_no_internals_mentioned($) { # croaks if references found
  my $original = shift;
  return if $Carp::Verbose; 

  local $_ = $original;

  # Ignore glob refs like \*{"..."}
  s/(?<!\\)\\\*\{"[^"]*"\}//g;
  
  # Ignore globs like *main::STDOUT or *main::$f
  s/(?<!\\)\*\w[\w:\$]*\b//g;
  
  # Ignore object refs like Some::Package=THING(hexaddr)
  s/(?<!\w)\w[\w:\$]*=(?:REF|ARRAY|HASH|SCALAR|CODE|GLOB)\(0x[0-9a-f]+\)//g;
  
  # Mask references to our test library files named t_something.pm
  s#\b(\bt_\w+).pm(\W|$)#<$1 .pm>$2#gs;
  
  my $msg;
  if (/\b(?<hit>${testee_top_module}::[\w:]*)/) {
    $msg = "ERROR: Log msg or traceback mentions internal package '$+{hit}'"
  }
  elsif (/(?<hit>[-.\w\/]+\.pm\b)/s) {
    $msg = "ERROR: Log msg or traceback mentions non-test .pm file '$+{hit}'"
  }
  if ($msg) {
    my $start = $-[1]; # offset of start of item
    my $end   = $+[1]; # offset of end+1
    substr($_,$start,0) = "HERE>>>";
    substr($_,$end+7,0) = "<<<THERE";
    local $Carp::Verbose = 0;  # no full traceback 
    $Carp::CarpLevel++;
    croak $msg, ":\n«$_»\n";
  }
  1 # return true result if we don't croak
}
sub show_empty_string(_) {
  $_[0] eq "" ? "<empty string>" : $_[0]
}

sub show_white(_) { # show whitespace which might not be noticed
  local $_ = shift;
  return "(Is undef)" unless defined;
  s/\t/<tab>/sg;
  s/( +)$/"<space>" x length($1)/seg; # only trailing spaces
  s/\n/<newline>\n/sg;
  show_empty_string $_
}

our $showstr_maxlen = 300;
our @quotes = ("«", "»");
#our @quotes = ("<<", ">>");
sub rawstr(_) { # just the characters in French Quotes (truncated)
  $quotes[0].(length($_[0])>$showstr_maxlen ? substr($_[0],0,$showstr_maxlen-3)."..." : $_[0]).$quotes[1]
}

# Show controls as single-charcter indicators like DDI's "controlpics",
# with the whole thing in French Quotes.  Truncate if huge.
sub showcontrols(_) {
  local $_ = shift;
  s/\n/\N{U+2424}/sg; # a special NL glyph
  s/[\x{00}-\x{1F}]/ chr( ord($&)+0x2400 ) /aseg;
  rawstr
}

# Show controls as traditional \t \n etc. if possible
sub showstr(_) {
  if (defined &Data::Dumper::Interp::visnew) {
    return visnew->Useqq("unicode")->vis(shift);
  } else {
    # I don't want to require Data::Dumper::Interp to be 
    # loaded although it will be if t_Common.pm was used also.
    return showcontrols(shift);
  }
}

# Show both the raw string in French Quotes, and with hex escapes
# so we can still see something useful in output from non-Unicode platforms.
sub displaystr($) {
  my ($input) = @_;
  return "undef" if ! defined($input);
  # Data::Dumper will show 'wide' characters as hex escapes
  my $dd = Data::Dumper->new([$input])->Useqq(1)->Terse(1)->Indent(0)->Dump;
  chomp $dd;
  if ($dd eq $input || $dd eq "\"$input\"") {
    # No special characters, so omit the hex-escaped form
    return rawstr($input)
  } else {
    return rawstr($input)."($dd)"
  }
}

sub fmt_codestring($;$) { # returns list of lines
  my ($str, $prefix) = @_;
  $prefix //= "line ";
  my $i; map{ sprintf "%s%2d: %s\n", $prefix,++$i,$_ } (split /\n/,$_[0]);
}

sub ok_with_lineno($;$) {
  my ($isok, $test_label) = @_;
  my $lno = (caller)[2];
  $test_label = ($test_label//"") . " (line $lno)";
  @_ = ( $isok, $test_label );
  goto &Test::More::ok;  # show caller's line number
}
sub like_with_lineno($$;$) {
  my ($got, $exp, $test_label) = @_;
  my $lno = (caller)[2];
  $test_label = ($test_label//"") . " (line $lno)";
  @_ = ( $got, $exp, $test_label );
  goto &Test::More::like;  # show caller's line number
}

sub _check_end($$$) {
  my ($errmsg, $test_label, $ok_only_if_failed) = @_;
  return
    if $ok_only_if_failed && !$errmsg;
  my $lno = (caller)[2];
  &Test::More::diag("**********\n${errmsg}***********\n") if $errmsg;
  @_ = ( !$errmsg, $test_label );
  goto &ok_with_lineno;
}

# Nicer alternative to check() when 'expected' is a literal string, not regex
sub checkeq_literal($$$) {
  my ($desc, $exp, $act) = @_;
  #confess "'exp' is not plain string in checkeq_literal" if ref($exp); #not re!
  $exp = show_white($exp); # stringifies undef
  $act = show_white($act);
  return unless $exp ne $act;
  my $hposn = 0;
  my $vposn = 0;
  for (0..length($exp)) {
    my $c = substr($exp,$_,1);
    last if $c ne substr($act,$_,1);
    ++$hposn;
    if ($c eq "\n") {
      $hposn = 0;
      ++$vposn;
    }
  }
  @_ = ( "\n**************************************\n"
        .($desc ? "${desc}\n" : "")
        ."Expected:\n".displaystr($exp)."\n"
        ."Actual:\n".displaystr($act)."\n"
        # + for opening « or << in the displayed str
        .(" " x ($hposn+length($quotes[0])))."^"
                          .($vposn > 0 ? "(line ".($vposn+1).")\n" : "\n")
        ." at line ", (caller(0))[2]."\n"
        .visFoldwidth()."\n" 
       ) ;
  #goto &Carp::confess;
  Carp::confess(@_);
}
sub expect1($$) {
  @_ = ("", @_);
  goto &checkeq_literal;
}

# Convert a literal "expected" string which contains things which are
# represented differently among versions of Perl and/or Data::Dumper
# into a regex which works with all versions.
# As of 1/1/23 the input string is expected to be what Perl v5.34 produces.
our $bs = '\\';  # a single backslash
sub expstr2re($) {
  local $_ = shift;
  confess "bug" if ref($_);
  unless (m#qr/|"::#) {
    return $_; # doesn't contain variable-representation items
  }
  # In \Q *string* \E the *string* may not end in a backslash because
  # it would be parsed as (\\)(E) instead of (\)(\E).
  # So change them to a unique token and later replace problematic
  # instances with ${bs} variable references.
  s/\\/<BS>/g;
  $_ = '\Q' . $_ . '\E';
  s#([\$\@\%])#\\E\\$1\\Q#g;

  if (m#qr/#) {
    # Canonical: qr/STUFF/MODIFIERS
    # Alternate: qr/STUFF/uMODIFIERS
    # Alternate: qr/(?^MODIFIERS:STUFF)/
    # Alternate: qr/(?^uMODIFIERS:STUFF)/
#say "#XX qr BEFORE: $_";
    s#qr/([^\/]+)/([msixpodualngcer]*)
     #\\E\(\\Qqr/$1/\\Eu?\\Q$2\\E|\\Qqr/(?^\\Eu?\\Q$2:$1)/\\E\)\\Q#xg
      or confess "Problem with qr/.../ in input string: $_";
#say "#XX qr AFTER : $_";
  }
  if (m#\{"([\w:]+).*"\}#) {
    # Canonical: fh=\*{"::\$fh"}  or  fh=\*{"Some::Pkg::\$fh"}
    #   which will be encoded above like ...\Qfh=<BS>*{"::<BS>\E\$\Qfh"}
    # Alt1     : fh=\*{"main::\$fh"}
    # Alt2     : fh=\*{'main::$fh'}  or  fh=\*{'main::$fh'} etc.
#say "#XX fh BEFORE: $_";
    s{(\w+)=<BS>\*\{"(::)<BS>([^"]+)"\}}
     {$1=<BS>*{\\E(?x: "(?:main::|::) \\Q<BS>$3"\\E | '(?:main::|::) \\Q$3'\\E )\\Q}}xg
    |
    s{(\w+)=<BS>\*\{"(\w[\w:]*::)<BS>([^"]+)"\}}
     {$1=<BS>*{\\E(?x: "\\Q$2<BS>$3"\\E | '\\Q$2$3'\\E )\\Q}}xg
    or
      confess "Problem with filehandle in input string <<$_>>";
#say "#XX fh AFTER : $_";
  }
  s/<BS>\\/\${bs}\\/g;
  s/<BS>/\\/g;
#say "#XX    FINAL : $_";

  my $saved_dollarat = $@;
  my $re = eval "qr{${_}}"; die "$@ " if $@;
  $@ = $saved_dollarat;
  $re
}

# check $test_desc, string_or_regex, result
sub check($$@) {
  my ($desc, $expected_arg, @actual) = @_;
  local $_;  # preserve $1 etc. for caller
  my @expected = ref($expected_arg) eq "ARRAY" ? @$expected_arg : ($expected_arg);
  confess "zero 'actual' results" if @actual==0;
  confess "ARE WE USING THIS FEATURE? (@actual)" if @actual != 1;
  confess "ARE WE USING THIS FEATURE? (@expected)" if @expected != 1;
  confess "\nTESTa FAILED: $desc\n"
         ."Expected ".scalar(@expected)." results, but got ".scalar(@actual).":\n"
         ."expected=(@expected)\n"
         ."actual=(@actual)\n"
         ."\$@=$@\n"
    if @expected != @actual;
  foreach my $i (0..$#actual) {
    my $actual = $actual[$i];
    my $expected = $expected[$i];
    if (!ref($expected)) {
      # Work around different Perl versions stringifying regexes differently
      $expected = expstr2re($expected);
    }
    if (ref($expected) eq "Regexp") {
      unless ($actual =~ $expected) {
        @_ = ( "\n**************************************\n"
              ."TESTb FAILED: ".$desc."\n"
              ."Expected (Regexp):\n".${expected}."<<end>>\n"
              ."Got:\n".displaystr($actual)."<<end>>\n"
              .visFoldwidth()."\n" ) ;
        Carp::confess(@_); #goto &Carp::confess;
      }
#say "###ACT $actual";
#say "###EXP $expected";
    } else {
      unless ($expected eq $actual) {
        @_ = ("TESTc FAILED: $desc", $expected, $actual);
        goto &checkeq_literal
      }
    }
  }
}

sub verif_eval_err(;$) {  # MUST be called on same line as the 'eval'
  my ($msg_regex) = @_;
  my @caller = caller(0);
  my $ln = $caller[2];
  my $fn = $caller[1];
  my $ex = $@;
  confess "expected error did not occur at $fn line $ln\n",
          fmtsheet(sheet({package => $caller[0]}))
    unless $ex;

  if ($ex !~ / at $fn line $ln\.?(?:$|\n)/s) {
    die "tex";
    confess "Got UN-expected err (not ' at $fn line $ln'):\n«$ex»\n",
            fmtsheet(sheet({package => $caller[0]})),
            "\n";
  }
  if ($msg_regex && $ex !~ qr/$msg_regex/) {
    confess "Got UN-expected err (not matching $msg_regex) at $fn line $ln'):\n«$ex»\n",
            fmtsheet(sheet({package => $caller[0]})),
            "\n";
  }
  verif_no_internals_mentioned($ex);
  dprint "Got expected err: $ex\n";
}

sub insert_loc_in_evalstr($) {
  my $orig = shift;
  my ($fn, $lno) = (caller(0))[1,2];
#use Data::Dumper::Interp; say dvis '###insert_loc_in_evalstr $fn $lno';
  "# line $lno \"$fn\"\n".$orig
}

sub timed_run(&$@) {
  my ($code, $maxcpusecs, @codeargs) = @_;

  eval { require Time::HiRes };
  my $getcpu = defined(eval{ &Time::HiRes::clock() })
    ? \&Time::HiRes::clock : sub{ my @t = times; $t[0]+$t[1] };

  my $startclock = &$getcpu();
  my (@result, $result);
  if (wantarray) {@result = &$code(@codeargs)} else {$result = &$code(@codeargs)};
  my $cpusecs = &$getcpu() - $startclock;
  confess "TOOK TOO LONG ($cpusecs CPU seconds vs. limit of $maxcpusecs)\n"
    if $cpusecs > $maxcpusecs;
  if (wantarray) {return @result} else {return $result};
}

1;
