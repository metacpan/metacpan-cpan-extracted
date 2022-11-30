#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

# 加载扩展模块
use PDK::Utils::OpenSwitchPort qw/parseExcel openCiscoPort portManager writePortConfig/;

my $data = parseExcel('/home/careline/Codes/perl/PDK/mojo.xls');
my $conf = openCiscoPort($data->[0]);
my $sample = portManager('/home/careline/Codes/perl/PDK/mojo.xls');

use DDP;
# p $data;
p $conf;
p $sample;

writePortConfig('/home/careline/Codes/perl/PDK/mojo.xls');

done_testing();

