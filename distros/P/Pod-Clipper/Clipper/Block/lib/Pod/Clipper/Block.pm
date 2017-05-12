package Pod::Clipper::Block;
use Moose;

BEGIN {
    our $VERSION = '0.01';
}

has 'data' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'is_pod' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
);

=head1 NAME

Pod::Clipper::Block - A block of POD or non-POD data

=head1 SYNOPSIS

  use Pod::Clipper::Block;
  my $block = Pod::Clipper::Block->new({ data => $data, is_pod => 1 });

=head1 DESCRIPTION

This module has very limited use on its own. It's mainly used as a helper
for C<Pod::Clipper>. Each C<Pod::Clipper::Block> object stores a block of
text along with a flag about whether the stored text is POD or non-POD data.
Both of these parameters have to be provided when you construct the object.
There's nothing preventing you from providing conflicting parameters, e.g.
C<data> can be non-POD yet you set C<is_pod> to true or vice versa (not sure
why you would want to do that, though).

=head1 METHODS

=head2 new

This is the C<Pod::Clipper::Block> constructor. It expects a hash reference
with two mandatory options: C<data> and C<is_pod>.

=head2 data

Returns the block of data stored in the object. You can also use it to set
new data.

  print $block->data;
  $block->data($new_data);

=head2 is_pod

Returns a boolean value describing the type of the data in your block.
1 => POD, 0 => non-POD. B<C<Pod::Clipper::Block> does not check your
data for whether it's POD or non-POD>. It simply returns whatever you've
set the C<is_pod> option to (via the constructor or this method).

  print "POD!" if $block->is_pod;
  $block->is_pod(0); # assign it a new value 

=head1 BUGS

There are no known bugs. If you find one, please report it to me at the
email address listed below. Any other suggestions or comments are also
welcome.

=head1 AUTHOR

Yousef H. Alhashemi <yha@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Pod::Clipper|Pod::Clipper>

=cut

1; # leave this here!
