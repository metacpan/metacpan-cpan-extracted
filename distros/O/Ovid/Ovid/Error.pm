package Ovid::Error;
use strict;

use Exporter;
@Ovid::Error::ISA = qw(Exporter);
@Ovid::Error::EXPORT = qw(info debug warning fatal $LOG_LEVEL LOG_LEVEL_DEBUG LOG_LEVEL_INFO);

our $LOG_LEVEL;

use constant LOG_LEVEL_DEBUG => 2;
use constant LOG_LEVEL_INFO => 4;

sub info (@);
sub debug (@);
sub warning (@);
sub fatal (@);

sub maybe_exit {
  #do nothing, usually
}

sub debug (@) { goto &warning if $LOG_LEVEL & LOG_LEVEL_DEBUG }
sub info(@) { goto &warning if $LOG_LEVEL & LOG_LEVEL_INFO }

sub warning(@) 
  {
    my $err = join ' ', map { tr/\n//; $_; } @_;
    if ($err)
      {
        my $caller = (caller(1))[3];
        my $prefix = $0;
        $prefix = (join ':', $prefix, $caller) if $caller;
        warn "$prefix: $err\n";
      }
    
    &maybe_exit;
  }

sub fatal(@) 
  {
    *maybe_exit = sub { exit 1 };
    unshift @_, 'fatal error -- ';
    goto &warning;
  }

1;

