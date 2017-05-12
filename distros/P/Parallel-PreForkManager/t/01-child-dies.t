
#!/usr/bin/perl -T

use strict;
use warnings;
use Parallel::PreForkManager;
use English;

use Test::More;
use Test::Exception;

plan tests => 1;

my $Errored = 0;
my @Results;

my $Worker = Parallel::PreForkManager->new({
    'ChildHandler'   => sub{
        my ( $Self, $Job ) = @_;
        my $Val = $Job->{ 'Value' };
        die() if $Val > 10;
    },
    'ParentCallback' => sub{
        my ( $Self, $Thing ) = @_;
        my $Result = $Self->GetResult();
        if ( exists( $Result->{ 'Error' } ) ) {
            $Errored++;
        }
    },
});

for ( my $i=0;$i<20;$i++ ) {
    $Worker->AddJob({ 'Value' => $i });
}

$Worker->RunJobs();

is( $Errored, 9, 'Child exception handling' );

