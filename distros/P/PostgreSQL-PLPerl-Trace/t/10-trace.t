use Test::More tests => 3;

my $fh;
my $trace_output;

BEGIN {
	open($fh, '>', \$trace_output) or die $!;
	$PostgreSQL::PLPerl::Trace::fh    = $fh;
	$PostgreSQL::PLPerl::Trace::TRACE = 0;
}

use PostgreSQL::PLPerl::Trace;
require Safe;

ok my $safe = Safe->new('PLPerl');
$safe->deny_only();

$PostgreSQL::PLPerl::Trace::TRACE = 1;
$safe->reval("42424242") or die $@;
$PostgreSQL::PLPerl::Trace::TRACE = 0;

ok $trace_output;
print $trace_output;

my @lines = split /\n/, $trace_output;

# >> (eval 9)[(eval 8)[/Users/timbo/pg/perl5101/lib/site_perl/5.11.5/Safe.pm:25]:1]:1: my $__ExPr__;42424242
my @matched = grep { /eval .* eval .* Safe.pm .* 42424242/x } @lines;

ok @matched, 'some lines should match';

