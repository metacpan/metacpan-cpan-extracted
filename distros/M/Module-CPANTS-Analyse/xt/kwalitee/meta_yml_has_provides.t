use strict;
use warnings;
use xt::kwalitee::Test;

xt::kwalitee::Test::run(
  ['TOBYINK/Platform-Windows-0.002.tar.gz', 0], # 2206
  ['TOBYINK/Platform-Unix-0.002.tar.gz', 0], # 2264
  ['COOLMEN/Test-More-Color-0.04.tar.gz', 0], # 2963
  ['COOLMEN/Test-Mojo-More-0.04.tar.gz', 0], # 4301
  ['SMUELLER/Math-SymbolicX-Complex-1.01.tar.gz', 0], # 4719
  ['CHENRYN/Nagios-Plugin-ByGmond-0.01.tar.gz', 0], # 5159
  ['SMUELLER/Math-Symbolic-Custom-CCompiler-1.03.tar.gz', 0], # 5244
  ['LTP/Game-Life-0.05.tar.gz', 0], # 6535
);
