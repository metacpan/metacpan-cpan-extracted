package Plack::Middleware::Scrutiny::Util;

use Data::Dumper;
use Time::HiRes qw( time );
use Storable qw( freeze thaw );
use parent 'Exporter';
our @EXPORT = qw( debug send receive );

use constant DEBUG => 1;

sub debug(@) {
  return unless DEBUG;
  my (@stuff) = @_;
  local $Data::Dumper::Terse    = 1;
  local $Data::Dumper::Sortkeys = 1;
  open my $debug, '>>', 'debug.log' or die "Error opening debug.log";
  my $time = sprintf("%0.05f", time());
  print $debug "$time";
  while(my $stuff = shift @stuff) {
    if(ref $stuff) {
      print $debug " ";
      print $debug Dumper($stuff);
    } else {
      print $debug " $stuff";
      print $debug "\n" unless @stuff;
    }
  }
  close $debug;
}

sub send {
  my ($self, $dest, $type, $val) = @_;

  my $dest_handle = $self->{$dest};
  
  my $from = $dest eq 'to_child' ? 'parent' : 'child';
  debug $from, "send $dest $type $val";
  # debug val => $val;
 
  print $dest_handle "$type\n";
 
  $val = freeze($val);
  $val = unpack('h*', $val);
  print $dest_handle "$val\n";
}

sub receive {
  my ($self, $source) = @_;

  my $from = $source eq 'from_child' ? 'parent' : 'child';
  debug $from, "receive $source";

  my $source_handle = $self->{$source};

  my $cmd = <$source_handle>;
  chomp $cmd;

  debug "got cmd '$cmd'";
  
  my $val = <$source_handle>;
  chomp $val;
  $val = pack('h*',$val);
  $val = thaw($val);

  return ($cmd, $val);
}


1;

