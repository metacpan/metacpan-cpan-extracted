#!/usr/bin/env perl
use warnings;
use strict;
use FindBin '$Bin';
use Template;
use Test::Differences;
use Test::More tests => 1;
my $template = <<EOTMPL;
[%
    FILTER null;
        USE c = GoogleChart;
        chart = c.new_chart(type => 'Pie');
        chart.pie_type('3d');
        chart.size('300x300');
        chart.data([ 10, 30, 50, 70, 90 ]);
    END;
    chart.as_uri;
%]
EOTMPL
my $tt = Template->new(INCLUDE_PATH => "$Bin/../lib",);
my $result;
$tt->process(\$template, {}, \$result) || die $tt->error();
1 while chomp $result;
eq_or_diff $result,
'http://chart.apis.google.com/chart?cht=p&chs=300x300&chd=t%3A10.0%2C30.0%2C50.0%2C70.0%2C90.0',
  'basic diagram';
