#!/usr/bin/perl

use Test::More tests => 6;
use Pod::From::GoogleWiki;

my $wiki = '_italic_ *bold* `code` ^super^script ,,sub,,script ~~strikeout~~';

my $pod = 'I<italic> B<bold> C<code> (super)script (sub)script C<--strikeout-->';

my $pfg = Pod::From::GoogleWiki->new();
my $ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'b/i OK');

$wiki = '_*bold* in italics_ *_italics_ in bold* *~~strike~~ works too* ~~as well as _this_ way round~~';
$pod = 'I<B<bold> in italics> B<I<italics> in bold> B<C<--strike--> works too> C<--as well as I<this> way round-->';
$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'mm b/i OK');

$wiki = <<'WIKI';
{{{
def fib(n):
  if n == 0 or n == 1:
    return n
  else:
    # This recursion is not good for large numbers.
    return fib(n-1) + fib(n-2)
}}}
WIKI
$pod = <<'POD';

  def fib(n):
    if n == 0 or n == 1:
      return n
    else:
      # This recursion is not good for large numbers.
      return fib(n-1) + fib(n-2)

POD
$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'code OK');

$wiki = <<'WIKI';
line 1

line 2
line 3

line 4
WIKI
$pod = <<'POD';
line 1

line 2
line 3

line 4
POD
$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'header OK');

$wiki = <<'WIKI';
= Heading =
== Subheading ==
=== Level 3 ===
==== Level 4 ====
===== Level 5 =====
====== Level 6 ======
WIKI
$pod = <<'POD';

=head1 Heading

=head2 Subheading

=head3 Level 3

=head4 Level 4

=head5 Level 5

=head6 Level 6
POD
$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'header OK');

$wiki = <<'WIKI';
|| *Year* || *Temperature (low)* || *Temperature (high)* ||
|| 1900 || -10 || 25 ||
|| 1910 || -15 || 30 ||
|| 1920 || -10 || 32 ||
|| 1930 || _N/A_ || _N/A_ ||
|| 1940 || -2 || 40 ||

WIKI
$pod = <<'POD';
.----------+----------------------+------------------------.
|  B<Year> | B<Temperature (low)> | B<Temperature (high)>  |
+----------+----------------------+------------------------+
|  1900    | -10                  | 25                     |
|  1910    | -15                  | 30                     |
|  1920    | -10                  | 32                     |
|  1930    | I<N/A>               | I<N/A>                 |
|  1940    | -2                   | 40                     |
'----------+----------------------+------------------------'
POD
$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'table OK');