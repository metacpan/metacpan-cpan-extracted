## Control false discovery rate in multiple test

### install

```
cpan -i Statistics::Multtest
```

### usage

```perl
use Statistics::Multtest qw(bonferroni holm hommel hochberg BH BY qvalue);
use Statistics::Multtest qw(:all);
use strict;
 
my $p;
# p-values can be stored in an array by reference
$p = [0.01, 0.02, 0.05,0.41,0.16,0.51];
# @$res has the same order as @$p
my $res = BH($p);
print join "\n", @$res;
 
# p-values can also be stored in a hash by reference
$p = {"a" => 0.01,
      "b" => 0.02,
      "c" => 0.05,
      "d" => 0.41,
      "e" => 0.16,
      "f" => 0.51 };
# $res is also a hash reference which is the same as $p
$res = holm($p);
foreach (sort {$res->{a} <=> $res->{$b}} keys %$res) {
    print "$_ => $res->{$_}\n";
}
 
# since qvalue does not always run successfully,
# it should be embeded in 'eval'
$res = eval 'qvalue($p)';
if($@) {
    print $@;
}
else {
    print join "\n", @$res;
}
```

### description

For statistical test, p-value is the probability of false positives. While there are many hypothesis for testing simultaneously, the probability of getting at least one false positive would be large. Therefore the origin p-values should be adjusted to decrease the false discovery rate.

Seven procedures to controlling false positive rates is provided. The names of the methods are derived from `p.adjust` in `stat` package and `qvalue` in `qvalue` package (http://www.bioconductor.org/packages/release/bioc/html/qvalue.html) in R. Code is translated directly from R to Perl using `List::Vectorize` module.

All seven subroutines receive one argument which can either be an array reference or a hash reference, and return the adjusted p-values in corresponding data structure. The order of items in the array does not change after the adjustment.

### subroutines

- `bonferroni($pvalue)`

  Bonferroni single-step process.

- `hommel($pvalue)`

  Hommel singlewise process.

  Hommel, G. (1988). A stagewise rejective multiple test procedure based on a modified Bonferroni test. Biometrika, 75, 383¨C386.

- `holm($pvalue)`

  Holm step-down process.

  Holm, S. (1979). A simple sequentially rejective multiple test procedure. Scandinavian Journal of Statistics, 6, 65¨C70.

- `hochberg($pvalue)`
  
  Hochberg step-up process.

  Hochberg, Y. (1988). A sharper Bonferroni procedure for multiple tests of significance. Biometrika, 75, 800¨C803.

- `BH($pvalue)`
  
  Benjamini and Hochberg, controlling the FDR.

  Benjamini, Y., and Hochberg, Y. (1995). Controlling the false discovery rate: a practical and powerful approach to multiple testing. Journal of the Royal Statistical Society Series B, 57, 289¨C300.

- `BY($pvalue)`
  
  Use Benjamini and Yekutieli.

  Benjamini, Y., and Yekutieli, D. (2001). The control of the false discovery rate in multiple testing under dependency. Annals of Statistics 29, 1165¨C1188.

- `qvalue($pvalue, %setup)`

  Storey and Tibshirani.

  Storey JD and Tibshirani R. (2003) Statistical significance for genome-wide experiments. Proceedings of the National Academy of Sciences, 100: 9440-9445.

The default method for estimating `pi0` in the origin `qvalue` package is to utilize cubic spline interpolation. However, there is no suitable perl module to do such work (external libraries should be installed if using `Math::GSL::Spline` and there seems to be some mistakes when I using `Math::Spline`). Therefore, in this module, we only provide 'bootstrap' method to estimate `pi0`, which is also the second `pi0` method in `qvalue` package. Some arguments which are the same in `qvalue` package can be set in `%setup` as follows.

```perl
lambda => multiply(seq(0, 90, 5), # The value of the tuning parameter
                   0.01),         # to estimate pi_0. Must be in [0,1).
                                  # It should be an array reference
robust => 0, # An indicator of whether it is desired to make the estimate 
             # more robust for small p-values and a direct finite sample
             # estimate of pFDR
```

For details, please see the Storey (2003) and the qvalue document in R.

NOTE: The results of this subroutine are not always exactly consistent to the `qvalue` package due to the floating point number calculation.

In some circumstance, the estimated `pi0 <= 0`, and the subroutine would throw an error. (try p-value list: `[0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]`). So you should embeded this subroutine in 'eval' such as:

```perl
my $qvalue;
eval '$qvalue = qvalue($pvalue, %setup)';
if($@) {
  # do something
}
else {
    print join ", ", @$qvalue;
}
```
