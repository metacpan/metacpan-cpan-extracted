=head1 NAME

Sort::TSort - topological sort; a very simple wrapper around 'tsort' command line utility.

=head1 SYNOPSIS

  use Sort::TSort qw(tsort);
  my $sorted_items = toposort($ordered_pairs);

=head1 DESCRIPTION

Sort::TSort::tsort performs a topological sort of an acyclic directed graph defined by list of edges (pairs of vertices).
Sort::TSort does this by invoking external command tsort (1). 

Exports one subroutine on demand: tsort.

If external program tsort is not installed, the subroutine dies.

If there are cycles in the graph, the subroutine dies.

If an item of input array has any other length than 2, the subroutine dies (this behaviour is different from external tsort, which accept any even number of items per row).

Sort::TSort tries to do its best to deal correctly with non-ASCII data (by encoding input strings in utf-8 and decoding result from utf-8).

=head1 EXAMPLE


  use Sort::TSort qw/tsort/;
  my $partial_order = [
    [ 'a', 'b' ],
    [ 'a', 'c' ],
    [ 'c', 'x' ],
    [ 'b', 'x' ],
    [ 'x', 'y' ],
    [ 'y', 'z' ],
  ];

  my $sorted = tsort($partial_order);

  # Result:
  # $sorted = [
  #     'a',
  #     'c',
  #     'b',
  #     'x',
  #     'y',
  #     'z'
  #   ];


  my $partial_order = [
    [ 'a', 'b' ],
    [ 'b', 'c' ],
    [ 'c', 'a' ],
  ];

  my $sorted = tsort($partial_order);

  # Result: tsort dies (there is a cycle 'a-b-c')


  my $partial_order = [
    [ 'a', 'b', 'c', 'd' ],
    [ 'b', 'c' ],
    [ 'c', 'a' ],
  ];

  my $sorted = tsort($partial_order);

  # Result: tsort dies (first row doesn't have exactly 2 items)

=head1 CAVEATS

Requires external tsort program to be installed.

Not tested on Windows (probably it can be made to work there with tsort from Perl Power Tools).

Not intended to sort very large arrays (input and output data are copied multiple times, join'ed and split'ed, which may lead to unnecessary memory consumption). 


=head1 SEE ALSO

tsort (1), tsort from PerlPowerTools, L<Sort::Topological>, L<tcsort>, L<Algorithm::TSort>

=head1 AUTHOR

Elena Bolshakova <helena@cpan.org>

=cut

use strict;
use warnings;
use utf8;

package Sort::TSort;

use base qw(Exporter);

use Encode;
use IPC::Cmd qw(can_run run_forked);

our @EXPORT_OK = qw(
    tsort
    );


sub tsort
{
    my ($arr) = @_;

    can_run('tsort') or die 'tsort is not installed, stop';

    my $data = join "\n", map { @$_ == 2 ? join " ", @$_ : die "unexpected number of elements in a row: [".join(", ", @$_)."]" } @$arr;

    my $res = run_forked( 'tsort', { child_stdin => Encode::encode_utf8($data), } );

    if ( $res->{exit_code} != 0 ){
        die "tsort exited with non-zero exit code ($res->{exit_code})\n$res->{stderr}";
    }

    my @sorted_array = split "\n", Encode::decode_utf8($res->{stdout});

    return \@sorted_array;
}


1;

