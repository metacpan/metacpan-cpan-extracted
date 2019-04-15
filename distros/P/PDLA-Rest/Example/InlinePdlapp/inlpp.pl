use blib;
use PDLA; # this must be called before (!) 'use Inline Pdlapp' calls
use Inline Pdlapp; # the actual code is in the __Pdlapp__ block below

$a = sequence 10;
print $a->inc,"\n";
print $a->inc->dummy(1,10)->tcumul,"\n";

__DATA__

__Pdlapp__

# a rather silly increment function
pp_def('inc',
       Pars => 'i();[o] o()',
       Code => '$o() = $i() + 1;',
      );

# a cumulative product
# essentially the same functionality that is
# already implemented by prodover
# in the base distribution
pp_def('tcumul',
       Pars => 'in(n); float+ [o] mul()',
       Code => '$mul() = 1;
                loop(n) %{
                  $mul() *= $in();
                %}',
);
