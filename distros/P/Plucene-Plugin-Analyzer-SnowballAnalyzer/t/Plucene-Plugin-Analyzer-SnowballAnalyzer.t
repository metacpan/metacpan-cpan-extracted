use strict;
use Test::More tests => 3;
use IO::Scalar;

BEGIN {
	use_ok('Plucene::Plugin::Analyzer::SnowballAnalyzer')
};

my @tests = (
	[ "tester cet environnement en français", [qw(test cet environ franc)], 'fr'],
	[ "testing the analyzer", [qw(test analyz)], 'en'],
);

my $a = Plucene::Plugin::Analyzer::SnowballAnalyzer->new;
for (@tests) {
	my ($input, $output, $lang) = @$_;
	$Plucene::Plugin::Analyzer::SnowballAnalyzer::LANG = $lang;
	my $stream = $a->tokenstream({
		field  => "dummy",
		reader => IO::Scalar->new(\$input) });
	my @data;
	push @data, $_->text while $_ = $stream->next;
	is_deeply(\@data, $output, "Analyzed $input");
}
