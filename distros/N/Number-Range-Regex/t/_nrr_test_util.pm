#!perl -w
$|++;

use strict;

use Test::More;

#usage: check_type($range, type_str, is_infinite, is_empty);
# type should be one of 'Compound', 'Simple', or 'Trivial'
#   note: other checks will fill in, for example, if you check
#   for 'Trivial', we will also check Simple and !Compound
# if you don't care what type, e.g. check_type($r, undef, 0, 1);
sub check_type {
  my ($range, $type, $infinite, $empty) = @_;
  my $ret = 1;
  my $got;

  $got = $range->is_infinite() ? 1 : 0;
  if(defined $infinite && $infinite != $got) {
    warn "check_type: inifiniteness: expected $infinite, got: $got";
    $ret = 0;
  }
  $got = $range->is_empty() ? 1 : 0;
  if(defined $empty && $empty != $got) {
    warn "check_type: emptiness: expected $empty, got: $got";
    $ret = 0;
  }

  my %types;
  $type = defined $type ? $type : ''; #dont warn about undef
  if($type eq 'Compound') {
    @types{qw(Compound Simple Trivial)} = (1, 0, 0);
  } elsif($type eq 'Trivial') {
    @types{qw(Compound Simple Trivial)} = (0, 1, 1);
  } elsif($type eq 'Simple') {
    @types{qw(Compound Simple Trivial)} = (0, 1, 0);
  }

  if ( ! $range->isa( 'Number::Range::Regex::Range' ) ) {
    warn "check_type: isa(Range): expected 1, got: 0";
  }
  foreach my $key (keys %types) {
    my $type = $key;
    $got = $range->isa("Number::Range::Regex::${type}Range") ? 1 : 0;
    if ( $got != $types{$key} ) {
      warn "check_type: isa($type): expected $types{$key}, got: $got";
      $ret = 0;
    }
  }
  return $ret;
}

sub strip_regex_bloat {
  my $str = (@_);
  # depending on the version of perl, we may get one or more
  # (?-xism: ... ) wrappers around the regex
  while($str =~ /^\(\?\-xism\:/) {
    $str = substr($str, 8, -1)
  }
  return $str;
}

sub test_rangeobj_exhaustive {
  my ($tr) = @_;
  my $regex = $tr->regex();
  die "cannot exhaustively test infinite/compound ranges"  if  !defined $tr->{min} or !defined $tr->{max};
  return  if  ($tr->{min}-1) =~ /^$regex$/;
  for(my $c=$tr->{min}; $c<=$tr->{max}; ++$c) {
    if("$c" !~ /^$regex$/) {
      warn "failed (exhaustive) test tr($tr->{min}, $tr->{max}, $tr->regex}) - failed $c =~ /^$regex$/\n";
      return;
    }
  }
  return  if  ($tr->{max}+1) =~ /^$regex$/;
  return $tr;
}

sub test_range_random {
  my($min, $max, $trials, $verbose, $opts) = @_;
  die "cannot randomly test infinite/compound ranges"  if  !defined $min or !defined $max;
  my $range = regex_range($min, $max);
  return  unless  $range;
  my $spread = $max - $min;
  my $test_start_min = $min - int( $spread / 2 );
  $test_start_min = 0  if  $test_start_min < 0;
  my @tests;
  return  if  ($min-1) =~ /^$range$/;
  return  if  $min !~ /^$range$/;
  for(my $trial=0; $trial<$trials; $trial++) {
    my $c = $test_start_min + int rand $spread * 2;
    push @tests, $c  if  $verbose;
    my $desired = ($c >= $min) && ($c <= $max);
    my $actual  = "$c" =~ /^$range$/;
    unless( ($desired and $actual) or (!$desired && !$actual) ) {
      warn "failed (random) test $c =~ /^$range$/\n";
      return;
    }
  }
  return  if  $max !~ /^$range$/;
  return  if  ($max+1) =~ /^$range$/;
  warn "\ninfo (***safe to ignore***): range $range seems to have worked for [$min..$max] in $trials trials (/***safe to ignore***)\n"  if  $verbose;
#  warn "\ninfo (***safe to ignore***): range $range seems to have worked for [$min..$max] in $trials trials. tested: ".join(", ", sort @tests)." (/***safe to ignore***)\n"  if  $verbose;
  return $range;
}

sub test_range_partial {
  my $opts = ref($_[-1]) eq 'HASH' ? pop @_ : {};
  my($min, $max, @tranges) = @_;
  my $range = regex_range($min, $max);
  return  unless  $range;
  return  if  defined $min && ($min-1) =~ /^$range$/;
  return  if  defined $min && $min !~ /^$range$/;
  foreach my $test (@tranges) {
    my ($tmin, $tmax) = ($test->[0], $test->[1]);
    for(my $c=$tmin; $c<=$tmax; ++$c) {
      my $desired = 1;
      $desired = $desired && ($c >= $min)  if  defined $min;
      $desired = $desired && ($c <= $max)  if  defined $max;
      my $actual  = "$c" =~ /^$range$/;
      unless( ($desired and $actual) or (!$desired && !$actual) ) {
        warn "failed (partial range) test $c =~ /^$range$/, min: $min, max: $max\n";
        return;
      }
    }
  }
  return  if  defined $max && $max !~ /^$range$/;
  return  if  defined $max && ($max+1) =~ /^$range$/;
  return $range;
}

sub test_range_exhaustive {
  my($min, $max, $opts) = @_;
  die "cannot exhaustively test infinite/compound ranges"  if  !defined $min or !defined $max;
  my $range = regex_range($min, $max);
  return  unless  $range;
  return  if  ($min-1) =~ /^$range$/;
  for(my $c=$min; $c<=$max; ++$c) {
    if("$c" !~ /^$range$/) {
      warn "failed (exhaustive) test $c =~ /^$range$/, min: $min, max: $max\n";
      return;
    }
  }
  return  if  ($max+1) =~ /^$range$/;
  return $range;
}

sub test_all_ranges_exhaustively {
  my ($min_min, $max_max) = @_;
  for my $start ($min_min..$max_max) {
    for my $end ($start..$max_max) {
      my $range = test_range_exhaustive( $start, $end );
      return unless $range;
    }
  }
  return 1;
}

sub test_range_regex {
  my($min, $max, $regex, $opts) = @_;
  die "cannot test infinite/compound ranges"  if  !defined $min or !defined $max;
  return  unless  $regex;
  return  if  ($min-1) =~ /^$regex$/;
  for(my $c=$min; $c<=$max; ++$c) {
    if("$c" !~ /^$regex$/) {
      warn "failed (range_regex) test $c =~ /^$regex$/, min: $min, max: $max\n";
      return;
    }
  }
  return  if  ($max+1) =~ /^$regex$/;
  return $regex;
}

## if we have perl > 5.8 we can temporarily reopen STDERR to a var,
## use this function to do checks on stderr output. with perl <=
## 5.8.0, we have no way to check stderr, so we just check the
## return value, dump to stderr and hope for the best


#sub ok_local_stderr(&$) { #ok_l_s { ... } qr/.../
sub ok_local_stderr { # ok_l_s sub { ... }, qr/.../
  my ($sub, $err_re) = @_;
  my $ret;
  if($^V gt v5.8.0) {
    my $err = '';
    local *STDERR;
    open(STDERR, '>', \$err) or die "open: $!";
    $ret = $sub->();
    close STDERR;
    ok( $ret && $err =~ /$err_re/ );
  } else {
    diag "please ignore the following warning!";
    $ret = $sub->();
    ok( $ret );
  }
  return $ret;
}

1;

