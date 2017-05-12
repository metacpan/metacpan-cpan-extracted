#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 1;
use_ok('Term::ProgressBar::Quiet');

my @todo     = ( 'x' x 10 );
my $progress = Term::ProgressBar::Quiet->new(
    { name => 'Todo', count => scalar(@todo), ETA => 'linear' } );

my $i = 0;
foreach my $todo (@todo) {

    # do something with $todo
    $progress->update( ++$i );
}
$progress->message('All done');

