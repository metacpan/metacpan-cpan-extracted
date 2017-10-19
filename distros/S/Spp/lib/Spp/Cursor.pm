package Spp::Cursor;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(new_cursor to_next cache reset_cache get_char pre_char fail_report);

use Spp::Builtin;

sub new_cursor {
  my ($str, $ns) = @_;
  my $text = add($str, End);
  my $len = len($text);
  return {
    'text'    => $text,
    'ns'      => $ns,
    'len'     => $len,
    'off'     => 0,
    'line'    => 1,
    'depth'   => 0,
    'maxoff'  => 0,
    'maxline' => 1
  };
}

sub to_next {
  my $cursor = shift;
  if (get_char($cursor) eq "\n") { $cursor->{'line'}++ }
  $cursor->{'off'}++;
  if ($cursor->{'off'} > $cursor->{'maxoff'}) {
    $cursor->{'maxoff'}  = $cursor->{'off'};
    $cursor->{'maxline'} = $cursor->{'line'};
  }
  return True;
}

sub cache {
  my $cursor = shift;
  my $off    = $cursor->{'off'};
  my $line   = $cursor->{'line'};
  return [$off, $line];
}

sub reset_cache {
  my ($cursor, $cache) = @_;
  $cursor->{'off'}  = $cache->[0];
  $cursor->{'line'} = $cache->[1];
  return True;
}

sub get_char {
  my $cursor = shift;
  return substr($cursor->{'text'}, $cursor->{'off'}, 1);
}

sub pre_char {
  my $cursor = shift;
  return substr($cursor->{'text'}, $cursor->{'off'} - 1, 1);
}

sub fail_report {
  my $cursor   = shift;
  my $text     = $cursor->{'text'};
  my $off      = $cursor->{'maxoff'};
  my $line     = $cursor->{'maxline'};
  my $line_str = to_end(substr($text, $off));
  return "line: $line Stop match:\n$line_str\n^";
}
1;
