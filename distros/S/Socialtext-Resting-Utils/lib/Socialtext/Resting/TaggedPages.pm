package Socialtext::Resting::TaggedPages;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw/tagged_pages/;

=head1 NAME

Socialtext::Resting::TaggedPages - Utilities for finding pages with tags

=head1 SYNOPSIS

  use Socialtext::Resting::TaggedPages qw/tagged_pages/;
  my $untagged_pages = tagged_pages( rester => $r, notags => 1 );
  my $foo_pages      = tagged_pages( rester => $r, tags   => ['foo'] );

=cut

our $VERSION = '0.01';

=head1 FUNCTIONS

=head2 tagged_pages

Return a list of tagged pages.  See SYNOPSIS for usage.

=cut

sub tagged_pages {
    my %opts = (
        tags => [],
        notags => undef,
        @_,
    );
    my $r = $opts{rester} or die "Rester is mandatory";

    $r->accept('perl_hash');

    my $all_pages = $r->get_pages;
    my @pages;
    for my $p (@$all_pages) {
        my $pagetags = $p->{tags} || [];
        if ($opts{notags}) {
            next if @$pagetags;
            push @pages, $p->{page_id};
        }
        else {
            my $missing_tag = 0;
            for my $t (@{ $opts{tags} }) {
                unless (grep { $_ eq $t } @$pagetags) {
                    $missing_tag++;
                }
            }
            push @pages, $p->{page_id} unless $missing_tag;
        }
    }
    return \@pages;
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
