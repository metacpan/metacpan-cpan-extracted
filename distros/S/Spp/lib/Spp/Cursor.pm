package Spp::Cursor;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(cursor go get_char pre_char cache recover max_report);

use 5.012;
no warnings "experimental";
use Spp::Builtin qw(to_end);

sub cursor {
   my ($str, $ns) = @_;
   $str = $str . chr(0);
   return {
      str => $str,
      ns  => $ns,
      len => length($str),
      off => 0,

      # record line number of souce code
      line => 1,

      # pos in current
      pos => 0,

      # 1 open debug mode 2: open gather token info
      debug => 0,

      # match_rule trace depth
      depth => 0,

      # get max reach location
      max_line => 1,
      max_off  => 0,
      max_pos  => 0,
   };
}

sub go {
   my $cursor = shift;
   if (get_char($cursor) eq "\n") {
      $cursor->{line}++;
      $cursor->{pos} = 0;
   }
   else {
      $cursor->{pos}++;
   }
   $cursor->{off}++;
   if ($cursor->{off} > $cursor->{max_off}) {
      $cursor->{max_off}  = $cursor->{off};
      $cursor->{max_line} = $cursor->{line};
      $cursor->{max_pos}  = $cursor->{pos};
   }
}

sub cache {
   my $cursor = shift;
   my $off    = $cursor->{off};
   my $line   = $cursor->{line};
   my $pos    = $cursor->{pos};
   return [$off, $line, $pos];
}

sub recover {
   my ($cursor, $cache) = @_;
   my ($off, $line, $pos) = @{$cache};
   $cursor->{off}  = $off;
   $cursor->{line} = $line;
   $cursor->{pos}  = $pos;
   return 1;
}

sub get_char {
   my $cursor = shift;
   return substr($cursor->{str}, $cursor->{off}, 1);
}

sub pre_char {
   my $cursor = shift;
   return substr($cursor->{str}, $cursor->{off} - 1, 1);
}

sub max_report {
   my $cursor   = shift;
   my $str      = $cursor->{str};
   my $off      = $cursor->{max_off};
   my $line     = $cursor->{max_line};
   my $pos      = $cursor->{max_pos};
   my $line_str = to_end(substr($str, $off - $pos));
   my $tip_str  = (' ' x $pos) . '^';
   return <<EOF;
Warning! Stop match at line: $line
   $line_str
   $tip_str
EOF
}

1;
