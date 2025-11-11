 #!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;
 
use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node);

# This test is just to validate that the example provided at the start of the
# Pod::Abstract documentation actually works!

# Get all the first level headings, and put them in a verbatim block
# at the start of the document
my $pa = Pod::Abstract->load_file('lib/Pod/Abstract.pm');
my @headings = $pa->select('/head1@heading');
my @headings_text = map { $_->pod } @headings;
my $headings_node = node->verbatim(join "\n",@headings_text);

$pa->unshift( node->cut );
$pa->unshift( $headings_node );
$pa->unshift( node->pod );

my $expect = q{=pod

 NAME
 SYNOPSIS
 DESCRIPTION
 COMPONENTS
 METHODS
 AUTHOR
 COPYRIGHT AND LICENSE

=cut};

my $pod = $pa->pod;

ok(index($pod, $expect) >= 0, "Found expected heading summary in generated POD");

1;