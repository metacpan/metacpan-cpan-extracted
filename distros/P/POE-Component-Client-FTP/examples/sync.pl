#!/usr/bin/perl

# Usage:
# sync.pl host:user:pass /local/path /remote/path
# 
# I would not recommend using this code on anything important
# I lost half web site catching a bug ;)
# Error checking is weak in some areas, but it demonstrates a variety
# of the methods used for the module.

# sub POE::Component::Client::FTP::DEBUG         () { 1 };
# sub POE::Component::Client::FTP::DEBUG_COMMAND () { 1 };
# sub POE::Kernel::TRACE_EVENTS () { 1 }

use strict;
use POE qw(Wheel::Run);
use POE::Component::Client::FTP;
use Carp;
use Date::Manip;
use FileHandle;
use File::Copy;

$|++;

my $conn = shift;
my ($server,$user,$pass) = split /:/, $conn;
my $lwd = shift;
my $rwd = shift;

-e $lwd or mkdir $lwd;
chdir $lwd or croak $!;

-e ".backup" or mkdir ".backup";


# note the method of mapping mkdir, get_done, and put_done back
# to the method that dispatched the message originally
# this creates a loop until the dispatch decides to go somewhere else
POE::Session->create
  (
   inline_states => {
		     _start        => \&start,
		     authenticated => \&authenticated,

		     ls_data       => \&ls_data,
		     ls_done       => \&ls_done,
		     ls_error      => \&error,

		     do_local_ls   => \&do_local_ls,
		     do_compare    => \&do_compare,
		     do_mkdir      => \&do_mkdir,
		     do_upload     => \&do_upload,
		     do_download   => \&do_download,
		     do_done       => \&do_done,

		     mkdir         => \&do_mkdir,
		     mkdir_error   => \&do_mkdir,

		     get_data      => \&get_data,
		     get_done      => \&do_download,
		     get_error     => \&error,

		     put_connected => \&put_connected,
		     put_closed    => \&do_upload,
		     put_flushed   => \&put_flushed,
		     put_error     => \&error,
		    }
  );

# register for the events to be posted back here
sub start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  my $ftp = POE::Component::Client::FTP->spawn
    (
     Alias      => 'ftp',
     
     RemoteAddr => $server,
     Username   => $user,
     Password   => $pass,
     
     Events => [qw(all)]
    );
}

# successful login
sub authenticated {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  
  $kernel->post('ftp', 'cd', $rwd);
  $kernel->post('ftp', 'ls', '-AR');
}

# parsing worked for my web host
sub ls_data {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
  
  local $_ = $input;

  if (my ($path) = /^\.?\/?(.*):$/) {
    $heap->{remote_lastpath} = $path;
  }
  elsif ( my ($perm, $size, $date, $filename) = 
	  /^(\S+)\s+\d+\s+\S+\s+\S+\s+(\d+)\s+(\S+\s+\S+\s+\S+)\s+(.*)$/) {
    $heap->{remote_files}->{ ($heap->{remote_lastpath} ? "$heap->{remote_lastpath}/" : "") . $filename } = [$perm, $date, $size];
  }
  elsif ($_ and not /^total/) {
    warn "Unexpected line: '$heap->{remote_lastpath} $_'";
  }
}

# string along events for scripting
sub ls_done {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
  
  $kernel->post($session, "do_local_ls");  
}

sub do_local_ls {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
  
  foreach (`ls -lAR1`) {
    chomp;

    if (my ($path) = /^\.?\/?(.*):$/) {
      $heap->{local_lastpath} = $path;
    }
    elsif ( my ($perm, $size, $date, $filename) = 
	    /^(\S+)\s+\d+\s+\S+\s+\S+\s+(\d+)\s+(\S+\s+\S+\s+\S+)\s+(.*)$/) {
      $heap->{local_files}->{ ($heap->{local_lastpath} ? "$heap->{local_lastpath}/" : "") . $filename } = [$perm, scalar(gmtime((stat $filename)[9])), $size];
    }
    elsif ($_ and not /^total/) {
      warn "Unexpected line: '$heap->{local_lastpath} $_'";
    }
  }

  $kernel->post($session, "do_compare");
}

sub do_compare {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
  
  my (@rmkdir, @rmake, @lmkdir, @lmake, @lupdate, @rupdate);

  foreach my $file (keys %{ $heap->{local_files} }, 
		 keys %{ $heap->{remote_files} } ) {
    if (not exists $heap->{remote_files}->{$file}) {
      if ($heap->{local_files}->{$file}->[0] =~ /^d/) {
	push @rmkdir, $file;
      }
      elsif ($heap->{local_files}->{$file}->[0] =~ /^-/) {
	push @rmake, $file;
      }
      delete $heap->{local_files}->{$file};
    }
    elsif (not exists $heap->{local_files}->{$file}) {
      if ($heap->{remote_files}->{$file}->[0] =~ /^d/) {
	push @lmkdir, $file
      }
      elsif ($heap->{remote_files}->{$file}->[0] =~ /^-/) {
	push @lmake, $file;
      }
      delete $heap->{remote_files}->{$file};
    }
    else {
      if ($heap->{local_files}->{$file}->[0] =~ /^-/) {
	if ( $heap->{local_files}->{$file}->[2] != 
	     $heap->{remote_files}->{$file}->[2] ) {
	  my $localtime  = ParseDate( $heap->{local_files}->{$file}->[1] );
	  my $remotetime = ParseDate( $heap->{remote_files}->{$file}->[1] );
	  my $compare    = Date_Cmp($localtime, $remotetime);
	  
	  if ($compare < 0) {
	    push @lupdate, $file;
	  }
	  elsif ($compare > 0) {
	    push @rupdate, $file;
	  }
	}
      }
      delete $heap->{local_files}->{$file};
      delete $heap->{remote_files}->{$file};
    }
  }

  for (sort {length $a <=> length $b} @lmkdir) {
    mkdir $_ or croak "mkdir $_: $!";
  }

  $heap->{mkdir} = [ sort {length $a <=> length $b} @rmkdir ];
  $heap->{stor}  = [ grep !/^.backup/, (@rmake, @rupdate) ];
  $heap->{retr}  = [ grep !/^.backup/, (@lmake, @lupdate) ];

  $kernel->post($session, 'do_mkdir');
}

# point the mkdir message back here until the queue is empty
# then proceed to uploads
sub do_mkdir {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

  if ( defined( my $dir = shift @{ $heap->{mkdir} } ) ) {
    print "MKD $dir\n";
    $kernel->post('ftp', 'mkdir', $dir);
  }
  else {
    $kernel->post($session, 'do_upload');
  }
}

# 
sub do_upload {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

  print "\n";

  if ( defined( my $file = shift @{ $heap->{stor} } ) ) {
    (my $backup = $file) =~ s{/}{_}g;
    if (exists $heap->{remote_files}->{$file}) {
      $kernel->post('ftp', 'rename', $file, ".backup/$backup" );
    }
    $kernel->post('ftp', 'type', 'I');
    print "STOR $file";
    $kernel->post('ftp', 'put', $file);
  }
  else {
    $kernel->post($session, 'do_download');
  }
}

# start the upload
sub put_connected {
  my ($kernel, $heap, $session, $filename) = @_[KERNEL, HEAP, SESSION, ARG2];

  undef $heap->{stor_fh};
  $heap->{stor_fh} = new FileHandle ("< $filename") or croak "$filename: $!";

  print ".";
  $kernel->post($session, 'put_flushed');
}

# upload 10k at a time
# see dotfer.pl for example of uploading all at once
# this method avoids having the entire file in memory
sub put_flushed {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

  print ".";
  
  my $buf;
  if (read $heap->{stor_fh}, $buf, 10240) {
    $kernel->post('ftp', 'put_data', $buf)
  }
  else {
    $kernel->post('ftp', 'put_close')
  }
}

# just like the uploads
sub do_download {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

  print "\n";

  undef $heap->{retr_fh};

  if ( defined( my $file = shift @{ $heap->{retr} } ) ) {
    (my $backup = $file) =~ s{/}{_}g;    

    if (exists $heap->{local_files}->{$file}) {
      copy $file, ".backup/$backup" or warn "error making backup: $!";
    }

    $heap->{retr_fh} = new FileHandle ("> $file") or croak "$file: $!";
    
    $kernel->post('ftp', 'type', 'I');
    print "RETR $file";
    $kernel->post('ftp', 'get', $file);
  }
  else {
    $kernel->post($session, 'do_done');
  }
}

# data as you get it
sub get_data {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  print ".";
  $heap->{retr_fh}->print($input);
}

# final step
sub do_done {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  print "Done!\n";
  $kernel->post('ftp', 'quit');
}

# catch-all for everything
# this is, of course, a poor method of error handling but its easy :)
sub error {
  my ($kernel, $heap, @args) = @_[KERNEL, HEAP, ARG0 .. $#_];
  croak "\nUnexpected error: @args";
}


# and go
$poe_kernel->run();
