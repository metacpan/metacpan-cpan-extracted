# -*- Mode: CPerl -*-
# File: t/common.plt
# Description: re-usable test subs; requires Test::More
BEGIN { $| = 1; }

# isok($label,@_) -- prints helpful label
sub isok {
  my $label = shift;
  if (@_==1) {
    ok($_[0],$label);
  } elsif (@_==2) {
    is($_[0],$_[1], $label);
  } else {
    die("isok(): expected 1 or 2 non-label arguments, but got ", scalar(@_));
  }
}

# skipok($label,$skip_if_true,@_) -- prints helpful label
# skipok($label,$skip_if_true,\&CODE) -- prints helpful label
sub skipok {
  my ($label,$skip_if_true) = splice(@_,0,2);
  if ($skip_if_true) {
    subtest $label => sub { plan skip_all => $skip_if_true; };
  } else {
    if (@_==1 && ref($_[0]) && ref($_[0]) eq 'CODE') {
      isok($label, $_[0]->());
    } else {
      isok($label,@_);
    }
  }
}

# skipordo($label,$skip_if_true,sub { ok ... },@args_for_sub)
sub skipordo {
  my ($label,$skip_if_true) = splice(@_,0,2);
  if ($skip_if_true) {
    subtest $label => sub { plan skip_all => $skip_if_true; };
  } else {
    $_[0]->(@_[1..$#_]);
  }
}

# ulistok($label,\@got,\@expect)
# --> ok() for unsorted lists
sub ulistok {
  my ($label,$l1,$l2) = @_;
  is_deeply([sort @$l1],[sort @$l2],$label);
}

# matchpdl($a,$b) : returns pdl identity check, including BAD
sub matchpdl {
  my ($a,$b) = map {PDL->topdl($_)->setnantobad} @_[0,1];
  return ($a==$b)->setbadtoval(0) | ($a->isbad & $b->isbad) | ($a->isfinite->not & $b->isfinite->not);
}
# matchpdl($a,$b,$eps) : returns pdl approximation check, including BAD
sub matchpdla {
  my ($a,$b) = map {$_->setnantobad} @_[0,1];
  my $eps = $_[2];
  $eps    = 1e-5 if (!defined($eps));
  return $a->approx($b,$eps)->setbadtoval(0) | ($a->isbad & $b->isbad) | ($a->isfinite->not & $b->isfinite->not);
}

# cmp_dims($got_pdl,$expect_pdl)
sub cmp_dims {
  my ($p1,$p2) = @_;
  return $p1->ndims==$p2->ndims && all(pdl(PDL::long(),[$p1->dims])==pdl(PDL::long(),[$p2->dims]));
}

# pdlok($label, $got, $want)
sub pdlok {
  my ($label,$got,$want) = @_;
  $got  = PDL->topdl($got) if (defined($got));
  $want = PDL->topdl($want) if (defined($want));
  isok($label,
       defined($got) && defined($want)
       && cmp_dims($got,$want)
       && all(matchpdl($want,$got)));
}

# pdlok_nodims($label, $got, $want)
#  + ignores dimensions
sub pdlok_nodims {
  my ($label,$got,$want) = @_;
  $got  = PDL->topdl($got) if (defined($got));
  $want = PDL->topdl($want) if (defined($want));
  isok($label,
       defined($got) && defined($want)
       #&& cmp_dims($got,$want)
       && all(matchpdl($want,$got)));
}

# pdlapprox($label, $got, $want, $eps=1e-5)
sub pdlapprox {
  my ($label,$got,$want,$eps) = @_;
  $got  = PDL->topdl($got) if (defined($got));
  $want = PDL->topdl($want) if (defined($want));
  $eps  = 1e-5 if (!defined($eps));
  isok($label,
       defined($got) && defined($want)
       && cmp_dims($got,$want)
       && all(matchpdla($want,$got,$eps)));
}


print "loaded ", __FILE__, "\n";

1;

