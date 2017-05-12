use strict;
use warnings;

use Test::More tests => 108;

sub begins_with
{
    my ($got, $exp) = @_;
    my $ok = substr($got,0,length $exp) eq $exp;
    if (!$ok)
    {
        diag "expected '$exp...'\n",
             "     got '$got'\n";
    }
    return $ok;
}

use Regexp::Common 'time';

# Time zone tests

# These should all succeed:
for my $in (qw(Z UT UTC GMT EST EDT CST CDT MST MDT PST PDT
               +0000 -0000 +00:00 -00:00 +00 -00
               +0100 -0200 +03:00 -04:00 +05 -06
               +1100 -1200 +13:00 -22:00 +23 -24
               +0130 -0230 +03:45 -04:17 +05:59 +0659
              ))
{
    my @out = $in =~ /\A$RE{time}{tf}{-pat => 'tz'}{-keep}\z/;
    is_deeply (\@out, [$in, $in], qq{TF '$in' should succeed});

    @out = $in =~ /\A$RE{time}{strftime}{-pat => '%Z'}{-keep}\z/;
    is_deeply (\@out, [$in], qq{stftime '$in' should succeed});
}

# These should all fail:
for my $in (qw(X EJR QQT ABC RST
               +2500 -2500 +25:00 -25:00 +25 -25
               0100 02:00 03
               +1160 -1270 +13:80 -22:80
              ))
{
    my @out = $in =~ /\A$RE{time}{tf}{-pat => 'tz'}{-keep}\z/;
    is_deeply (\@out, [], qq{TF '$in should fail'});

    @out = $in =~ /\A$RE{time}{strftime}{-pat => '%Z'}{-keep}\z/;
    is_deeply (\@out, [], qq{strftime '$in' should fail});
}
