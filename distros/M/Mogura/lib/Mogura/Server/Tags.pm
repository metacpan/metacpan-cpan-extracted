package Mogura::Server::Tags;
use strict;
use warnings;

sub validate {
    my ($class, $tags) = @_;

    die 'Invalid tags' unless ref($tags) eq 'ARRAY' && @$tags <= 20;
    my @normalized;
    my %seen;
    for my $value (@$tags) {
        my $tag = $value;
        die 'Invalid tag' if !defined($tag) || ref($tag) || $tag =~ /[\x00-\x1f\x7f]/;
        $tag =~ s/\A\s+|\s+\z//g;
        next unless length($tag);
        die 'Tag too long' if length($tag) > 120;
        push @normalized, $tag unless $seen{$tag}++;
    }
    return \@normalized;
}

1;
