package ForTest;

use lib qw(lib ../lib);
use Su::Log;

sub new {
  my $self = shift;
  return bless {}, $self;
}

sub info_test {
  my $self = shift;
  my $log  = Su::Log->new($self);
  return $log->info("info message.");
}

sub trace_test {
  my $self = shift;
  my $log  = Su::Log->new($self);
  return $log->trace("trace message.");
}

1;
