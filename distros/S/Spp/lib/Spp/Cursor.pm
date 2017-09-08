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
      str     => $str,
      ns      => $ns,
      len     => length($str),
      off     => 0,
      line    => 1,
      pos     => 0,
      mode    => 0,
      depth   => 0,
      maxoff  => 0,
      maxline => 1,
      maxpos  => 0,
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
   if ($cursor->{off} > $cursor->{maxoff}) {
      $cursor->{maxoff}  = $cursor->{off};
      $cursor->{maxline} = $cursor->{line};
      $cursor->{maxpos}  = $cursor->{pos};
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
   substr($cursor->{str}, $cursor->{off}, 1);
}

sub pre_char {
   my $cursor = shift;
   substr($cursor->{str}, $cursor->{off} - 1, 1);
}

sub max_report {
   my $cursor   = shift;
   my $str      = $cursor->{str};
   my $off      = $cursor->{maxoff};
   my $line     = $cursor->{maxline};
   my $pos      = $cursor->{maxpos};
   my $line_str = to_end(substr($str, $off - $pos));
   my $tip_str  = (' ' x $pos) . '^';
   return <<EOF;
Warning! Stop match at line: $line
   $line_str
   $tip_str
EOF
}

1;
