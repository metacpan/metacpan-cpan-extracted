use strict;
use warnings;

package Term::Chrome;
# ABSTRACT: DSL for colors and other terminal chrome
our $VERSION = '2.00';

# Pre-declare packages
{
    package # no index: private package
        Term::Chrome::Color;
}


use Exporter 5.57 'import';  # perl 5.8.3
# @EXPORT is defined at the end

use Carp ();
use Scalar::Util ();
our @CARP_NOT = qw< Term::Chrome::Color >;

# Private constructor for Term::Chrome objects. Lexical, so cross-packages.
# Arguments:
# - class name
# - foreground color
# - background color
# - flags list
my $new = sub
{
    my ($class, @self) = @_;

    my $fg = $self[0];
    Carp::croak "invalid fg color $fg"
        if defined($fg) && ($fg < 0 || $fg > 255);
    my $bg = $self[1];
    Carp::croak "invalid bg color $bg"
        if defined($bg) && ($bg < 0 || $bg > 255);
    # TODO check flags

    bless \@self, $class
};


# Cache for color objects
my %COLOR_CACHE;

sub color ($)
{
    my $color = shift;
    die "invalid color" if ref $color;
    my $c = chr $color;
    # We can not use '$COLOR_CACHE{$c} ||= ...' because this requires overloading
    # We can not use 'no overloading' because this requires perl 5.10
    exists $COLOR_CACHE{$c}
    ?  $COLOR_CACHE{$c}
    : ($COLOR_CACHE{$c} = Term::Chrome::Color->$new($color, undef))
}


use overload
    '""' => 'term',
    '+'  => '_plus',
    '${}' => '_deref',
    '&{}' => '_chromizer',
    '.'   => '_concat',
    '!'   => '_reverse',
    'bool' => sub () { 1 },
    fallback => 0,
;

sub term
{
    my $self = shift;
    my ($fg, $bg) = @{$self}[0, 1];
    my $r = join(';', @{$self}[2 .. $#$self]);
    if (defined($fg) || defined($bg)) {
        $r .= ';' if @$self > 2;
        if (defined $fg) {
            # LeoNerd says that this should be ----------> "38:5:$fg"
            # according to the spec but gnome-terminal doesn't support that
            $r .= $fg < 8 ? (30+$fg) : $fg < 16 ? "9$fg" : "38;5;$fg";
            $r .= ';' if defined $bg;
        }
        #                                      -------> "48:5:$bg"
        $r .= $bg < 8 ? (40+$bg) : $bg < 16 ? "10$bg" : "48;5;$bg" if defined $bg;
    } else {
        return '' unless @$self > 2
    }
    "\e[${r}m"
}


sub _plus
{
    my ($self, $other, $swap) = @_;

    return $self unless defined $other;

    die 'invalid value for +' unless $other->isa(__PACKAGE__);

    my @new = @$self;
    $new[0] = $other->[0] if defined $other->[0];
    $new[1] = $other->[1] if defined $other->[1];
    push @new, @{$other}[2 .. $#$other];

    bless \@new
}

sub _reverse
{
    my $self = shift;
    my @new = (undef, undef);
    push @new, 39 if $self->[0]; # ResetFg
    push @new, 49 if $self->[1]; # ResetBg
    # Reset/ResetFlags/ResetFg/ResetBg are removed
    # Other flags are reversed
    push @new, map { (!$_ || $_ == 22 || $_ > 30) ? () : ($_ > 20 ? $_-20 : $_+20) } @{$self}[2..$#$self];
    bless \@new, 'Term::Chrome::Flag'
}

sub _deref
{
    \("$_[0]")
}

sub _concat
{
    $_[2] ? $_[1].$_[0]->term
          : $_[0]->term.$_[1]
}


sub _chromizer
{
    my $self = shift;
    my $begin = $self->term;
    my $end = $self->_reverse->term;
    sub {
        unless (defined $_[0]) {
            Carp::carp "missing argument in Term::Chrome chromizer";
            return
        }
        $begin . $_[0] . $end
    }
}

sub fg
{
    my $c = $_[0]->[0];
    defined($c) ? color($c) : undef
}

sub bg
{
    my $c = $_[0]->[1];
    defined($c) ? color($c) : undef
}

sub flags
{
    my $self = shift;
    return undef unless @$self > 2;
    __PACKAGE__->$new(undef, undef, @{$self}[2..$#$self])
}

package # no index: private package
    Term::Chrome::Color;

our @ISA = qw< Term::Chrome >;

use overload
    '/'   => '_over',
    # Even if overloading is set in the super class, we have to repeat it for old perls
    (
        $^V ge v5.18.0
        ? ()
        : (
            '""'  => \&Term::Chrome::term,
            '+'   => \&Term::Chrome::_plus,
            '${}' => \&Term::Chrome::_deref,
            '.'   => \&Term::Chrome::_concat,
            '!'   => \&Term::Chrome::_reverse,
            'bool' => sub () { 1 },
        )
    ),
    fallback => 0,
;

sub _over
{
    die 'invalid bg color for /' unless ref($_[1]) eq __PACKAGE__;
    Term::Chrome->$new($_[0]->[0], $_[1]->[0])
}

package # no index: private package
    Term::Chrome::Flag;

our @ISA = qw< Term::Chrome >;

use overload
    '+'   => '_plus',
    '!'   => '_reverse',
    # Even if overloading is set in the super class, we have to repeat it for old perls
    (
        $^V ge v5.18.0
        ? ()
        : (
            '""'  => \&Term::Chrome::term,
            '${}' => \&Term::Chrome::_deref,
            '.'   => \&Term::Chrome::_concat,
            'bool' => sub () { 1 },
        )
    ),
    fallback => 0,
;

sub _reverse
{
    my $self = shift;
    bless [
        undef, undef,
        # Reset/ResetFlags/ResetFg/ResetBg are removed
        map { (!$_ || $_ == 22 || $_ > 30) ? () : ($_ > 20 ? $_-20 : $_+20) } @{$self}[2..$#$self]
    ]
}

sub _plus
{
    my ($self, $other, $swap) = @_;

    return $self unless defined $other;

    Carp::croak(q{Can't combine Term::Chrome with }.$other)
        unless Scalar::Util::blessed $other;

    if ($other->isa(__PACKAGE__)) {
        # Reset
        return $other if !$other->[2];
        # ResetFlags
        return $other if $other->[2] == 22;
        # Concat flags
        __PACKAGE__->$new(@$self, @{$other}[2..$#$other])
    } elsif ($other->isa(Term::Chrome::)) {
        $other->_plus($self, '')
    } else {
        Carp::croak(q{Can't combine Term::Chrome with }.ref($other))
    }
}


package
    Term::Chrome;

# Build the constants and the @EXPORT list
#
# This block must be after "use overload" (for both Term::Chrome
# and Term::Chrome::Color) because overload must be set before blessing
# due to a bug in perl < 5.18
# (according to a comment in Types::Serialiser source)

my $mk_flag = sub { Term::Chrome::Flag->$new(undef, undef, $_[0]) };

my %const = (
    Reset      => $mk_flag->(''),
    ResetFg    => $mk_flag->(39),
    ResetBg    => $mk_flag->(49),
    ResetFlags => $mk_flag->(22),
    Standout   => $mk_flag->(7),
    Underline  => $mk_flag->(4),
    Reverse    => $mk_flag->(7),
    Blink      => $mk_flag->(5),
    Bold       => $mk_flag->(1),

    Black      => color 0,
    Red        => color 1,
    Green      => color 2,
    Yellow     => color 3,
    Blue       => color 4,
    Magenta    => color 5,
    Cyan       => color 6,
    White      => color 7,

    # Larry Wall's favorite color
    # The true 'chartreuse' color from X11 colors is #7fff00
    # The xterm-256 color #118 is near: #87ff00
    Chartreuse => color 118,
);

our @EXPORT = ('color', keys %const);

# In 17fd029f we avoided to use constant.pm on perl < 5.16
# This does not seem necessary anymore.
require constant;
constant->import(\%const);

1;
# vim:set et ts=8 sw=4 sts=4:
