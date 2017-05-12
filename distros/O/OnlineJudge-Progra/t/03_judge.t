use strict;
use warnings;
use 5.008;

use Test::More tests => 5;
use OnlineJudge::Progra;
use OnlineJudge::Progra::Test;
use Cwd;

my $j 		= OnlineJudge::Progra->new();
my $get 	= sub { &OnlineJudge::Progra::Test::get;    };
my $update 	= sub { &OnlineJudge::Progra::Test::update; };
my $path 	= getcwd;

$j->load_badwords($path.'/t/03_judgebw.txt');
$j->set_logging(0);

my @r = $get->();

my $foo = $j->process_request( $r[0] );
my $bar = $update->($foo);
ok( $bar eq 'AC', 'accepted' );

$foo = $j->process_request( $r[1] );
$bar = $update->($foo);
ok( $bar eq 'CE', 'compilation error' );

$foo = $j->process_request( $r[2] );
$bar = $update->($foo);
ok( $bar eq 'TL', 'time limit' );

$foo = $j->process_request( $r[3] );
$bar = $update->($foo);
ok( $bar eq 'WA', 'wrong answer' );

$foo = $j->process_request( $r[4] );
$bar = $update->($foo);
ok( $bar =~ m'^BW', 'badword found' );
