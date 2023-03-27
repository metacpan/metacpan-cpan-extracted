use strict;
use warnings;
use Carp qw(confess);

our $DCODE_RE = qr/[\@\\]/;
# mutates $_[0]
sub doxy_bits {
  my (undef, $words, $hash, $key) = @_;
  my $re = '(?:'.join('|', @$words).')';
  my $bit_re = qr/$DCODE_RE$re\s+(.*?)(?=$DCODE_RE|\n{2,}|\n*\z)/s;
  my @p;
  while ($_[0] =~ s/$bit_re//) {
    push @p, $1;
  }
  $hash->{$key} = \@p if @p;
}

our %DPARSE = (
  code => ['endcode'],
  'f$' => ['f\$'],
);
our $DPARSE_RE = '('.join('|', map quotemeta, sort keys %DPARSE).')';
$DPARSE_RE = qr/\G(.*?)$DCODE_RE$DPARSE_RE/s;
push @{$DPARSE{$_}}, qr/\G(.*?)$DCODE_RE$DPARSE{$_}[0]/s for keys %DPARSE;
sub doxy_main {
  my ($lastpos, @p) = 0;
  while ($_[0] =~ m/$DPARSE_RE/g) {
    push @p, $1;
    my $found = $2;
    die "Unmatched pair for '$found'" if !($_[0] =~ m/$DPARSE{$found}[1]/g);
    my $contained = $1;
    push @p, [$found, $contained];
    $lastpos = pos $_[0]
  }
  push @p, substr $_[0], $lastpos;
  \@p;
}

sub doxyparse {
  my ($text) = @_;
  my %r;
  doxy_bits($text, [qw(brief short)], \%r, 'brief');
  doxy_bits($text, [qw(param)], \%r, 'params');
  doxy_bits($text, [qw(return returns)], \%r, 'return');
  doxy_bits($text, [qw(sa see)], \%r, 'see');
  $r{main} = doxy_main($text);
  \%r;
}

our %DHANDLE = (
  code => sub {
    my $text = "\n\n";
    for (@_) {
      (my $t = $_) =~ s/^/ /mg;
      $text .= $t;
    }
    $text . "\n\n";
  },
  'f$' => sub {
    'C<<< ' . join('', @_) . ' >>>'
  },
);
sub doxy2pdlpod {
  my ($r) = @_;
  my $text = '';
  $text .= qq{=for ref\n\n@{[join "\n", @{$r->{brief}}]}\n\n} if $r->{brief};
  for my $c (@{$r->{main}}) {
    if (ref $c) {
      $text .= $DHANDLE{$c->[0]}->($c->[1]);
    } else {
      $text .= md2pod($c);
    }
  }
  if (my $p = $r->{params}) {
    $text .= qq{\n\nParameters:\n\n=over\n\n};
    for (@$p) {
      do { require Test::More; confess(Test::More::explain($r)); } unless
        (my $rest = $_) =~ s#^\s*((?:\[[^\]]*\]\s*)?\w+):*\s+##;
      my $name = $1;
      $text .= "=item $name\n\n$rest\n\n";
    }
    $text .= qq{\n\n=back\n\n};
  }
  if (my $p = $r->{return}) {
    for (@$p) {
      $text .= "\n\nReturns: $_\n\n";
    }
  }
  $text .= qq{See also:\n@{[join "\n", @{$r->{see}}]}\n\n} if $r->{see};
  $text;
}

sub md2pod {
  my ($text) = @_;
  my $out = '';
  while ($text =~ s/(.*?:)\n(- .*?)(\n{2,}|\z)//s) {
    my ($before, $items, $rest) = ($1, $2, $3);
    $out .= "$before\n\n=over\n\n";
    my @items = $items =~ m/^-\s*(.*?)(?=\n-|\z)/mg;
    $out .= "=item *\n\n$_\n\n" for @items;
    $out .= "=back\n\n$rest";
  }
  $out = $out . $text;
  $out =~ s/\\\*/*/g; # very very basic
  $out =~ s/^\s*//gm;
  $out;
}

if (!caller) {
  my @l = do './Videoio/funclist.pl';
  die if $@; die $! if $!;
  my ($d) = grep $_->[1] eq 'get', @l;
  my $r = doxyparse($d->[2]);
require Test::More; print "RUN ", Test::More::explain($r);
  print "POD:\n", doxy2pdlpod($r);
}

1;
