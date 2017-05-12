package Run;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;

# This is voodoo, but with these settings test works:

my $no_error_on_unwind_close = 1;
my $use_longer_control_F = 0;	# redir.t no. 13 is fragile with this

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	spawn
);
$VERSION = '0.03';

%EXPORT_TAGS = ( NEW => [qw(new_system new_spawn new_or new_and new_chain
			    new_env new_redir new_pipe new_readpipe
			    new_readpipe_split)] );
@EXPORT_OK = @{$EXPORT_TAGS{NEW}};

@Run::and::ISA = @Run::or::ISA = @Run::chain::ISA = @Run::spawn::ISA
  = @Run::system::ISA = qw(Run::base);

@Run::env::ISA = @Run::pipe::ISA = @Run::redir::ISA = qw(Run::base2);
@Run::readpipe::ISA = @Run::readpipe_split::ISA = qw(Run::base1);

my $Debug = $ENV{PERL_RUN_DEBUG} && fileno STDERR;
my $SaveErr;
if ($Debug) {
  if ($Debug > 1) {
    $SaveErr =  \*SAVERR;
    open $SaveErr, ">&STDERR" or die "Cannot dup STDERR: $!";
    require IO::Handle;
    bless $SaveErr, 'IO::Handle';
    $SaveErr->autoflush(1);
  } else {
    $SaveErr =  \*STDERR;
  }
}

sub spawn {
  if ($^O eq 'os2') {
    if (@_ == 1 and ( $_[0] =~ /[\`|\"\'\$&;*?\{\}\[\]\(\)<>\s~]/ 
				# backslashes are allowed as far as
				# there is no whitespace.
		      or $_[0] =~ /^\s*\w+=/ )) {
      # system 1, blah would not use shell
      unshift @_, '/bin/sh', '-c'; # /bin/sh will be auto-translated
                                   # to the installed place by system().
    }
    return system 1, @_;
  } elsif ($^O eq 'MSWin32' or $^O eq 'VMS') {
    return system 1, @_;
  } else {
    print $SaveErr "forking...\t\t\t\t\t\t\t\$^F=$^F\n" if $Debug;
    my $pid = fork;
    return unless defined $pid;
    return $pid if $pid;	# parent
    # kid:
    print $SaveErr "execing `@_'...\n" if $Debug;
    exec @_ or die "exec '@_': $!";
  }
}

sub xfcntl ($$$$;$) {
  my ($fh, $mode, $flag, $errs, $how) = @_;
  my $fd = ref $fh ? fileno $fh : $fh;
  $how ||= "";
  my $str_mode = '';
  $str_mode = ($mode == Fcntl::F_GETFD() 
	       ? '=get'
	       : ($mode == Fcntl::F_SETFD()
		  ? '=set'
		  : '=???')) if $Debug;

  my $ret = fcntl($fh, $mode, $flag)
      or push @$errs, "$ {how}fcntl get $fd: $!", 
	 ($Debug and print $SaveErr $errs->[-1], "\n"),
         return;
  print $SaveErr "$ {how}fcntl($fd, $mode$str_mode, $flag) => $ret\n"
    if $Debug;
  $ret;
}

sub xclose ($$$) {
  my ($fh, $errs, $how) = @_;
  my $fd = fileno $fh;

  print $SaveErr "$ {how}closing fd=$fd...\n" if $Debug;
  my $res = close($fh);
  print "$ {how}close $fh fd=$fd => `$res': $!\n"
    if not $res and $Debug;
  if ($res or $no_error_on_unwind_close and  $how eq "unwind: ") {
    return $res;
  }
  push(@$errs, "$ {how}close $fh fd=$fd: $!");
  return;
}

sub xfdopen ($$$$$) {
  my ($fh1, $fh2, $mode, $errs, $how) = @_;
  my $fd1 = fileno $fh1;
  my $fd2 = ref $fh2 ? fileno $fh2 : $fh2;
  my $res;
  my $omode = ($mode eq 'r' ? '<' : '>');
  
  print $SaveErr "$ {how}open( fd=$fd1, '$omode&$fd2')\n" if $Debug;

  if ($res = open($fh1,"$omode&$fd2")) {
    print $SaveErr "   -> ", fileno $fh1, "\t\t\t\t$res\t\$^F=$^F\n" if $Debug;
    return $res;
  } else {
    push(@$errs, "$ {how}open( fd=$fd1, '$omode&$fd2'): $!"), 
    ($Debug and print $SaveErr $errs->[-1], "\n"),
    return;
  }
}

sub xnew_from_fd ($$$$) {	# Give up soon
  my ($fh, $mode, $errs, $how) = @_;
  my $fd = ref $fh ? fileno $fh : $fh;
  my $fd_printable = ref $fh ? "fh=>" . fileno $fh : $fh;

  print $SaveErr "$ {how}new_from_fd($fd_printable, $mode)\n" if $Debug;
  my $res = IO::Handle->new_from_fd($fh, $mode);
  if ($res) {
    print $SaveErr "   -> ", fileno $res, "\t\t\t\t$res\t\$^F=$^F\n" if $Debug;
    return $res;
  }
  push @$errs, "$ {how}new_from_fd($fd_printable, $mode): $!";
  print $SaveErr $errs->[-1], "\n" if $Debug;
  return;
}

# if we need to close_in_keed and need_in_parent, we need unwinding of fcntl
#
# returns undef on failure
#
# list to close may be too big, exclude fds which are going to be redirected
#
# Note that this is probably excessive, $^F handles this in simplest cases
#
# Need to maintain a list of all open fd, and give it to this guy
sub process_close_in_kid {
  # Stderr may be redirected, so we save the err text in @$errs:
  my ($close_in_child, $unwind, $redirected, $errs) = @_;
  return unless @$close_in_child;
  require Fcntl;
  my $fd;
  
  foreach $fd (@$close_in_child) {
    next if $redirected->{$fd}; # Do not close what we redirect!
    my $fl = xfcntl($fd, Fcntl::F_GETFD(), 1, $errs) or return;
    next if $fl & Fcntl::FD_CLOEXEC();
    xfcntl($fd, Fcntl::F_SETFD(), $fl | Fcntl::FD_CLOEXEC(), $errs) 
      or return;
    push @$unwind, ["fset", $fd, $fl];
  }
  return 1;
}

# returns undef on failure
sub do_unwind {
  my ($unwind, $errs) = @_;
  my $cmd;
  my $res = 1;

  while (@$unwind) {
    $cmd = pop @$unwind;
    if ($cmd->[0] eq 'fset') {
      xfcntl($cmd->[1], Fcntl::F_SETFD(), $cmd->[2], $errs, "unwind: ") 
	or undef $res;		# Continue on error
    } elsif ($cmd->[0] eq 'close') {
      xclose($cmd->[1], $errs, "unwind: ")
	or undef $res;		# Continue on error
    } elsif ($cmd->[0] eq 'fdopen') {
      xfdopen($cmd->[1], $cmd->[2], $cmd->[3], $errs, "unwind: ")
	or undef $res;		# Continue on error
    } else {
      push(@$errs, "unwind: unknown cmd `@$cmd'");
      print $SaveErr $errs->[-1], "\n" if $Debug;
    }
  }
  return $res;
}

sub cvt_2filehandle {
  my ($fds, $unwind, $errs) = @_;
  my ($fd, $fd_data);
  # Convert filename => filehandle.
  for $fd (keys %$fds) {
    $fd_data = $fds->{$fd};

    my $file = delete $fd_data->{filename};
    if ($file) {
      require IO::File;
      my $fh;

      # Will open a wrong guy, there should be a different way to do this...
      if (0 and $file =~ /^\s*([<>])\s*&\s*=\s*(.*)/s) {
	my $fd = $2;
	my $mode = $1 eq '<' ? "r" : "w";
	
	$fd = fileno $fd unless $fd =~ /^\d+\s*$/;
	$fh = fd_2filehandle($fd, $mode, $fds, $unwind, $errs) or return;
      } else {
	print $SaveErr "open `$file'\n" if $Debug;
	$fh = new IO::File $file 
	  or (push @$errs, "Cannot open `$file': $!"), 
	  ($Debug and print $SaveErr $errs->[-1], "\n"),
	  return;
	print $SaveErr "  --> ", fileno $fh, "\t\t\t\t$fh\t\$^F=$^F\n" if $Debug;
	push @$unwind, ["close", $fh]; # Will be done automagically when
	# goes out of scope, but would
	# not hurt to do earlier	
      }
      $fd_data->{filehandle} = $fh;
      $fd_data->{mode} = ($file =~ /^\s*(\+\s*)?[>|]/ ? 'w' : 'r');
      $fd_data->{kid_only} = 0;	# :-( Might redirect several kids to it
    }
  }
  return 1;
}

# Need to keep filehandles globally, since closing a clone close 
# the original
my %fd_hash = ( 0 => \*STDIN, 1 => \*STDOUT, 2 => \*STDERR);

# $old is any filehandle which is going to live long enough.
sub fd_2filehandle ($$$$$) {
  my ($fd,$mode,$fds,$unwind,$errs) = @_;
  require Fcntl;
  if (exists $fd_hash{$fd} and defined fileno($fd_hash{$fd})
      and fileno($fd_hash{$fd}) == $fd
      and fcntl($fd_hash{$fd}, Fcntl::F_GETFD(), 1)) { # Checking that it is not closed!
    require IO::Handle;
    bless $fd_hash{$fd}, 'IO::Handle' if ref $fd_hash{$fd} eq 'GLOB';
    print $SaveErr "filehandle $fd stashed...\n" if $Debug;
    return $fd_hash{$fd};	# In fact the corresponding FD may be
                                # closed, but there is nothing to do
                                # about it...
  }
  delete $fd_hash{$fd};
  # Grab the file descriptor
  my $fh = xnew_from_fd($fd, $mode, [], "grabfd: "); # ignore errors
  if (not defined $fh and $! =~ /bad\s+file\s+number/i) {
    print $SaveErr "Recovering from error in new_from_fd...\n" if $Debug;
    # Try to create missing filehandles
    my ($cnt, @tmp, $tmp_fh, $ok) = 0;
    my $old = $fds->{$fd}{filehandle};
    
    while ($cnt++ <= $fd) {	# Give up soon
      $tmp_fh = xnew_from_fd($old, $mode, $errs, "intermed fd: ") or return;
      $ok = 1, last if fileno $tmp_fh == $fd;
      push @tmp, $tmp_fh;
    }
    unless ($ok) {
      push @$errs, "Could not create fd=$fd";
      print $SaveErr $errs->[-1], "\n" if $Debug;
      return;
    }
    $fds->{$fd}{tmp_filehandles} = []
      unless defined $fds->{$fd}{tmp_filehandles};
    push @{$fds->{$fd}{tmp_filehandles}}, @tmp; # Do not close these guys soon
    $fh = $tmp_fh;
    process_close_in_kid(\@tmp, $unwind, $fds, $errs) or return;
  }
  return $fd_hash{$fd} = $fh;	# never close this
}

sub redirect_in_kid {
  my ($fds,$unwind,$errs,$max_fd_r) = @_;
  my ($fd_data, $fd);
  my $max_fd = -1;
  # Count
  for $fd (keys %$fds) {
    $max_fd = $fd if $fd > $max_fd;
  }
  return 1 unless $max_fd > -1;

  cvt_2filehandle($fds,$unwind,$errs) or return;
  
  # The guys below this level will be dup2()ed to on fdopen().
  # They also will not be closed on exec
  local $^F = $$max_fd_r = $max_fd if $max_fd > $^F; 

  my @close_in_child;
  require IO::Handle;
  for $fd (keys %$fds) {
    $fd_data = $fds->{$fd};

    # Grab the file descriptor
    $fd_data->{pre_filehandle} =
      fd_2filehandle($fd, $fd_data->{mode}, $fds, $unwind, $errs)
	or return;

    # Now save a copy to another filedescriptor
    $fd_data->{pre_filehandle_save} 
      = xnew_from_fd($fd_data->{pre_filehandle}, $fd_data->{mode}, $errs, "savecopy: ")
	or return;
    push @$unwind, ["close", $fd_data->{pre_filehandle_save}];
    push @close_in_child, $fd_data->{pre_filehandle_save};
    
    xfdopen($fd_data->{pre_filehandle}, fileno $fd_data->{filehandle},
	    $fd_data->{mode}, $errs, "final: ")
      or return;
    push @$unwind, 
      ["fdopen", $fd_data->{pre_filehandle}, $fd_data->{pre_filehandle_save},
       $fd_data->{mode}];
  }

  # Arrange for things to be closed in the kid:
  process_close_in_kid(\@close_in_child, $unwind, $fds, $errs) 
    or return;
  return 1;
}

sub run_system_spawn {
  my $do_spawn = shift;
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  # Sets result in $data->{result} on failure
  (local %::ENV = %::ENV), 
  @::ENV{keys %{$data->{env}}} = values %{$data->{env}}
    if (exists $data->{env});

  # Expand args:
  my @args = map {ref $_ ? $_->run : ($_)} @$tree;
  my $has_undef = grep {not defined} @args;
  return if $has_undef;

  my $unwind = [];
  my $max_fd;
  my $print_errs = not exists $data->{errs};
  my $errs = $print_errs ? [] : $data->{errs};
  
  if (defined $data->{redir}) {	# local could create undefined value
    my $res = redirect_in_kid($data->{redir},$unwind,$errs,\$max_fd);
    if (not $res) {
      local $^F = $max_fd 
	if defined $max_fd and $max_fd > $^F and $use_longer_control_F;
      do_unwind($unwind,$errs);
      # Should hope that STDERR is now restored
      print STDERR join "\n", @$errs, "" if $print_errs and @$errs;
      return;
    }
  }
  local $^F = $max_fd 
    if defined $max_fd and $max_fd > $^F and $use_longer_control_F;

  my $res;
  if ($do_spawn or $data->{'spawn'}) {
    $res = spawn @args;
    push @{$data->{pids}}, $res if defined $res;
    push @$errs, "spawn `@args': $!" unless defined $res;
  } else {
    $res = system @args;    
    $data->{result} = $res if $res;
    push @$errs, "system `@args': rc=$res: $!" if $res;	# XXXX?
    $res = ($res == 0 ? 1 : undef);
  }

  do_unwind($unwind,$errs) if @$unwind;
  # Should hope that STDERR is now restored
  print STDERR join "\n", @$errs, "" if $print_errs and @$errs;
  return $res;
}

sub Run::system::run {
  run_system_spawn(0,@_);
}

sub Run::spawn::run {
  run_system_spawn(1,@_);
}


sub Run::chain::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  my $out = 1;
  
  print(STDERR "cannot 'chain' with spawn: $!\n"), return if $data->{'spawn'};
  for my $cmd (@$tree) {
    my $res = $cmd->run($data);
    undef $out unless defined $res;
  }
  return $out;
}

sub Run::and::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  
  print(STDERR "cannot 'and' with spawn: $!\n"), return if $data->{'spawn'};
  for my $cmd (@$tree) {
    my $res = $cmd->run($data);
    return unless defined $res;
  }
  return 1;
}

sub Run::or::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  
  print(STDERR "cannot 'or' with spawn: $!\n"), return if $data->{'spawn'};
  for my $cmd (@$tree) {
    my $res = $cmd->run($data);
    return 1 if defined $res;
  }
  return;
}

sub Run::env::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  my $cmd = $tree->[1];
  local $data->{env} = $data->{env};
  $data->{env} = {} unless defined $data->{env};
  my %env = %{$data->{env}};
  my $env = $tree->[0];
  @{$data->{env}}{keys %$env} = values %$env;
  
  my $res = $cmd->run($data);
  %{$data->{env}} = %env;
  return $res;
}

sub Run::redir::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  my $cmd = $tree->[1];
  local $data->{redir} = $data->{redir};
  $data->{redir} = {} unless defined $data->{redir};
  #local %{$data->{redir}} = %{$data->{redir}}; # Preserve data from being wiped
  my %oldredir = %{$data->{redir}}; # Preserve data from being wiped
  
  my $redir = $tree->[0];
  my $unwind = [];
  my $print_errs = not exists $data->{errs};
  my $errs = $print_errs ? [] : $data->{errs};
  my $ret;
  if (cvt_2filehandle($redir,$unwind,$errs)) { # OK
    my ($fd, $rfd);
    if (%{$data->{redir}}) {
      for $fd (keys %$redir) {
	$rfd = fileno $redir->{$fd}{filehandle};
	next unless exists $data->{redir}{$rfd}; # Target redirected already
	$redir->{$fd} = $data->{redir}{$rfd};
      }
    }
    @{$data->{redir}}{keys %$redir} = values %$redir;
  
    $ret = $cmd->run($data);
    return $ret unless @$unwind;
  }
  do_unwind($unwind,$errs) if @$unwind;
  # STDERR should not be redirected above, but signature of do_unwind is such...
  print STDERR join "\n", @$errs, "" if $print_errs and @$errs;
  %{$data->{redir}} = %oldredir; # Restore the data
  return $ret;
}

sub Run::pipe::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  my $cmd = $tree->[1];
  my $dir = $tree->[0];
  require IO::Handle;
  my $rpipe = IO::Handle->new;
  my $wpipe = IO::Handle->new;

  print $SaveErr "pipe creation (parent will $dir)\n" if $Debug;
  pipe($rpipe,$wpipe) 
    or print(STDERR "cannot create pipe: $!\n"), return;
  print $SaveErr "  --> ", fileno $rpipe, "\t\t\t\tread  $rpipe\t\$^F=$^F\n" if $Debug;
  print $SaveErr "  --> ", fileno $wpipe, "\t\t\t\twrite $wpipe\t\$^F=$^F\n" if $Debug;
  my ($toclose, $ret, $redir);
  
  if ($dir eq 'r') {
    $redir = new_redir({1 => {filehandle => $wpipe, mode => 'w'}}, $cmd);    
    $toclose = $wpipe;
    $ret = $rpipe;
  } else {
    $redir = new_redir({0 => {filehandle => $rpipe, mode => 'r'}}, $cmd);        
    $toclose = $rpipe;
    $ret = $wpipe;
  }
  # XXXX Do not use unwind argument???
  process_close_in_kid([$ret],[],{},[]); # XXXX No error handling here
  local $data->{'spawn'} = 1;
  $redir->run($data) or return;

  # XXXX This is not needed, since run() called unwind() which closed
  # fd=0/1, which invalidated $toclose anyway.

  xclose($toclose,[],"pipe::run: ")
    or print(STDERR "pipe::run: cannot close pipe end not belonging to me: $!\n"), return;
  return $ret;
}

sub Run::readpipe::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  my $cmd = $tree->[0];
  my $pipe = Run::pipe->new("r", $cmd)->run($data) or return;
  $pipe->input_record_separator(undef);
  return scalar <$pipe>;
}

sub Run::readpipe_split::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  my $cmd = $tree->[0];
  my $pipe = Run::pipe->new("r", $cmd)->run($data) or return;
  $pipe->input_record_separator(undef);
  return split ' ', scalar <$pipe>;
}

sub Run::base::new {
  my $class = shift;
  bless [@_], $class;
}

sub Run::base2::new {
  my $class = shift;
  die "need two arguments in $class\->new" unless @_ == 2;
  bless [@_], $class;
}

sub Run::base1::new {
  my $class = shift;
  die "need one argument in $class\->new" unless @_ == 1;
  bless [@_], $class;
}

sub new_system	{ Run::system->new(@_) }
sub new_spawn	{ 'Run::spawn'->new(@_) }
sub new_or	{ Run::or->new(@_) }
sub new_and	{ Run::and->new(@_) }
sub new_chain	{ Run::chain->new(@_) }
sub new_env	{ Run::env->new(@_) }
sub new_redir	{ Run::redir->new(@_) }
sub new_pipe	{ Run::pipe->new(@_) }
sub new_readpipe	{ Run::readpipe->new(@_) }
sub new_readpipe_split	{ Run::readpipe_split->new(@_) }

1;
__END__

=head1 NAME

Run - Perl extension for to start programs in background

=head1 SYNOPSIS

  use Run;
  $pid = spawn 'long_running_task', 'arg1', 'arg2' or die "spawn: $!";
  do_something_else();
  waitpid($pid,0);

=head1 DESCRIPTION

The subroutine C<spawn> is equivalent to the builtin C<system> (see
L<perlfunc/system LIST>) with the exceptions that the program is
started in background, and the return the C<pid> of the kid.

Returns 0 on failure, $! should contain the reason for the failure.

=head1 EXPORT

Exports C<spawn> by default.

=head1 AUTHOR

Ilya Zakharevich <ilya@math.ohio-state.edu

=head1 TODO

What to do with C<errs> in C<or>?  Should they be cleared?

=head1 ENVIRONMENT

C<PERL_RUN_DEBUG> is used to set debugging flag.

=head1 NOTES

C<open FH, "E<gt>&=FH1"> creates a "naughty" copy of C<FH1>.  Closing
C<FH> will invalidate C<FH1>.

=head1 SEE ALSO

perl(1).

=cut
