use strict;
use warnings;

package Mojo::DOM::Role::Style::Value;

# use Scalar::Util qw/blessed/;

use overload
    '""'   => sub { ${$_[0]}[0] },
    '%{}'  => sub { ${$_[0]}[1] },
    fallback => 1;

sub new {
    my ($class, $css, $hash) = @_;
    return bless [$css, $hash], $class;
}

package Mojo::DOM::Role::Style;

# ABSTRACT: Adds a style method to Mojo::DOM

use Mojo::Base -role;
use List::Util qw/uniq/;

sub style {
    my $self = shift;

    my $css     = $self->attr('style') // '';
    my ($h, $k) = _from_css($css);

    # Getter - no args
    return Mojo::DOM::Role::Style::Value->new($css, $h) unless @_;

    # Single string arg - get one property value
    if (@_ == 1 && !ref $_[0] && defined $_[0] && $_[0] !~ /:/) {
        return $h->{$_[0]};
    }

    if (@_ == 1 && !ref $_[0] && defined $_[0] && $_[0] =~ /:/) {
        $self->attr(style => $_[0]);
        return $self
    }

    # Undef - remove style attribute entirely
    if (@_ == 1 && !defined $_[0]) {
        $self->attr({style => undef});
        return $self;
    }

    # Hashref - merge into existing style
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        $h->{$_} = $_[0]->{$_} for keys %{$_[0]};
        my $new = _to_css($h, $k);
        $self->attr(style => $new);
        # return Mojo::DOM::Role::Style::Value->new($new, $h);
	return $self
    }

    # Flat list - replace entire style
    if (@_ % 2 == 0) {
        my @keys = do { my %seen; grep { !$seen{$_}++ } @_[ grep { !($_ % 2) } 0 .. $#_ ] };
        my $new  = _to_css({@_}, \@keys);
        $self->attr(style => $new);
        # return Mojo::DOM::Role::Style::Value->new($new, {@_});
	return $self;
    }
}

sub _to_css {
    my ($h, $k) = @_;
    $k = [ uniq(@$k, keys %$h) ];
    return join ';', map { $_ . ':' . $h->{$_} } @$k;
}

sub __from_css {
    my $css = shift;
    return ({}, []) unless $css;

    my $k = [ map { /^([^:]+?)\s*:/; $1 } split /\s*;\s*/, $css ];
    my $h = { map { split /\s*:\s*/, $_, 2 } split /\s*;\s*/, $css };

    return ($h, $k);
}

sub _from_css {
    my $css = shift;
    return ({}, []) unless $css;

    my @declarations = split /\s*;\s*(?![^(]*\))/, $css;

    my $k = [ map { /^([^:]+?)\s*:/; $1 } @declarations ];
    my $h = { map { split /\s*:\s*/, $_, 2 } @declarations };

    return ($h, $k);
}

1;

=encoding utf8

=head1 NAME

Mojo::DOM::Role::Style - Manage inline CSS styles on Mojo::DOM elements

=head1 SYNOPSIS

  use Mojo::DOM;

  my $dom = Mojo::DOM->new('<div style="color:red;font-size:12pt">hello</div>')
    ->with_roles('+Style');

  # Get the full style - stringifies to the CSS string
  my $style = $dom->at('div')->style;
  say $style;                    # "color:red;font-size:12pt"
  say $style->{'color'};         # "red"

  # Get a single property
  my $color = $dom->at('div')->style('color');

  # Replace with a raw CSS string
  $dom->at('div')->style('color:blue;font-size:14pt');

  # Replace with a flat list
  $dom->at('div')->style(color => 'blue', 'font-size' => '14pt');

  # Merge into the existing style
  $dom->at('div')->style({'font-weight' => 'bold'});

  # Remove the style attribute entirely
  $dom->at('div')->style(undef);

=head1 DESCRIPTION

L<Mojo::DOM::Role::Style> is a role that adds a convenience method for
reading and manipulating the C<style> attribute of L<Mojo::DOM> elements.

=head1 RETURN VALUE

Getter calls with no arguments return a L<Mojo::DOM::Role::Style::Value>
object. This object stringifies to the CSS attribute string, and can be
dereferenced as a hash to access individual properties.

  my $style = $dom->at('div')->style;
  say $style;                # "color:red;font-size:12pt"
  say $style->{'color'};     # "red"

Single-property getter calls return a plain string. All setter calls return
the element itself for chaining.

=head1 METHODS

L<Mojo::DOM::Role::Style> implements the following methods.

=head2 style

  my $style = $dom->at('div')->style;
  my $val   = $dom->at('div')->style('color');
  $dom      = $dom->at('div')->style('color:red;font-size:12pt');
  $dom      = $dom->at('div')->style(color => 'red', 'font-size' => '12pt');
  $dom      = $dom->at('div')->style({'font-weight' => 'bold'});
  $dom      = $dom->at('div')->style(undef);

Get or set the inline style of this element.

With no arguments, returns a L<Mojo::DOM::Role::Style::Value> representing
the current style.

  # "red"
  my $style = $dom->at('p')->style;
  say $style->{'color'};

With a single string argument that is a property name, returns the value of
that CSS property, or C<undef> if it is not set.

  # "red"
  $dom->at('p')->style('color');

With a single string argument that is a raw CSS declaration string, replaces
the entire inline style and returns the element for chaining.

  # <p style="color:red;font-size:12pt">hi</p>
  $dom->at('p')->style('color:red;font-size:12pt');

With an even-length flat list, replaces the entire inline style with the
given property-value pairs. Key order is preserved as supplied. Returns the
element for chaining.

  # <p style="color:blue;font-size:14pt">hi</p>
  $dom->at('p')->style(color => 'blue', 'font-size' => '14pt');

With a hash reference, merges the given properties into the existing style,
adding new properties and overwriting existing ones. Returns the element for
chaining.

  # <p style="color:red;font-weight:bold">hi</p>
  $dom->at('p')->style({'font-weight' => 'bold'});

With C<undef>, removes the C<style> attribute entirely and returns the
element for chaining.

  # <p>hi</p>
  $dom->at('p')->style(undef)->attr('id', 'intro');

=head1 SEE ALSO

L<Mojo::DOM>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021 Simone Cesano.

This is free software, you may use it and distribute it under the same terms
as Perl itself.

=head1 AUTHOR

Simone Cesano

=cut
