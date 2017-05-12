package Number::RGB;

use strict;
use warnings;

our $VERSION = '1.41'; # VERSION

use vars qw[$CONSTRUCTOR_SPEC];
use Scalar::Util qw[looks_like_number];
use Params::Validate qw[:all];
use base qw[Class::Accessor::Fast];
use Attribute::Handlers 0.99;
use Carp;
our @CARP_NOT = ('Attribute::Handlers', __PACKAGE__);
$Carp::Internal{'attributes'}++; # no idea why doesn't work in @CARP_NOT

sub import {
    my $class  = shift;
    my $caller = (caller)[0];
    eval qq[
        package $caller;
        use Attribute::Handlers;
        sub RGB :ATTR(RAWDATA) { goto &$class\::RGB }
        package $class;
    ];
}

use overload fallback => 1,
    '""'  => \&as_string,
    '+'   => sub { shift->_op_math('+',  @_) },
    '-'   => sub { shift->_op_math('-',  @_) },
    '*'   => sub { shift->_op_math('*',  @_) },
    '/'   => sub { shift->_op_math('/',  @_) },
    '%'   => sub { shift->_op_math('%',  @_) },
    '**'  => sub { shift->_op_math('**', @_) },
    '<<'  => sub { shift->_op_math('<<', @_) },
    '>>'  => sub { shift->_op_math('>>', @_) },
    '&'   => sub { shift->_op_math('&',  @_) },
    '^'   => sub { shift->_op_math('^',  @_) },
    '|'   => sub { shift->_op_math('|',  @_) };

sub new {
    my $class = shift;
    my %params = validate( @_,  $CONSTRUCTOR_SPEC );
    croak "$class->new() requires parameters" unless keys %params;

    my %rgb;
    if ( defined $params{rgb} ) {
        @rgb{qw[r g b]} = @{$params{rgb}};
    } elsif ( defined $params{rgb_number} ) {
        return $class->new(rgb => [($params{rgb_number})x3]);
    } elsif ( defined $params{hex} ) {
        my $hex = $params{hex};
        $hex =~ s/^#//;
        $hex =~ s/(.)/$1$1/g if length($hex) == 3;
        @rgb{qw[r g b]} = map hex, $hex =~ /(.{2})/g;
    }

    $class->SUPER::new(\%rgb);
}

__PACKAGE__->mk_accessors( qw[r g b] );

sub rgb       { [ map $_[0]->$_, qw[r g b] ] }
sub hex       { '#' . join '', map { substr sprintf('0%x',$_[0]->$_), -2 } qw[r g b] }
sub hex_uc    { uc shift->hex }
sub as_string {
    join ',', map $_[0]->$_, qw[r g b]
}

sub _op_math {
    my ($self,$op, $other, $reversed) = @_;
    ref($self)->new(rgb => [
        map {
            my $x = $self->$_;
            my $y = ref($other) && overload::Overloaded($other) ? $other->$_ : $other;
            my $ans = eval ($reversed ? "$y $op $x" : "$x $op $y");
            $ans = sprintf '%.0f', $ans||0;
            $ans = 0 if $ans < 0; $ans = 255 if $ans > 255;
            $ans;
        } qw[r g b]
    ] );
}

sub new_from_guess {
    my ($class, $value) = @_;
    $value = [ $value =~ /\d+/g ] if $value =~ /,/;
    my $is_single_rgb = looks_like_number($value) && $value>=0 && $value<=255;

    foreach my $param ( keys %{$CONSTRUCTOR_SPEC} ) {
        next if $param eq 'hex' and $is_single_rgb;
        my $self = eval { $class->new($param => $value) };
        return $self if defined $self;
    }
    croak q{couldn't guess value type};
}

sub RGB :ATTR(RAWDATA) {
    my ($var, $data) = @_[2,4];
    $$var = __PACKAGE__->new_from_guess($data);
}

$CONSTRUCTOR_SPEC = {
    rgb => {
        type      => ARRAYREF,
        optional  => 1,
        callbacks => {
            'three elements'    => sub { 3 == @{$_[0]} },
            'only digits'       => sub { 0 == grep /\D/, @{$_[0]} },
            'between 0 and 255' => sub { 3 == grep { $_ >= 0 && $_ <= 255 } @{$_[0]} },
        },
    },
    rgb_number => {
        type      => SCALAR,
        optional  => 1,
        callbacks => {
            'only digits'       => sub { $_[0] !~ /\D/ },
            'between 0 and 255' => sub {
                looks_like_number($_[0]) and $_[0] >= 0 && $_[0] <= 255
            },
        },
    },
    hex => {
        type      => SCALAR,
        optional  => 1,
        callbacks => {
            'hex format' => sub { $_[0] =~ /^#?(?:[\da-f]{3}|[\da-f]{6})$/i },
        },
    }
};

1;

__END__

=encoding utf8

=head1 NAME

Number::RGB - Manipulate RGB Tuples

=head1 SYNOPSIS

  use Number::RGB;
  my $white :RGB(255);
  my $black :RGB(0);

  my $gray = $black + ( $white / 2 );

  my @rgb = @{ $white->rgb };
  my $hex = $black->hex;

  my $blue   = Number::RGB->new(rgb => [0,0,255]);
  my $green  = Number::RGB->new(hex => '#00FF00');

  my $red :RGB(255,0,0);

  my $purple = $blue + $green;
  my $yellow = $red  + $green;

=head1 DESCRIPTION

This module creates RGB tuple objects and overloads their operators to
make RGB math easier. An attribute is also exported to the caller to
make construction shorter.

=head2 Methods

=head3 C<new>

  my $red   = Number::RGB->new(rgb => [255,0,0])
  my $blue  = Number::RGB->new(hex => '#0000FF');
  my $blue  = Number::RGB->new(hex => '#00F');
  my $black = Number::RGB->new(rgb_number => 0);

This constructor accepts named parameters. One of three parameters are
required.

C<rgb> is a array reference containing three integers within the range
of C<0..255>. In order, each integer represents I<red>, I<green>, and
I<blue>.

C<hex> is a hexadecimal representation of an RGB tuple commonly used in
Cascading Style Sheets. The format begins with an optional hash (C<#>)
and follows with three groups of hexadecimal numbers representing
I<red>, I<green>, and I<blue> in that order. A shorthand, 3-digit version
can be used: C<#123> is equivalent to C<#112233>.

C<rgb_number> is a single integer to use for each of the three primary colors.
This is shorthand to create I<white>, I<black>, and all shades of
I<gray>.

This method throws an exception on error.

=head3 C<new_from_guess>

  my $color = Number::RGB->new_from_guess( ... );

This constructor tries to guess the format being used and returns a
tuple object. If it can't guess, an exception will be thrown.

I<Note:> a single number between C<0..255> will I<never> be interpreted as
a hex shorthand. You'll need to explicitly prepend C<#> character to
disambiguate and force hex mode.

=head3 C<r>

Accessor and mutator for the I<red> value.

=head3 C<g>

Accessor and mutator for the I<green> value.

=head3 C<b>

Accessor and mutator for the I<blue> value.

=head3 C<rgb>

Returns a array reference containing three elements. In order they
represent I<red>, I<green>, and I<blue>.

=head3 C<hex>

Returns a hexadecimal representation of the tuple conforming to the format
used in Cascading Style Sheets.

=head3 C<hex_uc>

Returns the same thing as L</hex>, but any hexadecimal numbers that
include C<'A'..'F'> will be in upper case.

=head3 C<as_string>

Returns a string representation of the tuple.  For example, I<white>
would be the string C<255,255,255>.

=head2 Attributes

=head3 C<:RGB()>

  my $red   :RGB(255,0,0);
  my $blue  :RGB(#0000FF);
  my $white :RGB(0);

This attribute is exported to the caller and provides a shorthand wrapper
around L</new_from_guess>.

=head2 Overloads

C<Number::RGB> L<overloads|overload> the following operations:

    ""
    +
    -
    *
    /
    %
    **
    <<
    >>
    &
    ^
    |

Stringifying a C<Number::RGB> object will produce a string with three
RGB tuples joined with commas. All other operators operate on each
individual RGB tuple number.

If the tuple value is below C<0> after
the operation, it will set to C<0>. If the tuple value is above C<255> after
the operation, it will set to C<255>.

I<Note:> illegal operations (such us dividing by zero) result in the tuple
value being set to C<0>.

Operations create new C<Number::RGB> objects,
which means that even something as strange as this still works:

    my $color :RGB(5,10,50);
    print 110 - $color; # prints '105,100,60'

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/Number-RGB>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/Number-RGB/issues>

If you can't access GitHub, you can email your request
to C<bug-Number-RGB at rt.cpan.org>

=for html  </div></div>

=head1 MAINTAINER

This module is currently maintained by:

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/CWEST"> <img src="http://www.gravatar.com/avatar/1ed0b822068d34032bca7d2beeb2f846?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2Fb3bb9984adabb61d974f96965b2ed074" alt="CWEST" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">CWEST</span> </a> </span>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut