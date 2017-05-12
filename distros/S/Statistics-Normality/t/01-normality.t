#!perl -T
use strict;
use warnings;
use Test::More;

use Statistics::Normality ':all';

my @data = qw/0.0987 0.0000 0.0533 -0.0026 0.0293 -0.0036 0.0246
-0.0042 0.0200 -0.0114 0.0194 -0.0139 0.0191 -0.0222 0.0180
-0.0333 0.0172 -0.0348 0.0132 -0.0363 0.0102 -0.0363 0.0084
-0.0402 0.0077 -0.0583 0.0058 -0.1184 0.0016 -0.1420/;
my ($pval, $stat) = shapiro_wilk_test (\@data);
print "SHAPIRO-WILK CASE\n";
print "   w-statistic = $stat\n";
print "   pval = $pval\n\n";
ok(abs(0.892184124933737 - $stat) < 0.000000000000001);
ok($pval == 0.0054370);

#__D'AGOSTINO K-SQUARED TEST CASE
#
#  D'Agostino et al (1990) pp 318
@data = qw/393 353 334 336 327 300 300 308 283 285 270 270 272 278 278
263 264 267 267 267 268 254 254 254 256 256 258 240 243 246
247 248 230 230 230 230 231 232 232 232 234 234 236 236 238
220 225 225 226 210 211 212 215 216 217 218 200 202 192 198
184 167/;
($pval, $stat) = dagostino_k_square_test (\@data);
print "D'AGOSTINO CASE\n";
print "   k-squared-statistic = $stat\n";
print "   pval = $pval\n";

ok(abs(14.7515066801266 - $stat) < .0000000000001);
ok($pval == 0.00062625);
