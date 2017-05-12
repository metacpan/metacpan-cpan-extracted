use strict;
use Test::More tests => 2;
use IO::Scalar;

BEGIN {
	use_ok('Plucene::Plugin::Analyzer::MetaphoneAnalyzer')
};

my @tests = (
	[ "testing the analyzer", [qw(TSTNK 0 ANLSR)]],
);

my $a = Plucene::Plugin::Analyzer::MetaphoneAnalyzer->new;
for (@tests) {
	my ($input, $output) = @$_;
	my $stream = $a->tokenstream({
		field  => "dummy",
		reader => IO::Scalar->new(\$input) });
	my @data;
	push @data, $_->text while $_ = $stream->next;
	is_deeply(\@data, $output, "Analyzed $input");
}
