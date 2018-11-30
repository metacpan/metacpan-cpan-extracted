#!perl

use strict;
use warnings;

use Perl::Critic;
use Perl::Critic::Utils qw{ :severities };
use Test::More;

use Data::Dumper;
use File::Basename;
use File::Spec;

my %modules = (
    'Module::WithTryTiny' => 0,
    'Module::WithEval'    => 1,
);

use constant POLICY => 'Perl::Critic::Policy::Reneeb::ProhibitBlockEval';

diag 'Testing *::ProhibitBlockEval version ' . POLICY->VERSION();

is_deeply [ POLICY->default_themes ], [qw/reneeb/];

is POLICY->default_severity, $SEVERITY_MEDIUM, 'Check default severity';

is_deeply
    [ POLICY->applies_to ], 
    [ "PPI::Statement" ],
    'Check node names this policy applies to';


my $dir = dirname __FILE__;

my $pc = Perl::Critic->new( -'single-policy' => POLICY );

for my $module ( sort keys %modules ) {
    my @parts = split /::/, $module;
    $parts[-1] .= '.pm';

    my $path = File::Spec->catfile(
        $dir,
        @parts,
    );

    my @violations = $pc->critique( $path );
    #diag Dumper( \@violations );

    is scalar @violations, $modules{$module}, "Check $module";
}

done_testing();
