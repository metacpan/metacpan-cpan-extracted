#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 8;

use POSIX::1003::Pathconf qw(fpathconf %pathconf _PC_LINK_MAX);
use POSIX::1003::FdIO     qw(openfd closefd);
use Fcntl                 qw(O_RDONLY);

my $fd = openfd __FILE__, O_RDONLY
    or die $!;

my $max  = fpathconf($fd, '_PC_LINK_MAX');
ok(defined $max, "_PC_LINK_MAX via function = $max");

my $max3 = _PC_LINK_MAX($fd);
ok(defined $max3, "_PC_LINK_MAX directly = $max3");
cmp_ok($max, '==', $max3);

closefd $fd;

use POSIX::1003::Pathconf qw(pathconf %pathconf _PC_LINK_MAX);

my $max4 = pathconf(__FILE__, '_PC_LINK_MAX');
ok(defined $max4, "_PC_LINK_MAX via function = $max4");

my $max6 = _PC_LINK_MAX(__FILE__);
ok(defined $max6, "_PC_LINK_MAX directly = $max6");
cmp_ok($max4, '==', $max3);


use POSIX::1003::Pathconf qw(pathconf_names);
my @names = pathconf_names;
# I expect at least a few names
cmp_ok(scalar @names, '>', 5, @names." names");

my $undefd = 0;
foreach my $name (sort @names)
{   my $val = pathconf(__FILE__, $name);
    printf " %3d  %-24s %s\n", $pathconf{$name}, $name
      , (defined $val ? $val : 'undef');
    defined $val or $undefd++;
}
ok(1, "$undefd return undef for __FILE__");
