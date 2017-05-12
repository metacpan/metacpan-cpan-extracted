# Devel::Cover invokes the bool operator on the RHS of $overload::ops{assign} operators,
# which confounds PDL. e.g.
#   $mask //= $some_pdl
# turns into $mask //= bool $some_pdl
# and PDL's bool overload croaks

{
  package PDL;
  eval 'use overload bool => sub { return $_[0] };'
    if $INC{'Devel/Cover.pm'};
}

1;
