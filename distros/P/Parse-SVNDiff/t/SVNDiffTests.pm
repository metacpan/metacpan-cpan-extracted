
package SVNDiffTests;

use Test::Base -Base;

use strict;
use warnings;

our @EXPORT = qw(&parse_ok &apply_is &dump_is);

sub parse_ok {
    my $diff = $self;
    my $raw = shift;
    isa_ok(
       $diff->parse($raw),
       "Parse::SVNDiff",
       "new parse from ".shift
      );
}

sub apply_is {
    my $diff = $self;
    my $source = shift;
    my $dest = shift;
is(
    $diff->apply($source),
    $dest,
    '->apply works - '.shift,
);
}

sub dump_is {
    my $diff = $self;
    my $raw = shift;

    my $dump = $diff->dump;
is(
    unpack('B*', $dump),
    unpack('B*', $raw),
    '->dump roundtrips - '.shift,
)
	or do {
    
    my $dumpbin = unpack('B*', $dump);
    my $rawbin = unpack('B*', $raw);

    my $state = 0;
    my $offset = 0;
    diag("lengths - dumped = ".length($dump).", input = ".length($raw));
    diag(sprintf("offset  dumped    input"));
    while (length $dumpbin or length $rawbin) {
	my $left = substr $dumpbin, 0, 8, "";
	my $right = substr $rawbin, 0, 8, "";
       	if ($left ne $right) {
	    diag(sprintf(" %.4x  %8s  %8s", $offset, $left, $right))
	}
	$offset++;
    }

}
}

package SVNDiffTests::Filter;
use Test::Base::Filter -Base;
    use YAML;

sub from_binary {
    my $what = shift;
    join '', map pack('B*', $_), map /([01]{8})/g, $what;
}

sub trim {
    my $what = shift;
    chomp $what;
    return $what;
}
