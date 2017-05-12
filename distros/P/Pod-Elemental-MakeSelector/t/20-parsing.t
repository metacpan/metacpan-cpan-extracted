#! /usr/local/bin/perl
#---------------------------------------------------------------------
# Copyright 2015 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test Pod::Elemental::MakeSelector on a parsed document
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

use Test::More 0.88;            # done_testing
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;

use Pod::Elemental::MakeSelector;

# Either plan tests or output actual results
my $generateResults;
if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  eval 'require Data::Dump;' or die; # hide from AutoPrereqs
  open(OUT, '>', '/tmp/20-parsing.t') or die $!;
  printf OUT "#%s\n# Tests begin here:\n", '=' x 69;
} else {
  plan tests => 21;
}

# Parse our sample document and extract its elements
my $document = Pod::Elemental->read_handle(*DATA);
Pod::Elemental::Transformer::Pod5->new->transform_node($document);

my @elements;

sub list_elements {
  for my $e (@_) {
    push @elements, $e;
    list_elements(@{$e->children}) if $e->does('Pod::Elemental::Node');
  }
}
list_elements($document);

#---------------------------------------------------------------------
# Perform one test
#
# Usage: test($test_name, @criteria, $expected_results)

sub test
{
  my $name     = shift;
  my $expected = pop;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $selector = make_selector(@_);

  my $got = join("--\n", map { $_->as_pod_string }
                         grep { $selector->($_) } @elements);

  if ($generateResults) {
    print OUT "\ntest('$name',\n";
    my $nl = 1;
    for (@_) {
      if (ref or not /^-/) {
        print OUT " " . Data::Dump::pp($_) . ",\n";
        $nl = 1;
      } else {
        print OUT "\n" unless $nl;
        print OUT "  $_ =>";
        $nl = 0;
      }
    }
    print OUT "\n" unless $nl;
    print OUT "  <<'END TEST $name');\n${got}END TEST $name\n";
  } else {
    is($got, $expected, $name);
  }
} # end test

#=====================================================================
# Tests begin here:

test('author',
  -command => "head1",
  -content => "AUTHOR",
  <<'END TEST author');
=head1 AUTHOR

END TEST author

test('authorRE',
  -command => "head1",
  -content => qr/^AUTHOR/,
  <<'END TEST authorRE');
=head1 AUTHOR

--
=head1 AUTHORS

--
=head1 AUTHORS AND CREDITS

END TEST authorRE

test('authorsOnly',
  -command => "head1",
  -content => "AUTHORS",
  <<'END TEST authorsOnly');
=head1 AUTHORS

END TEST authorsOnly

test('authorOrAuthors',
  -command => "head1",
  -or => ["-content", "AUTHOR", "-content", "AUTHORS"],
  <<'END TEST authorOrAuthors');
=head1 AUTHOR

--
=head1 AUTHORS

END TEST authorOrAuthors

test('contradiction',
  -command => "head1",
  -content => "AUTHOR",
  -content => "AUTHORS",
  <<'END TEST contradiction');
END TEST contradiction

test('multiOr',
  -or => [
  "-and",
  [
    "-command",
    "head1",
    "-or",
    ["-content", "AUTHOR", "-content", "AUTHORS"],
  ],
  "-and",
  ["-flat", "-content", qr/Goodbye/],
],
  <<'END TEST multiOr');
=head1 AUTHOR

--
=head1 AUTHORS

--
Goodbye, all!

END TEST multiOr

test('allCommands',
  -command =>
  <<'END TEST allCommands');
=head1 AUTHOR

--
=head1 AUTHORS

--
=head1 AUTHORS AND CREDITS

--
=head1 DESCRIPTION

--
=head2 Notes

--
=head3 About

--
=for Pod::Coverage omit_this

--
=for :list * one
* two
* three

END TEST allCommands

test('head23',
  -command => ["head2", "head3"],
  <<'END TEST head23');
=head2 Notes

--
=head3 About

END TEST head23

test('head23re',
  -command => qr/^head[23]/,
  <<'END TEST head23re');
=head2 Notes

--
=head3 About

END TEST head23re

test('headNmixedArray',
  -command => ["head1", qr/^head[23]/],
  <<'END TEST headNmixedArray');
=head1 AUTHOR

--
=head1 AUTHORS

--
=head1 AUTHORS AND CREDITS

--
=head1 DESCRIPTION

--
=head2 Notes

--
=head3 About

END TEST headNmixedArray

test('AmixedArray',
  -command => [qr/^head[12]/, "head3"],
  -content => qr/^A/,
  <<'END TEST AmixedArray');
=head1 AUTHOR

--
=head1 AUTHORS

--
=head1 AUTHORS AND CREDITS

--
=head3 About

END TEST AmixedArray

test('flat',
  -flat =>
  <<'END TEST flat');
=cut

=pod


--
Some text about the author.

--
Some text about the authors.

--
About authors and other credits.

--
The description.

--
Some notes.

--
About this.

--
Hello world!

--
Goodbye, all!

--
omit_this
--
* one
* two
* three

END TEST flat

test('blank',
  -blank =>
  <<'END TEST blank');
END TEST blank

test('hello',
  -flat =>
  -content => qr/Hello/,
  <<'END TEST hello');
Hello world!

END TEST hello

test('helloGoodbye',
  -flat =>
  -content => [qr/Hello/, qr/Goodbye/],
  <<'END TEST helloGoodbye');
Hello world!

--
Goodbye, all!

END TEST helloGoodbye

test('allRegions',
  -region =>
  <<'END TEST allRegions');
=for Pod::Coverage omit_this

--
=for :list * one
* two
* three

END TEST allRegions

test('listRegions',
  -region => "list",
  <<'END TEST listRegions');
=for :list * one
* two
* three

END TEST listRegions

test('podRegions',
  -podregion =>
  <<'END TEST podRegions');
=for :list * one
* two
* three

END TEST podRegions

test('podListRegions',
  -podregion => "list",
  <<'END TEST podListRegions');
=for :list * one
* two
* three

END TEST podListRegions

test('nonPodRegions',
  -nonpodregion =>
  <<'END TEST nonPodRegions');
=for Pod::Coverage omit_this

END TEST nonPodRegions

test('nullArray',
  -command => [],
  <<'END TEST nullArray');
END TEST nullArray

done_testing unless $generateResults;

print OUT "\ndone_testing unless \$generateResults;\n\n" if $generateResults;

__DATA__

=head1 AUTHOR

Some text about the author.

=head1 AUTHORS

Some text about the authors.

=head1 AUTHORS AND CREDITS

About authors and other credits.

=head1 DESCRIPTION

The description.

=head2 Notes

Some notes.

=head3 About

About this.

Hello world!

Goodbye, all!

=for Pod::Coverage
omit_this

=begin :list

* one
* two
* three

=end :list
