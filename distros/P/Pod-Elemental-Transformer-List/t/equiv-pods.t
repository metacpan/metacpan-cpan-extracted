#!perl
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
use Pod::Elemental::Transformer::List;

my $pod5 = Pod::Elemental::Transformer::Pod5->new;
my $list = Pod::Elemental::Transformer::List->new;

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

list_is tight_bullet_for => <<'END_POD';
=for :list
* foo
* bar
* baz
--------------------------------------
=over 4

=item *

foo

=item *

bar

=item *

baz

=back
END_POD

list_is empty_list => <<'END_POD';
=begin :list

=end :list
--------------------------------------
=over 4

=back
END_POD

list_is tight_bullet => <<'END_POD';
=begin :list

* foo
* bar
* baz

=end :list
------------------------------------
=over 4

=item *

foo

=item *

bar

=item *

baz

=back
END_POD

list_is loose_bullet => <<'END_POD';
=begin :list

* foo

* bar

* baz

=end :list
------------------------------------
=over 4

=item *

foo

=item *

bar

=item *

baz

=back
END_POD

list_is bullets_with_wrapping => <<'END_POD';
=begin :list

* foo
 continues

* bar
    continues
But this is new
* baz

=end :list
------------------------------------
=over 4

=item *

foo continues

=item *

bar continues

But this is new

=item *

baz

=back
END_POD

list_is tight_num => <<'END_POD';
=for :list
1. foo
2. bar
3. baz
------------------------------------
=over 4

=item 1

foo

=item 2

bar

=item 3

baz

=back
END_POD

list_is tight_num_repeated => <<'END_POD';
=for :list
1. foo
1. bar
1. baz
------------------------------------
=over 4

=item 1

foo

=item 2

bar

=item 3

baz

=back
END_POD

# It's important to realize that in this example, C<1. foo> makes the C<=item>
# and then a standalone "foo" paragraph.  The rest of the content until the
# next bullet becomes a single paragraph.

list_is num_with_paras => <<'END_POD';
=for :list
1. foo
Foo is an important aspect of L<Foo::Bar>.  It really is.
It's hard to explain I<just> how important.
2. bar
3. baz
Baz is also important, but compared to Foo, Baz isn't even Bar.
------------------------------------
=over 4

=item 1

foo

Foo is an important aspect of L<Foo::Bar>.  It really is.
It's hard to explain I<just> how important.

=item 2

bar

=item 3

baz

Baz is also important, but compared to Foo, Baz isn't even Bar.

=back
END_POD

list_is num_with_wrapping_and_paras => <<'END_POD';
=for :list
1. foo
 continues
Foo is an important aspect of L<Foo::Bar>.  It really is.
It's hard to explain I<just> how important.
2. bar
3. baz
Baz is also important, but compared to Foo, Baz isn't even Bar.
------------------------------------
=over 4

=item 1

foo continues

Foo is an important aspect of L<Foo::Bar>.  It really is.
It's hard to explain I<just> how important.

=item 2

bar

=item 3

baz

Baz is also important, but compared to Foo, Baz isn't even Bar.

=back
END_POD

list_is def_with_custom_indent => <<'END_POD';
=begin :list :over<6>

= TLA
Three-letter acronym.

= TBD
To be defined.

= ETC
And so on and so forth.

=end :list
------------------------------------
=over 6

=item TLA

Three-letter acronym.

=item TBD

To be defined.

=item ETC

And so on and so forth.

=back
END_POD

list_is nested_complex => <<'END_POD';
=begin :list

1. foo

Foo is an important aspect of foo.

2. bar

Bar is also important, and takes options:

=begin :list

= height

It's supplied in in pixels.

= width

It's supplied in inches.

And those are all of them.

=end :list

3. baz

Reasons why Baz is important:

=for :list
* it's delicious like L<Net::Delicious>
* it's nutritious
* it's seditious

=for :list
= bananas
Yellow with a peel.
= Banderas
Fellow with appeal.

=end :list
------------------------------------
=over 4

=item 1

foo

Foo is an important aspect of foo.

=item 2

bar

Bar is also important, and takes options:

=over 4

=item height

It's supplied in in pixels.

=item width

It's supplied in inches.

And those are all of them.

=back

=item 3

baz

Reasons why Baz is important:

=over 4

=item *

it's delicious like L<Net::Delicious>

=item *

it's nutritious

=item *

it's seditious

=back

=over 4

=item bananas

Yellow with a peel.

=item Banderas

Fellow with appeal.

=back

=back
END_POD

list_is nested_complex_with_custom_indent => <<'END_POD';
=begin :list :over<3>

1. foo

Foo is an important aspect of foo.

2. bar

Bar is also important, and takes options:

=begin :list :over<8>

= height

It's supplied in in pixels.

= width

It's supplied in inches.

And those are all of them.

=end :list

3. baz

Reasons why Baz is important:

=for :list
* it's delicious like L<Net::Delicious>
* it's nutritious
* it's seditious

=for :list
= bananas
Yellow with a peel.
= Banderas
Fellow with appeal.

=end :list
------------------------------------
=over 3

=item 1

foo

Foo is an important aspect of foo.

=item 2

bar

Bar is also important, and takes options:

=over 8

=item height

It's supplied in in pixels.

=item width

It's supplied in inches.

And those are all of them.

=back

=item 3

baz

Reasons why Baz is important:

=over 4

=item *

it's delicious like L<Net::Delicious>

=item *

it's nutritious

=item *

it's seditious

=back

=over 4

=item bananas

Yellow with a peel.

=item Banderas

Fellow with appeal.

=back

=back
END_POD
