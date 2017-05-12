# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Recall.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

use lib '../blib/lib';
use Template::Recall;


# Text
my $tstr;
for (<DATA>) { $tstr .= $_ }
my $tr = Template::Recall->new( template_str => $tstr );
$tr->trim(); # Trim all
my $s = $tr->render('sec_hello', { hello => 'helo' } );
$s .= $tr->render('sec_world', { world => 'wrld' } );

ok( length($s) == 8, "Trim both: [$s]" );

$tr->trim('l');
$s = $tr->render('sec_hello', { hello => 'helo' } );
ok( ($s =~ /\s$/ and $s !~ /^\s/), "Trim left");


$tr->trim('right');
$s = $tr->render('sec_world', { world => 'wrld' } );
ok( ($s !~ /\s$/ and $s =~ /^\s/), "Trim right");


$tr->trim('OFF');
$s = $tr->render('sec_world', { world => 'helo' } );
ok( ($s =~ /\s$/ and $s =~ /^\s/), "Trim off");



__DATA__
[===== sec_hello =====]

['hello']


[===== sec_world =====]


['world']




