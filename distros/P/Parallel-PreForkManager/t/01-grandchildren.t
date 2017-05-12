#!/usr/bin/perl
#!/usr/bin/perl -T

use strict;
use warnings;
use Parallel::PreForkManager;
use English;

use Test::More;

use List::Util;

plan tests => 1;

my $Worker = Parallel::PreForkManager->new({
    'ChildHandler'   => \&WorkHandler,
    'ParentCallback' => \&CallbackHandler,
    'ChildCount'     => 10,
    'JobsPerChild'    => 10,
});

$Worker->{ '_Results' } = [];

for ( my $i=0;$i<10;$i++ ) {
    $Worker->AddJob({ 'Value' => $i });
}

$Worker->RunJobs();

my @Results = sort @{ $Worker->{ '_Results' } };
my @Expected = (
    'SubWorkHandler:0.0',
    'SubWorkHandler:0.1',
    'SubWorkHandler:0.2',
    'SubWorkHandler:0.3',
    'SubWorkHandler:0.4',
    'SubWorkHandler:0.5',
    'SubWorkHandler:0.6',
    'SubWorkHandler:0.7',
    'SubWorkHandler:0.8',
    'SubWorkHandler:0.9',
    'SubWorkHandler:1.10',
    'SubWorkHandler:1.11',
    'SubWorkHandler:1.12',
    'SubWorkHandler:1.13',
    'SubWorkHandler:1.14',
    'SubWorkHandler:1.15',
    'SubWorkHandler:1.16',
    'SubWorkHandler:1.17',
    'SubWorkHandler:1.18',
    'SubWorkHandler:1.19',
    'SubWorkHandler:2.20',
    'SubWorkHandler:2.21',
    'SubWorkHandler:2.22',
    'SubWorkHandler:2.23',
    'SubWorkHandler:2.24',
    'SubWorkHandler:2.25',
    'SubWorkHandler:2.26',
    'SubWorkHandler:2.27',
    'SubWorkHandler:2.28',
    'SubWorkHandler:2.29',
    'SubWorkHandler:3.30',
    'SubWorkHandler:3.31',
    'SubWorkHandler:3.32',
    'SubWorkHandler:3.33',
    'SubWorkHandler:3.34',
    'SubWorkHandler:3.35',
    'SubWorkHandler:3.36',
    'SubWorkHandler:3.37',
    'SubWorkHandler:3.38',
    'SubWorkHandler:3.39',
    'SubWorkHandler:4.40',
    'SubWorkHandler:4.41',
    'SubWorkHandler:4.42',
    'SubWorkHandler:4.43',
    'SubWorkHandler:4.44',
    'SubWorkHandler:4.45',
    'SubWorkHandler:4.46',
    'SubWorkHandler:4.47',
    'SubWorkHandler:4.48',
    'SubWorkHandler:4.49',
    'SubWorkHandler:5.50',
    'SubWorkHandler:5.51',
    'SubWorkHandler:5.52',
    'SubWorkHandler:5.53',
    'SubWorkHandler:5.54',
    'SubWorkHandler:5.55',
    'SubWorkHandler:5.56',
    'SubWorkHandler:5.57',
    'SubWorkHandler:5.58',
    'SubWorkHandler:5.59',
    'SubWorkHandler:6.60',
    'SubWorkHandler:6.61',
    'SubWorkHandler:6.62',
    'SubWorkHandler:6.63',
    'SubWorkHandler:6.64',
    'SubWorkHandler:6.65',
    'SubWorkHandler:6.66',
    'SubWorkHandler:6.67',
    'SubWorkHandler:6.68',
    'SubWorkHandler:6.69',
    'SubWorkHandler:7.70',
    'SubWorkHandler:7.71',
    'SubWorkHandler:7.72',
    'SubWorkHandler:7.73',
    'SubWorkHandler:7.74',
    'SubWorkHandler:7.75',
    'SubWorkHandler:7.76',
    'SubWorkHandler:7.77',
    'SubWorkHandler:7.78',
    'SubWorkHandler:7.79',
    'SubWorkHandler:8.80',
    'SubWorkHandler:8.81',
    'SubWorkHandler:8.82',
    'SubWorkHandler:8.83',
    'SubWorkHandler:8.84',
    'SubWorkHandler:8.85',
    'SubWorkHandler:8.86',
    'SubWorkHandler:8.87',
    'SubWorkHandler:8.88',
    'SubWorkHandler:8.89',
    'SubWorkHandler:9.90',
    'SubWorkHandler:9.91',
    'SubWorkHandler:9.92',
    'SubWorkHandler:9.93',
    'SubWorkHandler:9.94',
    'SubWorkHandler:9.95',
    'SubWorkHandler:9.96',
    'SubWorkHandler:9.97',
    'SubWorkHandler:9.98',
    'SubWorkHandler:9.99',
    'WorkHandler:0',
    'WorkHandler:1',
    'WorkHandler:2',
    'WorkHandler:3',
    'WorkHandler:4',
    'WorkHandler:5',
    'WorkHandler:6',
    'WorkHandler:7',
    'WorkHandler:8',
    'WorkHandler:9'
);

is_deeply( \@Results, \@Expected, 'Grandchildren Data correct' );

sub WorkHandler {
    my ( $Self, $Thing ) = @_;
    my $Val = $Thing->{'Value'};

    my $Worker2 = Parallel::PreForkManager->new({
        'ChildHandler'   => \&SubWorkHandler,
        'ParentCallback' => \&SubCallbackHandler,
        'ChildCount'     => 10,
        'JobsPerChild'    => 10,
    });

    $Worker2->{ '_Results' } = [];

    $Worker2->{ 'Val' } = $Val;

    my $Start = $Val * 10;

    for ( my $i=$Start;$i<($Start+10);$i++ ) {
        $Worker2->AddJob({ 'Value' => $i });
    }

    $Worker2->RunJobs();

    push @{ $Worker2->{ '_Results' } }, "WorkHandler:$Val";
    return $Worker2->{ '_Results' };
}

sub SubWorkHandler {
    my ( $Self, $Thing ) = @_;
    my $Val = $Thing->{'Value'};
    my $Val2 = $Self->{ 'Val' };
    return "SubWorkHandler:$Val2.$Val";
}

sub CallbackHandler {
    my ( $Self, $Foo ) = @_;
    my @Results = ( @{ $Self->{ '_Results' } }, @$Foo );
    $Self->{ '_Results' } = \@Results;
    return;
}

sub SubCallbackHandler {
    my ( $Self, $Foo ) = @_;
    push @{ $Self->{ '_Results' } } , $Foo;
    return;
}

