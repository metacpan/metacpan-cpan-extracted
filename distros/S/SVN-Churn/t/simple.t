#!perl
use strict;
use SVN::Churn;
use Test::More tests => 4;

my $db = 'churn.db';
my $churn = SVN::Churn->new(
    path => 'http://opensource.fotango.com/svn/trunk/SVN-Churn/',
    #path => 'http://svn.work.fotango.com/svn/trunk/',
    database  => $db,
   );
isa_ok( $churn, 'SVN::Churn' );
$churn->update;

my $rev = $churn->revisions->[1];
is( $rev->{revision}, 1665, "got the second revision" );
is( $rev->{lines_added}, 107, "saw the right number of lines" );
$churn->graph( "churn.png" );
$churn->save;
undef $churn;

$churn = SVN::Churn->load( $db );
isa_ok( $churn, 'SVN::Churn' );
$churn->update;
$churn->save;
