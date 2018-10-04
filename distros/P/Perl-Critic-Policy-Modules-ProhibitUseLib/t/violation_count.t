use strict;
use warnings;

use Test::More;
use Perl::Critic;
use Path::Tiny;

subtest 'check violation count' => sub {

    my $critic = Perl::Critic->new(
        '-profile'       => '',
        '-single-policy' => 'Modules::ProhibitUseLib'
    );

    my $violation_count = {
        'module.pm'  => 4,
        'program.pl' => 0
    };

    my $dir = path('t')->child('data');
    for my $file ( sort keys %$violation_count ) {
        my $f          = $dir->child($file)->stringify;
        my @violations = $critic->critique($f);
        my $expected   = $violation_count->{$file};
        my $got        = scalar @violations;

        is $got, $expected, 'number of violations';
    }
};

done_testing;
