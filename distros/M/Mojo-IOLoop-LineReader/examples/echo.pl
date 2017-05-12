
use Mojo::Base -strict;
use Mojo::IOLoop::LineReader;

my $fn = shift or die "Usage: $0 <filename>\n";
open my $fh, '<', $fn or die qq{Can't open "$fn": $!};

my $r = Mojo::IOLoop::LineReader->new($fh);

my $c = 0;
$r->on(
  readln => sub {
    $c++;
    my ($r, $ln) = @_;
    print "$c: $ln";
  }
);
$r->on(close => sub { say "Bye." });

$r->start;
$r->reactor->start;
