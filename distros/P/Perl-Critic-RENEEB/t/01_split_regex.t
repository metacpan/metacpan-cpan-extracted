#!perl

use strict;
use warnings;

use Perl::Critic;
use Test::More;

use Data::Dumper;
use File::Basename;
use File::Spec;

use Perl::Critic::Utils qw{ :severities };
use Perl::Critic::Policy::RegularExpressions::RequireExtendedFormattingExceptForSplit;

use constant POLICY =>
    'Perl::Critic::Policy::RegularExpressions::RequireExtendedFormattingExceptForSplit';

my %modules = (
    'Module::WithSplit'     => 0,
    'Module::SimpleRegex'   => 4,
    'Module::ShortRegex'    => [ 'minimum_regex_length_to_complain_about=12', 2 ],
    'Module::ShortRegexOk'  => [ 'minimum_regex_length_to_complain_about=35', 1 ],
);

diag 'Testing *::RequireExtendedFormattingExceptForSplit version ' . POLICY->VERSION();

is_deeply [ POLICY->default_themes ], [qw/reneeb/];

my @parameters = POLICY->supported_parameters();
is_deeply
    [ map{ $_->{name} }@parameters ],
    [qw/minimum_regex_length_to_complain_about/],
    'Parameters';

is POLICY->default_severity, $SEVERITY_MEDIUM, 'Check default severity';

is_deeply
    [ POLICY->applies_to ],
    [ map{ "PPI::Token::$_" }qw/Regexp::Match Regexp::Substitute QuoteLike::Regexp/ ],
    'Check node names this policy applies to';

my $dir = dirname __FILE__;

for my $module ( sort keys %modules ) {
    #diag $module;
    my $pc = Perl::Critic->new( -only => 1 );

    my @parts = split /::/, $module;
    $parts[-1] .= '.pm';

    my $path = File::Spec->catfile(
        $dir,
        @parts,
    );

    my $expected_nr_violations = $modules{$module};
    if ( ref $expected_nr_violations ) {
        my ($param, $result)    = @{ $expected_nr_violations || [] };
        $expected_nr_violations = $result;
        my ($name, $value)      = split /=/, $param;

        $pc->add_policy( -policy => POLICY, -params => { $name => defined $value ? $value : 1 } ); 
    }
    else {
        $pc->add_policy( -policy => POLICY );
    }

    my @violations = $pc->critique( $path );

    is scalar @violations, $expected_nr_violations, "Check $module";
    #diag Dumper( \@violations );
}

done_testing();
