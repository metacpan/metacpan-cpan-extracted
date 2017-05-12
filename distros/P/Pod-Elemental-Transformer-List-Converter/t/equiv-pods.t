
# The logic in this file is essentally stolen from a file of the same name in
# Pod::Elemental::Transformer::List.  Thanks! :)

package X;
use strict;
use warnings;

# HOW TO READ THESE TESTS:
#   All the list_id tests get a big string; it's two parts, divided by a ------
#   line.  The first half is what you write.  The second part is what it's
#   transformed to before publishing.

use Test::More 'no_plan';
use Test::Differences;

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::List::Converter;

my $pod5 = Pod::Elemental::Transformer::Pod5->new;
my $list = Pod::Elemental::Transformer::List::Converter->new;

sub list_is {
  my ($comment, $string) = @_;
  my ($input, $want) = split /^-{10,}$/m, $string;
  $want =~ s/\A\n//; # stupid

  $input = "=pod\n\n$input";
  $want  = "=pod\n\n$want\n=cut\n";
  my $doc = Pod::Elemental->read_string($input);
  $pod5->transform_node($doc);
  $list->transform_node($doc);
  eq_or_diff($doc->as_pod_string, $want, $comment);
}

list_is simple_list => <<'END_POD';
=over 4

=item foo

=item bar

=item baz

=back
--------------------------------------
=head2 foo

=head2 bar

=head2 baz
END_POD

list_is bullet => <<'END_POD';
=over 4

=item * foo

=item * bar

=item * baz

=back
--------------------------------------
=head2 foo

=head2 bar

=head2 baz
END_POD

list_is bullet_and_following_para => <<'END_POD';
=over 4

=item * foo

Hi there!

=item * bar

Bip!

=item * baz

=back
--------------------------------------
=head2 foo

Hi there!

=head2 bar

Bip!

=head2 baz
END_POD

#my $list = Pod::Elemental::Transformer::List::Converter->new->;
$list->command('head3');

list_is simple_list_to_head3_not_head2 => <<'END_POD';
=over 4

=item foo

=item bar

=item baz

=back
--------------------------------------
=head3 foo

=head3 bar

=head3 baz
END_POD
