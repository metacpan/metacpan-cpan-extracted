use strict;
use warnings;
use File::Spec;
use Test::More;

if ( not $ENV{TEST_AUTHOR} and not $ENV{TEST_ALL} ) {
    my $msg = 'set TEST_AUTHOR or TEST_ALL to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Metrics::Simple; };

if ($@) {
    my $msg = 'Test::Perl::Metrics::Simple required to criticise code';
    plan( skip_all => $msg );
}

Test::Perl::Metrics::Simple->import( -complexity => 30 );
all_metrics_ok();
