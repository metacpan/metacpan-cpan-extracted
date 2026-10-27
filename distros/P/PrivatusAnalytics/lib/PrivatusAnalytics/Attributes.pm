package PrivatusAnalytics::Attributes;

use 5.020;
use strict;
use warnings;

use Carp         qw(croak);
use Exporter     qw(import);
use Scalar::Util qw(blessed);

our $VERSION = '1.0.0';

our @EXPORT_OK = qw(
  event_data event_attrs click_data click_attr valid_click_name
  html_escape to_html normalize_key normalize_props props_pairs
  is_bool string_value
);

use constant {
    MAX_NAME  => 120,
    MAX_KEY   => 64,
    MAX_PROPS => 30,
    MAX_VALUE => 500,
};

my $CLICK_NAME = qr/\A[A-Za-z0-9_.:-]{1,100}\z/;

# builtin::is_bool exists from Perl 5.36. Older Perls only have boolean objects.
my $BUILTIN_IS_BOOL = do {
    no strict 'refs';
    defined &{'builtin::is_bool'} ? \&{'builtin::is_bool'} : undef;
};

# Escapes & < > " and ' for HTML.
sub html_escape {
    my ($text) = @_;
    $text = '' unless defined $text;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;
    $text =~ s/'/&#39;/g;
    return $text;
}

# Turns a list of name => value pairs into HTML attributes, every value escaped.
sub to_html {
    my @pairs = @_;
    my @parts;
    while ( my ( $name, $value ) = splice @pairs, 0, 2 ) {
        push @parts, sprintf '%s="%s"', $name, html_escape($value);
    }
    return join ' ', @parts;
}

# Lowercases, swaps anything outside a-z 0-9 _ for _, cuts to 64 characters.
sub normalize_key {
    my ($key) = @_;
    $key = lc( defined $key ? "$key" : '' );
    $key =~ s/[^a-z0-9_]/_/g;
    return substr $key, 0, MAX_KEY;
}

# Props as an ordered list of [key, value] pairs.
# Accepts a hash ref (keys sorted), an array ref of pairs, or a flat list of pairs.
sub props_pairs {
    my @args = @_;
    my @flat;
    if ( @args == 1 ) {
        my $props = $args[0];
        return [] unless defined $props;
        if ( ref $props eq 'HASH' ) {
            @flat = map { ( $_ => $props->{$_} ) } sort keys %{$props};
        }
        elsif ( ref $props eq 'ARRAY' ) {
            @flat = @{$props};
        }
        else {
            croak 'Props must be a hash ref, an array ref or a list of pairs';
        }
    }
    else {
        @flat = @args;
    }
    croak 'Props need an even number of items (key => value pairs)' if @flat % 2;

    my @pairs;
    while ( my ( $key, $value ) = splice @flat, 0, 2 ) {
        push @pairs, [ $key, $value ];
    }
    return \@pairs;
}

# Cleans the keys, merges repeated keys (the last value wins, the first place is
# kept), and optionally drops undef values and keeps the first 30 props.
sub _merge_pairs {
    my ( $pairs, $drop_undef ) = @_;
    my ( @keys, %values );
    for my $pair ( @{$pairs} ) {
        my $key = normalize_key( $pair->[0] );
        next if $key eq '';
        push @keys, $key unless exists $values{$key};
        $values{$key} = $pair->[1];
    }
    my @clean = map { [ $_, $values{$_} ] } @keys;
    @clean = grep { defined $_->[1] } @clean if $drop_undef;
    return \@clean;
}

# The normalised props: clean keys, no undef values, at most 30.
sub normalize_props {
    my $clean = _merge_pairs( props_pairs(@_), 1 );
    splice @{$clean}, MAX_PROPS if @{$clean} > MAX_PROPS;
    return $clean;
}

# Whether a value is a true/false value: a JSON boolean object, \1 or \0,
# or (Perl 5.36 and later) a builtin boolean.
sub is_bool {
    my ($value) = @_;
    return 0 unless defined $value;
    if ( blessed $value ) {
        return 1
          if $value->isa('JSON::PP::Boolean')
          || $value->isa('Types::Serialiser::Boolean')
          || $value->isa('boolean');
        return 0;
    }
    if ( ref $value eq 'SCALAR' ) {
        my $inner = ${$value};
        return defined $inner && ( $inner eq '1' || $inner eq '0' ) ? 1 : 0;
    }
    return 0 if ref $value;
    return 0 unless $BUILTIN_IS_BOOL;
    no warnings;    ## no critic (ProhibitNoWarnings)
    return $BUILTIN_IS_BOOL->($value) ? 1 : 0;
}

sub _bool_value {
    my ($value) = @_;
    return ref $value eq 'SCALAR' ? ${$value} : $value ? 1 : 0;
}

sub _scalar_text {
    my ($value) = @_;
    return _bool_value($value) ? 'true' : 'false' if is_bool($value);
    return "$value";
}

# The text of a prop value: true/false for booleans, lists joined with commas,
# cut to 500 characters.
sub string_value {
    my ($value) = @_;
    my $text =
      ref $value eq 'ARRAY'
      ? join( ',', map { _scalar_text($_) } grep { defined } @{$value} )
      : _scalar_text($value);
    return substr $text, 0, MAX_VALUE;
}

# ('data-privatus-event' => name, 'data-privatus-prop-<key>' => value, ...),
# or an empty list for an empty name.
sub event_data {
    my ( $name, @props ) = @_;
    $name = defined $name ? "$name" : '';
    $name =~ s/\A\s+|\s+\z//g;
    $name = substr $name, 0, MAX_NAME;
    $name =~ s/\s+\z//;
    return () if $name eq '';

    my @attrs = ( 'data-privatus-event' => $name );
    for my $pair ( @{ normalize_props(@props) } ) {
        push @attrs, "data-privatus-prop-$pair->[0]" => string_value( $pair->[1] );
    }
    return @attrs;
}

# The same attributes as escaped HTML to put inside a tag.
sub event_attrs {
    return to_html( event_data(@_) );
}

# Whether a click map name is valid: letters, digits, _ . : - and at most 100 characters.
sub valid_click_name {
    my ($name) = @_;
    return defined $name && "$name" =~ $CLICK_NAME ? 1 : 0;
}

# ('data-privatus-click' => name), or an empty list when the name is not valid.
sub click_data {
    my ($name) = @_;
    return valid_click_name($name) ? ( 'data-privatus-click' => "$name" ) : ();
}

# The click map attribute as HTML, or '' when the name is not valid.
sub click_attr {
    return to_html( click_data(@_) );
}

1;

__END__

=encoding utf8

=head1 NAME

PrivatusAnalytics::Attributes - data attributes for Privatus Analytics events and click maps

=head1 SYNOPSIS

  use PrivatusAnalytics::Attributes qw(event_attrs click_attr);

  my $html = event_attrs('Report exported', { format => 'csv' });
  # data-privatus-event="Report exported" data-privatus-prop-format="csv"

  my $click = click_attr('pricing.cta');
  # data-privatus-click="pricing.cta"

=head1 DESCRIPTION

Plain Perl, no framework needed. L<PrivatusAnalytics> and the framework
plugins wrap these functions. See L<PrivatusAnalytics> for the rules.

=head1 FUNCTIONS

=over 4

=item event_data($name, \%props | \@pairs | %props)

A list of attribute name and value pairs. An empty list for an empty name.

=item event_attrs($name, ...)

The same attributes as escaped HTML.

=item click_data($name)

C<< ('data-privatus-click' => $name) >>, or an empty list when the name is not valid.

=item click_attr($name)

The click attribute as HTML, or an empty string.

=item valid_click_name($name)

True when the name uses only letters, digits and C<_ . : ->, up to 100 characters.

=item html_escape($text)

Escapes C<& E<lt> E<gt> " '>.

=back

=head1 LICENSE

MIT. Copyright (c) 2026 Two Phase LLC.

=cut
