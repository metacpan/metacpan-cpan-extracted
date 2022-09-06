use strict;
use warnings;

package Mojo::DOM::Role::Style;

# ABSTRACT: Adds a style method to Mojo::DOM

use Mojo::Base -role;
use Want;
use List::Util qw/uniq/;

use Mojo::Util qw/dumper/;

sub style {
    my $self = shift;

    my $css = $self->attr('style');

    my ($h, $k) = _from_css($css);

    if (scalar @_ == 1 && ! ref $_[0] && defined $_[0]) {
	return $h->{shift()}
    }
    elsif (scalar @_ == 1 && ! defined $_[0]) {
	delete $self->attr->{'style'};
    }
    elsif ((scalar @_ % 2) == 0 && (scalar @_)) {
	my $m = { @_ };
	$css = _to_css($m, []);
	$self->attr('style', $css);
    }
    elsif (ref $_[0] eq 'HASH') {
	for (keys %{$_[0]}) { $h->{$_} = $_[0]->{$_} }
	$css = _to_css($h, $k);
	$self->attr('style', $css);
    }


    if (want('OBJECT')) {
	return $self;
    } elsif (want('HASH')) {
	return $h;
    } else {
	return $css;
    }
}



# my $query = $url->query;
# $url      = $url->query({merge => 'to'});
# $url      = $url->query([append => 'with']);
# $url      = $url->query(replace => 'with');
# $url      = $url->query('a=1&b=2');
# $url      = $url->query(Mojo::Parameters->new);

sub _to_css {
    my $h = shift;
    my $k = shift || [];

    $k = [ uniq (@$k, keys %$h) ];

    my $css = join ';', map { join ':', $_, $h->{$_} } @$k;
    return $css
}

sub _from_css {
    my $css = shift;
    unless ($css) { return wantarray ? ({}, []) : {} }

    my $k = [ map { /^(.+?)\s*:/; $1 } split /\s*;\s*/, $css ];
    my $h = { map { split /\s*:\s*/, $_, 2 } split /\s*;\s*/, $css };

    return wantarray ? ($h, $k) : $h
}

1;
