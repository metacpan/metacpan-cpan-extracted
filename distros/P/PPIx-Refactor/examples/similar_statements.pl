#!/usr/bin/env perl
use warnings;
use strict;
use PPIx::Refactor;

=head2 sumilar_statements.pl

Simple demonstration of how to examine the syntax tree for a group of statements
in the scope of a specific subroutine for purposes of analysis of a
particular chunk of code.

=cut

# You could use the PPI::Document->find method here instead, but it has a
# slightly different interface for the coderef.
my $pxr1 = PPIx::Refactor->new(file => 'lib/SomePackage.pm',
                               ppi_find => sub {
                                   my ($elem, $doc) = @_;
                                   return 0 unless $elem->class eq 'PPI::Statement::Sub';
                                   return 0 unless $elem->first_token->snext_sibling eq 'my_method';
                                   return 1;
                               },);

my $sub_finds = $pxr1->finds;
die "Found more than one method of the same name " unless @$sub_finds == 1;


my $sub = $sub_finds->[0];
my $pxr2 = $pxr1->new(element => $sub,
                      ppi_find => sub {
                          my ($elem, $doc) = @_;
                          return 1 if $elem->class eq 'PPI::Statement';
                          return 0;
                      });
my $found = $pxr2->finds;

# Find the ppi element tree for the code construct of interest in this case the second PPI::Statement found
my $candidate = join ' ', map { $_->class } grep { $_->significant} $found->[1]->tokens;

# Now gather up all matching constructs
my (@hit, @miss);
foreach my $statement (@$found) {
    my $syntax = join " ", map {$_->class } grep { $_->significant} $statement->tokens;
    if ($syntax eq $candidate) {
        push @hit, $statement;
    }
    else {
        push @miss, $statement;
    }
}

# This finds 4 hits and 6 misses
print "Found " . scalar(@hit) . " hits, and " . scalar(@miss) . " misses\n";
print "Now hit your debug tools and see if the hits and misses are accurate, and work out what to do next\n";
