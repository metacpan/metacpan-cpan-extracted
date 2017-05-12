package TestStatsd;

our $ALWAYS_SAMPLE = 0;

BEGIN {
  our $ALWAYS_SAMPLE = 0;
  *CORE::GLOBAL::rand = sub {
    if ($ALWAYS_SAMPLE) {
      return 0; # rand() < $sample_rate will now always be true unless $sample_rate is 0
    } else {
      return &CORE::rand(@_);
    }
  };
}
  
use Test::More;
use Exporter 'import';
our @EXPORT = qw(sends_ok);

sub sends_ok (&@) {
  my ($code, $client, $pattern, $desc) = @_;
  my $sent;

  my $ok = eval {
    no warnings 'redefine';
    local *Etsy::StatsD::_send_to_sock = sub {
      $sent .= $_[1];
    };
    $code->();
    1;
  };
  if (!$ok) {
    diag "Died: $@";
    fail $desc;
    return;
  }
  like $sent, $pattern, $desc;
}

