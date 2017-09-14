package Spp::Cursor;

use 5.012;
no warnings "experimental";

use Spp::Core qw(to_end);

sub new {
   my ($class, $str, $ns) = @_;
   my $trace_str = $str . chr(0);
   my $len_str = length($trace_str);
   return bless({
      str     => $trace_str,
      ns      => $ns,
      len     => $len_str,
      off     => 0,
      line    => 1,
      pos     => 0,
      depth   => 0,
      maxoff  => 0,
      maxline => 1,
      maxpos  => 0,
   }, $class);
}

sub off {
   my $self = shift;
   return $self->{'off'};
}

sub str {
   my $self = shift;
   return $self->{'str'};
}

sub len {
   my $self = shift;
   return $self->{'len'};
}

sub go {
   my $self = shift;
   if (get_char($self) eq "\n") {
      $self->{line}++;
      $self->{pos} = 0;
   }
   else {
      $self->{pos}++;
   }
   $self->{off}++;
   if ($self->{off} > $self->{maxoff}) {
      $self->{maxoff}  = $self->{off};
      $self->{maxline} = $self->{line};
      $self->{maxpos}  = $self->{pos};
   }
}

sub cache {
   my $self = shift;
   my $off    = $self->{off};
   my $line   = $self->{line};
   my $pos    = $self->{pos};
   return [$off, $line, $pos];
}

sub recover {
   my ($self, $cache) = @_;
   my ($off, $line, $pos) = @{$cache};
   $self->{off}  = $off;
   $self->{line} = $line;
   $self->{pos}  = $pos;
   return 1;
}

sub get_char {
   my $self = shift;
   my $str = $self->{str};
   my $off = $self->{off};
   return substr($str, $off, 1);
}

sub pre_char {
   my $self = shift;
   my $str = $self->{str};
   my $off = $self->{off};
   return substr($str, $off-1, 1);
}

sub max_report {
   my $self   = shift;
   my $str      = $self->{str};
   my $off      = $self->{maxoff};
   my $line     = $self->{maxline};
   my $pos      = $self->{maxpos};
   my $tip_str  = to_end(substr($str, $off - $pos));
   my $tip_char = (' ' x $pos) . '^';
   return <<EOF;
Warning! Stop match at line: $line
   $tip_str
   $tip_char
EOF
}

sub error {
   my ($self, $message) = @_;
   my $max_report = $self->max_report();
   say $max_report; 
   say $message;
   exit();
}

1;
