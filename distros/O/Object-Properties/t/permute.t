use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Object::Properties ();

my @order;
my %field = map { my $n = $_; $n, sub { push @order, $n } } qw( foo bar baz ); # quux veeble xyzzy

# c.f. perldoc -q permute
sub permute (&@) {
	my $code = shift;
	my @idx = 0 .. $#_;
	while () {
		$code->( @_[@idx] );
		my $p = $#idx;
		--$p while $idx[$p-1] > $idx[$p];
		my $q = $p or return;
		push @idx, reverse splice @idx, $p;
		++$q while $idx[$p-1] > $idx[$q];
		@idx[$p-1,$q]=@idx[$q,$p-1];
	}
}

# exhaustive test that the promise of declaration-ordered prop init holds
# (for x fields this runs x!^2 tests...)

my %seen;
permute {
	my $declared = "@_";
	return if $seen{ $declared }++;

	# quell redef warnings:
	no warnings 'once';
	local ( *PROPINIT, *foo, *bar, *baz, *quux, *veeble, *xyzzy );

	Object::Properties->import( map {; $_, $field{$_} } @_ );

	permute {
		return if $seen{ "$declared @_" }++;
		@order = ();
		__PACKAGE__->new( map {; $_, $field{$_} } @_ );
		is "@order", $declared, "@_ => $declared";
	} sort @_;
} sort keys %field;

done_testing;
