# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and
# related or neighboring rights to the content of this file.
# Attribution is requested but is not required.

# NO use strict; use warnings here to avoid conflict with t_Common which sets them

# t_TestCommon -- setup and tools specifically for tests.
#
#   This file is intended to be identical in all my module distributions.
#
#   Loads Test2::V0 (except with ":no-Test2"), which sets UTF-8 enc/dec
#   for test-harness streams (but *not* STD* or new filehandles).
#
#   Makes STDIN, STDOUT & STDERR UTF-8 auto de/encode
#
#   Imports 'utf8' so scripts can be written in UTF-8 encoding
#
#   warnings are *not* imported, to avoid clobbering 'no warnings ...'
#   settings done beforehand (e.g. via t_Common).
#
#   If @ARGV contains -d etc. those options are removed from @ARGV
#   and the corresponding globals are set: $debug, $verbose, $silent
#   (the globals are not exported by default).  In addition, the
#   hash %dvs is initialized with those values.
#
#   ':silent' captures stdout & stderr and dies at exit if anything was
#      written (Test::More output and output via 'note'/'diag' excepted).
#      Note: Currently incompatible with Capture::Tiny !
#
#   Exports various utilites & wrappers for ok() and like()
#
#   Everything not specifically test-related is in the separate
#   module t_Common (which is not necessairly just for tests).

package t_TestCommon;

use t_Common qw/oops mytempfile mytempdir/;

use v5.16; # must have PerlIO for in-memory files for ':silent';

use Carp;
BEGIN{
  confess "Test::More already loaded!" if defined( &Test::More::ok );
  confess "Test2::V0 already loaded!" if defined( &Test2::V0::import );

  # Force UTF-8 (and remove any other encoder) regardless of the
  # environment/terminal.  This allows tests to use capture {...} and check
  # the results independent of the environment, even though printed results
  # may be garbled.
  binmode(STDIN, ":raw:encoding(UTF-8):crlf");
  if ($^O eq "MSWin32") {
    binmode(STDOUT, ":raw:encoding(UTF-8)");
    binmode(STDERR, ":raw:encoding(UTF-8)");
  } else {
    binmode(STDOUT, ":raw:crlf:encoding(UTF-8)");
    binmode(STDERR, ":raw:crlf:encoding(UTF-8)");
  }

  # Disable buffering
  STDERR->autoflush(1);
  STDOUT->autoflush(1);
}
use POSIX ();
use utf8;
use JSON ();

require Exporter;
use parent 'Exporter';
our @EXPORT = qw/silent
                 bug
                 t_ok t_is t_like
                 ok_with_lineno is_with_lineno like_with_lineno
                 rawstr showstr showcontrols displaystr
                 show_white show_empty_string
                 fmt_codestring
                 verif_no_internals_mentioned
                 insert_loc_in_evalstr verif_eval_err
                 timed_run
                 mycheckeq_literal expect1 mycheck _mycheck_end
                 arrays_eq hash_subset
                 run_perlscript
                 @quotes
                 string_to_tempfile
                 tmpcopy_if_writeable
                /;
our @EXPORT_OK = qw/$savepath $debug $silent $verbose %dvs dprint dprintf/;

use Import::Into;
use Data::Dumper;

unless (Cwd::abs_path(__FILE__) =~ /Data-Dumper-Interp/) {
  # unless we are testing DDI
  #$Data::Dumper::Interp::Foldwidth = undef; # use terminal width
  $Data::Dumper::Interp::Useqq = "controlpics:unicode";
}

use Cwd qw/getcwd abs_path/;
use POSIX qw/INT_MAX/;
use File::Basename qw/dirname/;
use Env qw/@PATH @PERL5LIB/;  # ties @PATH, @PERL5LIB
use Config;

sub bug(@) { @_=("BUG FOUND:",@_); goto &Carp::confess }

# Parse manual-testing args from @ARGV
my @orig_ARGV = @ARGV;
our ($debug, $verbose, $silent, $savepath, $nobail, $nonrandom, %dvs);
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure("pass_through");
GetOptions(
  "d|debug"           => sub{ $debug=$verbose=1; $silent=0 },
  "s|silent"          => \$silent,
  "savepath=s"        => \$savepath,
  "nobail"            => \$nobail,
  "n|nonrandom"       => \$nonrandom,
  "v|verbose"         => \$verbose,
) or die "bad args";
Getopt::Long::Configure("default");
say "> ARGV PASSED THROUGH: ",join(",",map{ "'${_}'" } @ARGV) if $debug;

$dvs{debug}   = $debug   if defined($debug);
$dvs{verbose} = $verbose if defined($verbose);
$dvs{silent}  = $silent  if defined($silent);

if ($nonrandom) {
  # This must run before Test::More or Test2::V0 is loaded!!
  # Normally this is the case because our package body is executed before
  # import() is called.
  if (open my $fh, "<", "/proc/sys/kernel/randomize_va_space") {
    chomp(my $setting = <$fh>);
    unless($setting eq "0") {
      warn "WARNING: Kernel address space randomization is in effect.\n";
      warn "To disable:  echo 0 | sudo tee /proc/sys/kernel/randomize_va_space\n";
      warn "To re-enable echo 2 | sudo tee /proc/sys/kernel/randomize_va_space\n";
    }
  }
  unless (($ENV{PERL_PERTURB_KEYS}//"") eq "2") {
    $ENV{PERL_PERTURB_KEYS} = "2"; # deterministic
    $ENV{PERL_HASH_SEED} = "0xDEADBEEF";
    #$ENV{PERL_HASH_SEED_DEBUG} = "1";
    @PERL5LIB = @INC; # cf 'use Env' above
    # https://web.archive.org/web/20160308025634/http://wiki.cpantesters.org/wiki/cpanauthornotes
    exec $Config{perlpath}, $0, @orig_ARGV; # for reproducible results
  }
}

sub import {
  my $target = caller;

  my %tags;
  for (my $ix=0; $ix <= $#_; $ix++) {
    if ($_[$ix] =~ /^(:.*)$/) {
      next if $_[$ix] eq ":DEFAULT"; # ok, pass thru to Exporter
      $tags{$1} = 1;
      splice @_, $ix, 1, ();
      redo unless $ix > $#_;
    }
  }

  # Do an initial read of $[ so arybase will be autoloaded
  # (prevents corrupting $!/ERRNO in subsequent tests)
  eval '$[' // die;

  # Test2::V0
  #  Do not import warnings, to avoid un-doing prior settings.
  #  Do not inport 1- and 2- or 3- character upper-case names, which are
  #  likely to clash with user variables and/or spreadsheet column letters
  #  (when using Spreadsheet::Edit).
  unless (delete $tags{":no-Test2"}) {
    require Test2::V0; # a huge collection of tools
    Test2::V0->import::into($target,
      -no_warnings => 1,
      (map{ "!$_" } "A".."AAZ")
    );
    if ($nobail) {
      say "> NOT requiring BailOnFail"
    } else {
      require Test2::Plugin::BailOnFail;
      # Stop on the first error
      Test2::Plugin::BailOnFail->import::into($target);
    }
  }
  utf8->import::into($target);

  if (delete $tags{":silent"}) {
    _start_silent() unless $debug;
  }

  die "Unhandled tag ",keys(%tags) if keys(%tags);

  # chain to Exporter to export any other importable items
  goto &Exporter::import
}

# Avoid turning on Test2 if not otherwise used...
sub dprint(@)   { print(@_)                if $debug };
sub dprintf($@) { printf($_[0],@_[1..$#_]) if $debug };

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
#
# Provides -I options to mimic @INC (PERL5LIB is often not set)
#
# -CIOE is passed to make stdio UTF-8 regardless of the actual test
# environment, but if the script does e.g. "use open ':locale'" it will
# override that.   I'm forcing LC_ALL=C so things like date and number
# formats will be predictable for testing.
#
# This is usually enclosed in Tiny::Capture::capture { ... }
#
#    ==> IMPORTANT: Be sure STDOUT/ERR has :encoding(...) set beforehand
#        because Tiny::Capture will decode captured output the same way.
#        Otherwise wide chars will be corrupted
#
#
sub run_perlscript(@) {
  my $tf; # keep in scope until no longer needed
  my @perlargs = ("-CIOE", @_);
  @perlargs = ((map{ "-I$_" } @INC), @perlargs);
  unshift @perlargs, "-MCarp=verbose" if $Carp::Verbose;
  unshift @perlargs, "-MCarp::Always=verbose" if $Carp::Always::Verbose;
  if ($^O eq "MSWin32") {
    for (my $ix=0; $ix <= $#perlargs; $ix++) {
      if ($perlargs[$ix] =~ /^-w?[Ee]$/) {
        # Passing perl code in an argument is impractical in DOS/Windows
        $tf = Path::Tiny->tempfile("perlcode_XXXXX");
        $tf->spew_utf8($perlargs[$ix+1]);
        splice(@perlargs, $ix, 2, $tf->stringify);
      }
      for ($perlargs[$ix]) {
        if (/^-\*[Ee]/) { oops "unhandled perl arg" }
        s/"/\\"/g;
        if (/[\s\/"']/) {
          $_ = '"' . $_ . '"';
        }
      }
    }
  }

  local $ENV{LC_ALL} = "C";

  if ($debug) {
    my $msg = "%%% run_perlscript >";
    for my $k (sort keys %ENV) {
      next unless $k =~ /^(LC|LANG)/;
      $msg .= " $k='$ENV{$k}'"
    }
    $msg .= " $^X";
    $msg .= " '${_}'" foreach (@perlargs);
    print STDERR "$msg\n";
  }
  my $wstat = system $^X, @perlargs;
  print STDERR "%%%(returned from 'system', wstat=",sprintf("0x%04X",$wstat),")%%%\n" if $debug;
  $wstat
}

#--------------- :silent support ---------------------------
# N.B. It appears, experimentally, that output from ok(), like() and friends
# is not written to the test process's STDOUT or STDERR, so we do not need
# to worry about ignoring those normal outputs (somehow everything is
# merged at the right spots, presumably by a supervisory process).
# [Note May23: This was with Test::More may *NOT* be true with Test2::V0 !!]
#
# Therefore tests can be simply wrapped in silent{...} or the entire
# program via the ':silent' tag; however any "Silence expected..." diagnostics
# will appear at the end, perhaps long after the specific test case which
# emitted the undesired output.
my ($orig_stdOUT, $orig_stdERR, $orig_DIE_trap);
my ($inmem_stdOUT, $inmem_stdERR) = ("", "");
my $silent_mode;
use Encode qw/decode FB_WARN FB_PERLQQ FB_CROAK LEAVE_SRC/;
my $start_silent_loc = "";
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
  defined($errmsg) ? $errmsg." at $start_silent_loc\n" : undef;
}
sub _start_silent() {
  confess "nested silent treatments not supported" if $silent_mode;
  $silent_mode = 1;

  for (my $N=0; ;++$N) {
    my ($pkg, $file, $line) = caller($N);
    $start_silent_loc = "$file line $line", last if $pkg ne __PACKAGE__;
  }

  $orig_DIE_trap = $SIG{__DIE__};
  $SIG{__DIE__} = sub{
    return if $^S or !defined($^S);  # executing an eval, or Perl compiler
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
  Test2::V0::ok(! defined($errmsg), $errmsg);
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

# Find the ancestor build or checkout directory (it contains a "lib" subdir)
# and derive the package name from e.g. "My-Pack" or "My-Pack-1.234"
my $testee_top_module;
for (my $path=path(__FILE__);
             $path ne Path::Tiny->rootdir; $path=$path->parent) {
  if (-e (my $p = $path->child("dist.ini"))) {
    $p->slurp() =~ /^ *name *= *(\S+)/i or oops;
    ($testee_top_module = $1) =~ s/-/::/g;
    last
  }
  if (-e (my $p = $path->child("MYMETA.json"))) {
    $testee_top_module = JSON->new->decode($p->slurp())->{name};
    $testee_top_module =~ s/-/::/g;
    last;
  }
}
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

  # Ignore Data::Dumper::Interp::addrvis output like Some::Package<dec:hex>
  s/(?<!\w)\w[\w:\$]*<\d+:[\da-f]+>//g;

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
  s/\R/<newline>\n/sg;
  show_empty_string $_
}

#our $showstr_maxlen = 300;
our $showstr_maxlen = INT_MAX;
our @quotes = ("«", "»");
#our @quotes = ("<<", ">>");
sub rawstr(_) { # just the characters in French Quotes (truncated)
  # Show spaces visibly
  my $text = $_[0];
  ##$text =~ s/ /\N{MIDDLE DOT}/gs;
  $quotes[0].(length($text)>$showstr_maxlen ? substr($text,0,$showstr_maxlen-3)."..." : $text).$quotes[1]
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

# Show the raw string in French Quotes.
# If STDOUT is not UTF-8 encoded, also show D::D hex escapes
# so we can still see something useful in output from non-Unicode platforms.
sub displaystr($) {
  my ($input) = @_;
  return "undef" if ! defined($input);
  local $_;
  state $utf8_output = grep /utf.?8/i, PerlIO::get_layers(*STDOUT, output=>1);
  my $r = rawstr($input);
  if (! $utf8_output && $input =~ /[^[:print:]]/a) {
    # Data::Dumper will show 'wide' characters as hex escapes
    my $dd = Data::Dumper->new([$input])->Useqq(1)->Terse(1)->Indent(0)->Dump;
    if ($dd ne $input && $dd ne "\"$input\"") {
      $r .= "\nD::D->$dd";
    }
  }
  $r
}

sub fmt_codestring($;$) { # returns list of lines
  my ($str, $prefix) = @_;
  $prefix //= "line ";
  my $i; map{ sprintf "%s%2d: %s\n", $prefix,++$i,$_ } (split /\n/,$_[0]);
}

# These wrappers add the caller's line number to the test description
# so they show when successful tests log their name.
# This is only visible with using "perl -Ilib t/xxx.t"
# not with 'prove -l' and so mostly pointless!

sub t_ok($;$) {
  my ($isok, $test_label) = @_;
  my $lno = (caller)[2];
  $test_label = ($test_label//"") . " (line $lno)";
  @_ = ( $isok, $test_label );
  goto &Test2::V0::ok;  # show caller's line number
}
sub ok_with_lineno($;$) { goto &t_ok };

sub t_is($$;$) {
  my ($got, $exp, $test_label) = @_;
  my $lno = (caller)[2];
  $test_label = ($test_label//$exp//"undef") . " (line $lno)";
  @_ = ( $got, $exp, $test_label );
  goto &Test2::V0::is;  # show caller's line number
}
sub is_with_lineno($$;$) { goto &t_is }

sub t_like($$;$) {
  my ($got, $exp, $test_label) = @_;
  my $lno = (caller)[2];
  $test_label = ($test_label//$exp) . " (line $lno)";
  @_ = ( $got, $exp, $test_label );
  goto &Test2::V0::like;  # show caller's line number
}
sub like_with_lineno($$;$) { goto &t_like }

sub _mycheck_end($$$) {
  my ($errmsg, $test_label, $ok_only_if_failed) = @_;
  return
    if $ok_only_if_failed && !$errmsg;
  my $lno = (caller)[2];
  &Test2::V0::diag("**********\n${errmsg}***********\n") if $errmsg;
  @_ = ( !$errmsg, $test_label );
  goto &ok_with_lineno;
}

# Nicer alternative to mycheck() when 'expected' is a literal string, not regex
sub mycheckeq_literal($$$) {
  my ($desc, $exp, $act) = @_;
  #confess "'exp' is not plain string in mycheckeq_literal" if ref($exp); #not re!
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
       ) ;
  #goto &Carp::confess;
  Carp::confess(@_);
}
sub expect1($$) {
  @_ = ("", @_);
  goto &mycheckeq_literal;
}

# Convert a literal "expected" string which contains things which are
# represented differently among versions of Perl and/or Data::Dumper
# into a regex which works with all versions.
# As of 1/1/23 the input string is expected to be what Perl v5.34 produces.
our $bs = '\\';  # a single backslash
sub _expstr2restr($) {
  local $_ = shift;
  confess "bug" if ref($_);
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
    s#qr/((?:\\.|[^\/])+)/([msixpodualngcer]*)
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

  $_
}
sub expstr2re($) {
  my $input = shift;
  my $xdesc; # extra debug description of intermediates
  my $output;
  if ($input !~ m#qr/|"::#) {
    # doesn't contain variable-representation items
    $output = $input;
    $xdesc = "";
  } else {
    my $s = _expstr2restr($input);
    my $saved_dollarat = $@;
    my $re = eval "qr{$s}"; die "$@ " if $@;
    $@ = $saved_dollarat;
    $xdesc = "**Orig match str  :".displaystr($input)."\n"
            ."**Generated re str:".displaystr($s)."\n" ;
    $output = $re;
  }
  wantarray ? ($xdesc, $output) : $output
}

# check $test_desc, string_or_regex, result
sub mycheck($$@) {
  my ($desc, $expected_arg, @actual) = @_;
  local $_;  # preserve $1 etc. for caller
  my @expected = ref($expected_arg) eq "ARRAY" ? @$expected_arg : ($expected_arg);
  if ($@) {
    local $_;
    confess "Eval error: $@\n" unless $@ =~ /fake/i;  # It's okay if $@ is "...Fake..."
  }
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
    my $xdesc = "";
    if (!ref($expected)) {
      # Work around different Perl versions stringifying regexes differently
      #$expected = expstr2re($expected);
      ($xdesc, $expected) = expstr2re($expected);
    }
    if (ref($expected) eq "Regexp") {
      unless ($actual =~ $expected) {
        @_ = ( "\n**************************************\n"
              ."TESTb FAILED: ".$desc."\n"
              ."Expected (Regexp):\n".${expected}."<<end>>\n"
              .$xdesc
              ."Got:\n".displaystr($actual)."<<end>>\n"
             ) ;
        Carp::confess(@_); #goto &Carp::confess;
      }
#say "###ACT $actual";
#say "###EXP $expected";
    } else {
      unless ($expected eq $actual) {
        @_ = ("TESTc FAILED: $desc", $expected, $actual);
        goto &mycheckeq_literal
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
    unless $ex;

  if ($ex !~ / at \Q$fn\E line $ln\.?(?:$|\R)/s) {
    confess "Got UN-expected err (not ' at $fn line $ln'):\n«$ex»\n",
            "\n";
  }
  if ($msg_regex && $ex !~ qr/$msg_regex/) {
    confess "Got UN-expected err (not matching $msg_regex) at $fn line $ln'):\n«$ex»\n",
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

  my $getcpu = eval {do{
    require Time::HiRes;
    () = (&Time::HiRes::clock());
    \&Time::HiRes::clock;
  }} // sub{ my @t = times; $t[0]+$t[1] };
  dprint("Note: $@") if $@;
  $@ = ""; # avoid triggering "Eval error" in mycheck();

  my $startclock = &$getcpu();
  my (@result, $result);
  if (wantarray) {@result = &$code(@codeargs)} else {$result = &$code(@codeargs)};
  my $cpusecs = &$getcpu() - $startclock;
  confess "TOOK TOO LONG ($cpusecs CPU seconds vs. limit of $maxcpusecs)\n"
    if $cpusecs > $maxcpusecs;
  if (wantarray) {return @result} else {return $result};
}

# Copy a file if needed to prevent any possibilty of it being modified.
# Returns the original path if the file is read-only, otherwise the path
# of a temp copy.
sub tmpcopy_if_writeable($) {
  my $path = shift;
  confess "$path : $!" unless stat($path);
  if ( (stat(_))[2] & 0222 ) {
    my ($name, $suf) = (basename($path) =~ /^(.*?)((?:\.\w{1,4})?)$/);
    (undef, my $tpath) =
      File::Temp::tempfile(SUFFIX => $suf, UNLINK => 1);
    File::Copy::copy($path, $tpath) or die "File::Copy $!";
    return $tpath;
  }
  $path
}

1;
