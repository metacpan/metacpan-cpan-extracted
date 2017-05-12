# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Recall.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;

use lib '../blib/lib';
use Template::Recall;


# Text
my $tstr;
for (<DATA>) { $tstr .= $_ }
my $tr = Template::Recall->new( template_str => $tstr );
my $h = { filename => $0 };
my $s = $tr->render('main', $h );
ok( $s ne '' and $s !~ /filename/, "From __DATA__ section:\n$s" );





__DATA__
[=main=]
Hi. I live in the __DATA__ section of the file --

This file name is: ['filename']

