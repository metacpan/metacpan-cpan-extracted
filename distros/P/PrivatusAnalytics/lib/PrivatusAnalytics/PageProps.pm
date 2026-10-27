package PrivatusAnalytics::PageProps;

use 5.020;
use strict;
use warnings;

use B                             ();
use Exporter                      qw(import);
use JSON::PP                      ();
use PrivatusAnalytics::Attributes qw(normalize_props is_bool);

our $VERSION = '1.0.0';

our @EXPORT_OK = qw(page_props_json);

use constant MAX_ITEMS => 30;

my $JSON = JSON::PP->new->allow_nonref;

# Whether a plain scalar holds a number (and was never used as text).
sub _is_number {
    my ($value) = @_;
    return 0 if ref $value;
    my $flags = B::svref_2object( \$value )->FLAGS;
    return ( $flags & ( B::SVp_IOK() | B::SVp_NOK() ) ) && !( $flags & B::SVp_POK() ) ? 1 : 0;
}

sub _scalar_json {
    my ($value) = @_;
    return undef unless defined $value;    ## no critic (ProhibitExplicitReturnUndef)
    if ( is_bool($value) ) {
        my $true = ref $value eq 'SCALAR' ? ${$value} : $value ? 1 : 0;
        return $true ? 'true' : 'false';
    }
    if ( _is_number($value) ) {

        # NaN and infinity are not JSON, so they are left out.
        return undef if $value != $value || $value * 0 != 0;    ## no critic (ProhibitExplicitReturnUndef)
        return $JSON->encode($value);
    }
    return $JSON->encode( substr "$value", 0, PrivatusAnalytics::Attributes::MAX_VALUE() );
}

sub _value_json {
    my ($value) = @_;
    if ( ref $value eq 'ARRAY' ) {
        my @items = grep { defined } @{$value};
        splice @items, MAX_ITEMS if @items > MAX_ITEMS;
        return '[' . join( ',', grep { defined } map { _scalar_json($_) } @items ) . ']';
    }
    return _scalar_json($value);
}

# A JSON object that is safe inside a <script>, or undef when there are no props.
# Takes the same shapes as event props: a hash ref, an array ref of pairs, or pairs.
sub page_props_json {
    my @parts;
    for my $pair ( @{ normalize_props(@_) } ) {
        my $value = _value_json( $pair->[1] );
        push @parts, $JSON->encode( $pair->[0] ) . ':' . $value if defined $value;
    }
    return undef unless @parts;    ## no critic (ProhibitExplicitReturnUndef)

    my $json = '{' . join( ',', @parts ) . '}';
    $json =~ s/([<>&\x{2028}\x{2029}])/sprintf '\\u%04x', ord $1/ge;
    return $json;
}

1;

__END__

=encoding utf8

=head1 NAME

PrivatusAnalytics::PageProps - page props as JSON that is safe inside a script tag

=head1 SYNOPSIS

  use PrivatusAnalytics::PageProps qw(page_props_json);

  page_props_json([ plan => 'pro', seats => 5, beta => \1 ]);
  # {"plan":"pro","seats":5,"beta":true}

=head1 DESCRIPTION

Keys follow the same rules as event props. Numbers, true and false and lists
keep their JSON types. Lists keep at most 30 items. C<< < > & >> and the
characters U+2028 and U+2029 are written as C<\uXXXX>, so the JSON cannot end
the script early.

Perl has no separate true and false values before 5.36. Pass C<\1> and C<\0>,
or C<JSON::PP::true> and C<JSON::PP::false>, to get JSON C<true> and C<false>.

=head1 LICENSE

MIT. Copyright (c) 2026 Two Phase LLC.

=cut
