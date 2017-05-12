#!/usr/bin/env perl
use strict;
use warnings;
use Parse::Taxonomy::MaterializedPath;

=head1 NAME

examples/walk_tree.pl - Display mapping between IDs, parent IDs and materialized paths.

=head2 USAGE

    perl examples/walk_tree.pl

=head2 DESCRIPTION

This is a simple program which, given the Perl data structures needed to use
the C<components> interface to build a F<Parse::Taxonomy::MaterializedPath>
object, prints to STDOUT a mapping among the C<id>, C<parent_id> in the object
and the materialized path in the input.

=head2 AUTHOR

Contributed by Ron Savage.

=cut

# ------------------------------------

sub walk_tree
{
	my($got)   = @_;
	my($paths) = [];

	my($id);
	my($path);

	for my $i (0 .. $#$got)
	{
		$id   = $i;
		$path = [];

		push @$path, $$got[$id]{name};

		while ($id = $$got[$id]{parent_id})
		{
			$id--;

			push @$path, $$got[$id]{name};
		}

		push @$paths, join('|', reverse @$path);
	}

	return $paths;

} # End of walk_tree.

# ------------------------------------

my(@input_columns) = (qw/path letter_vendor_id is_actionable/);
my(@data)          =
(
  ["|alpha", 1, 0],				#  1
  ["|alpha|able", 1, 0],		#  2
  ["|alpha|able|Agnes", 1, 1],	#  3
  ["|alpha|able|Agnew", 1, 1],	#  4
  ["|alpha|baker", 1, 0],		#  5
  ["|alpha|baker|Agnes", 1, 1],	#  6
  ["|alpha|baker|Agnew", 1, 1],	#  7
  ["|beta", 1, 0],				#  8
  ["|beta|able", 1, 0],			#  9
  ["|beta|able|Agnes", 1, 1],	# 10
  ["|beta|able|Agnew", 1, 1],	# 11
  ["|beta|baker", 1, 0],		# 12
  ["|beta|baker|Agnes", 1, 1],	# 13
  ["|beta|baker|Agnew", 1, 1],	# 14
);
my($tax) = Parse::Taxonomy::MaterializedPath -> new
({
	components =>
	{
		fields       => \@input_columns,
		data_records => \@data,
	}
});
my($adjacent) = $tax -> adjacentify();
my($paths)    = walk_tree($adjacent);

print "Parent ID\tID\tFull path\n";

for my $i (0 .. $#$adjacent)
{
	print sprintf
	(
		"%9s\t%2s\t%s\n",
		$$adjacent[$i]{parent_id} || '-',
		$$adjacent[$i]{id},
		$$paths[$i],
	);
}
