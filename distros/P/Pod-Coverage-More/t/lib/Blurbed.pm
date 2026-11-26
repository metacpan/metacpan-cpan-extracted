package Blurbed;

# Subs with blurbs and no POD, for t/Pod-Coverage-More-Generator.t to generate POD for and check it.

use 5.036;
use warnings FATAL => q{all};

=head1 NAME

Blurbed - subs that a blurb documents

=head2 documented

Documented by hand, so it gets no generated section.

    Blurbed::documented();

=cut

sub documented {
    return;
}

# Double a number.
# @param   count   Num  what to double
# @returns Num  twice the count
# @example my $four = Blurbed::double(2);
sub double {
    my ($count) = @_;
    return $count * 2;
}

# Make a widget from named options.
# @param  size    Int  how big
# @param  colour  Str  what colour
# @throws when the size is negative
# @throws with a Blurbed::Exception when the size is over 1000
# @example my $widget = Blurbed->make( size => 3, colour => 'red' );
sub make {
    my ( $class, %opts ) = @_;
    die "negative\n"                                  if $opts{size} < 0;
    Blurbed::Exception->throw( message => 'too big' ) if $opts{size} > 1000;
    return bless { size => $opts{size}, colour => $opts{colour} }, $class;
}

# Says yes.
# @example Blurbed::yes();
sub yes {
    return 1;
}

# A default that subclasses override, which ignores its argument.
# @param  record  HashRef  what to work on
# @example $object->hook( {} );
sub hook {
    return;
}

# Maybe a widget.
# @param   x  Any  whether to make one
# @example my $widget = Blurbed::maybe(1);
sub maybe {
    my ($x) = @_;
    return $x ? bless( {}, 'Blurbed' ) : undef;
}

# The paths that a snapshot does not have.
# @param   snapshot  HashRef  what to look in
# @param   @paths    Str  each path to look for
# @returns the paths, as a list
# @example my @missing = Blurbed::missing( {}, 'a', 'b' );
sub missing ( $snapshot, @paths ) {
    return grep { !$snapshot->{$_} } @paths;
}

# The port to listen on.
# @returns 443 when nothing else is set
# @example my $port = Blurbed::port();
sub port {
    return 443;
}

sub plain {
    return 2;
}

1;
