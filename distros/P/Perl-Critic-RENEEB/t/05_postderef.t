#!perl

use strict;
use warnings;

use Perl::Critic;
use Perl::Critic::Utils qw{ :severities };
use Test::More;

use Data::Dumper;
use File::Basename;
use File::Spec;

use constant POLICY => 'Perl::Critic::Policy::Reneeb::RequirePostderef';

diag 'Testing ' . POLICY() . ' version ' . POLICY->VERSION();

is_deeply [ POLICY->default_themes ], [qw/reneeb/];

is POLICY->default_severity, $SEVERITY_MEDIUM, 'Check default severity';

is_deeply
    [ POLICY->applies_to ], 
    [ "PPI::Token::Cast" ],
    'Check node names this policy applies to';


my $pc = Perl::Critic->new( -'single-policy' => POLICY );

while ( my $line = <DATA> ) {
    my ($code, $expected) = split /\s{6,}/, $line;

    my @violations = $pc->critique( \$code );
    #diag Dumper( \@violations );

    is scalar @violations, $expected + 0, "Check $code";
}

done_testing();

__DATA__
my @list   = grep { ausdruck() } @{$liste};        1
my $list   = grep { ausdruck() } @liste;           0
for ( $ref->@* ) {}                                0
for ( @{ $ref } ) {}                               1
for ( @$ref ) {}                                   1
@{ $ref };                                         1
@{ $ref->[0] };                                    1
@$ref;                                             1
%$ref;                                             1
%{ $ref };                                         1
%ref;                                              0
$ref->@*;                                          0
$ref->%*;                                          0
*{ $ref };                                         1
$ref->**                                           0
&{ $ref }                                          1
&$ref                                              1
$ref->&*                                           0
my $nr = $#{$ref};                                 1
my $nr = $ref->$#;                                 0
my @a  = @{$re}{@keys};                            1
my @a  = $re->@{@keys};                            0
