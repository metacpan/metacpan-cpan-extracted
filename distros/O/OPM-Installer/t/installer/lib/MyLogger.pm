package
    MyLogger;

my $log = '';

sub new { my ($class) = @_; return bless {}, $class; }

sub log {
    $log;
}

sub error  { my ($self, %p) = @_;  $log .= "[ERROR] " . $p{fatal} . "\n"; }
sub debug  { my ($self, %p) = @_;  $log .= "[DEBUG] " . $p{message} . "\n"; }
sub notice { my ($self, %p) = @_;  $log .= "[NOTICE] " . $p{message} . "\n"; }
sub info   { my ($self, %p) = @_;  $log .= "[INFO] " . $p{message} . "\n"; }
sub warn   { my ($self, %p) = @_;  $log .= "[WARN] " . $p{message} . "\n"; }

1;
