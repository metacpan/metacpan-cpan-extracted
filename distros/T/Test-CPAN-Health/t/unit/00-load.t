use strict;
use warnings;

use Test::More;

my @modules = qw(
	Params::Validate::Strict
	Test::CPAN::Health
	Test::CPAN::Health::Cache
	Test::CPAN::Health::Check
	Test::CPAN::Health::Config
	Test::CPAN::Health::Distribution
	Test::CPAN::Health::Report
	Test::CPAN::Health::Reporter::HTML
	Test::CPAN::Health::Reporter::JSON
	Test::CPAN::Health::Reporter::Markdown
	Test::CPAN::Health::Reporter::TAP
	Test::CPAN::Health::Reporter::Terminal
	Test::CPAN::Health::Result
	Test::CPAN::Health::Runner
	Test::CPAN::Health::Check::AbandonedDeps
	Test::CPAN::Health::Check::Benchmarks
	Test::CPAN::Health::Check::Changelog
	Test::CPAN::Health::Check::CIConfig
	Test::CPAN::Health::Check::Complexity
	Test::CPAN::Health::Check::CPANTesters
	Test::CPAN::Health::Check::DeclaredDeps
	Test::CPAN::Health::Check::Deprecations
	Test::CPAN::Health::Check::DocQuality
	Test::CPAN::Health::Check::DuplicateCode
	Test::CPAN::Health::Check::Examples
	Test::CPAN::Health::Check::Kwalitee
	Test::CPAN::Health::Check::License
	Test::CPAN::Health::Check::MetaJSON
	Test::CPAN::Health::Check::MinPerl
	Test::CPAN::Health::Check::Perlcritic
	Test::CPAN::Health::Check::PODCoverage
	Test::CPAN::Health::Check::ReadmeSync
	Test::CPAN::Health::Check::ReverseDeps
	Test::CPAN::Health::Check::SecurityAdvisories
	Test::CPAN::Health::Check::SemVer
	Test::CPAN::Health::Check::StaleDeps
	Test::CPAN::Health::Check::TestCoverage
	Test::CPAN::Health::Check::VersionSync
);

plan tests => scalar @modules;

use_ok($_) for @modules;
