#!/usr/bin/perl -w

use strict;

=head1 NAME

line-numbers.t - Tests that Pod::Snippets numbers lines correctly

=cut

use Test::More no_plan => 1;
use Pod::Snippets;

my @lines = read_file($INC{"Pod/Snippets.pm"});
my $examples = Pod::Snippets->load($INC{"Pod/Snippets.pm"},
                                -markup => "metatests",
                                -named_snippets => "strict");

=pod

We use a POD snippet way down the B<Pod::Snippets> source code, so as
to maximize the likelihood of causing fencepost errors.

=cut

my $snippet = $examples->named("as_data multiple blocks return")
    ->as_code();

my @sniplines = split m/\n/, $snippet;
my $linemarkup = shift @sniplines;
ok((my ($line, $file) = $linemarkup =~ m/^#line (\d+) "(.*)"$/),
   "line numbering markup found at the top")
    or die "no markup line found, rest of the test is pointless";
like($file, qr/Pod.*Snippets/, "file name OK");

foreach my $offset (0..$#sniplines) {
    cmp_ok(index($lines[$line + $offset - 1], $sniplines[$offset]),
           ">=", 0, "sync OK at offset $offset");
}

=pod

Also we test the line offset feature.

=cut

my $examples_offset = Pod::Snippets->load
    ($INC{"Pod/Snippets.pm"},
     -markup => "metatests",
     -named_snippets => "strict",
     -line => 42);

@sniplines = split m/\n/,
    $examples_offset->named("as_data multiple blocks return")
    ->as_code();
ok((my ($offsetline, undef) = $sniplines[0] =~ m/^#line (\d+) "(.*)"$/),
   "line numbering markup found at the top");
is($offsetline, $line + 41, "line offset feature");

1;

=head2 read_file

Same foo as L<File::Slurp/read_file>, sans the dependency on same.

=cut

sub read_file {
    my ($path) = @_;
    local *FILE;
    open FILE, $path or die $!;
    return <FILE>;
}
