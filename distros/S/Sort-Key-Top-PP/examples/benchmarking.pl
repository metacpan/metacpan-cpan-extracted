use v5.10;
use strict;
use warnings;
use Test::More;
use Benchmark qw(cmpthese);

use Sort::Key::Top 'rnkeytopsort';
use Sort::Key::Top::PP 'rnkeytopsort' => { -as => 'rnkeytopsort_pp' };

# Naive pure Perl implementation of rnkeytopsort
sub rnkeytopsort_naive (&$@) {
	my ($code, $n, @list) = @_;
	my @sorted =
		map  { $_->[1] }
		sort { $b->[0] <=> $a->[0] }
		map  { [ $code->($_), $_ ] } @_;
	return @sorted[ 0 .. $n-1 ];
}

my @list;
open my $fh, '<', '/usr/share/dict/words';
while (<$fh>) {
	chomp;
	push @list, $_;
	last if @list >= 50_000;
}
say "# Word count: @{[ scalar @list ]}";

my @xs    = rnkeytopsort       { length($_) } 50 => @list;
my @pp    = rnkeytopsort_pp    { length($_) } 50 => @list;
my @naive = rnkeytopsort_naive { length($_) } 50 => @list;

is_deeply(\@xs, \@naive);
is_deeply(\@pp, \@naive);
is_deeply(\@pp, \@xs);
done_testing;

# Make Benchmark output into TAP comments...
use IO::Callback; SELECT: {
	select(
		IO::Callback->new('>', sub {
			my $in = shift;
			$in =~ s/^/# /m;
			print STDOUT $in;
		})
	);
};

for my $N (qw< 5 50 500 >)
{
	say "Benchmarking rnkeytopsort for top $N";
	cmpthese(50, {
		xs    => sub { rnkeytopsort       { length($_) } $N, @list },
		pp    => sub { rnkeytopsort_pp    { length($_) } $N, @list },
		naive => sub { rnkeytopsort_naive { length($_) } $N, @list },
	});
	say q();
}