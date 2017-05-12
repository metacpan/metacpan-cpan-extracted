# Net::MSN::Debug - standardised logging routine.
# Written by DJ <dj@boxen.net>
#
# $Id: Debug.pm,v 1.2 2003/07/02 14:14:55 david Exp $

package Net::MSN::Debug;

use strict;
use warnings;

BEGIN {
  use Fcntl 'O_RDWR', 'O_CREAT';
  use POSIX;

  use vars qw($VERSION);

  $VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
}

# my $Logger = new Net::MSN::Debug(%opts);

sub new {
  my ($class, %args) = @_;

  my $self = bless({
    'Debug'     =>      0,
    'Level'     =>      0,
    'LogFile'   =>      '',
    'STDERR'    =>      0,
    'STDOUT'	=>	0,
    'LogCaller' =>      1,
    'LogTime'   =>      1,
    'LogLevel'  =>      1,
    'Version'   =>      $VERSION
  }, ref($class) || $class);

  $self->_set_options(\%args);

  $self->{log_obj} = sub{ $self->log(@_) };

  return $self;
}

sub _set_options {
  my ($self, $opts) = @_;

  my %opts = %$opts;
  foreach my $key (keys %opts) {
    $self->{$key} = $opts{$key};
  }
}

sub get_log_obj {
  my ($self) = @_;

  return $self->{log_obj};
}

sub clean {
  my ($self) = @_;

  if (defined $self->{LogFile} && -f $self->{LogFile}) {
    unlink($self->{LogFile});
  }
}

sub log {
  my ($self, $msg, $lvl, $file) = @_; 

  $lvl = 1 unless (defined $lvl && $lvl); 
  $self->{Level} = 1 unless (defined $self->{Level});

  return unless ((defined $self->{Debug} && $self->{Debug} == 1) &&
    (defined $self->{Level} && $self->{Level} !=0 && 
    $self->{Level} >= $lvl)); 

  my $logentry;

  if (defined $self->{LogTime} && $self->{LogTime} == 1) {
    my $date = POSIX::strftime( "%H:%M:%S %d %b %Y", localtime(time) );
    $logentry .= $date. ': ';
  }

  if (defined $self->{LogCaller} && $self->{LogCaller} == 1) {
    my ($package, $filename, $lineno, $subroutine, $hasargs, $wantarray,
      $evaltext, $is_require, $hints, $bitmask) = caller(1);

    unless (defined $subroutine && defined $package) {
      ($package, $filename, $lineno, $subroutine, $hasargs, $wantarray,
        $evaltext, $is_require, $hints, $bitmask) = caller();
    } elsif ($subroutine eq __PACKAGE__. '::__ANON__') {
      ($package, $filename, $lineno, $subroutine, $hasargs, $wantarray,
        $evaltext, $is_require, $hints, $bitmask) = caller(2);
    }
    $subroutine = $package. ' '. $subroutine. ' line: '. $lineno
      if (defined $subroutine && $subroutine =~ /^[(]*eval[)]*$/);
    
    $logentry .= (defined $subroutine && $subroutine) ? $subroutine : 'main';
    $logentry .= ' ';
  }

  if (defined $self->{LogLevel} && $self->{LogLevel} == 1) {
    $logentry .= 'L'. $lvl;
  }

  $logentry .= (defined $logentry && $logentry) ? '> '. $msg : $msg; 

  if (defined $self->{LogFile} && $self->{LogFile}) {
    open(DEBUGLOG, '>>'. $self->{LogFile});
    print DEBUGLOG $logentry. "\n";
    close(DEBUGLOG);
  }
  if (defined $self->{STDERR} && $self->{STDERR} == 1) {
    print STDERR $logentry. "\n";
  } elsif (defined $self->{STDOUT} && $self->{STDOUT} == 1) {
    print STDOUT $logentry. "\n";
  }
}

1;

