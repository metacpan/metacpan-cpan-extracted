# -*- indent-tabs-mode: nil -*-

=head1 SEE ALSO

L<Graphics::ColorUtils>

L(<https://qiita.com/yoya/items/96c36b069e74398796f3>

=cut

package Term::ANSIColor::Concise::ColorUtils;

our $VERSION = "3.01";

use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Graphics::ColorUtils;
use List::Util qw(min max pairs);

sub clip { max(min($_[0], $_[1]), 0) }

sub rgb {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        bless [ map { max(min(255, $_), 0) } @_ ], $class;
    } else {
        map int, @{$self};
    }
}

sub hsl2rgb { hls2rgb $_[0], $_[2], $_[1] }
sub rgb2hsl { (rgb2hls(@_))[0,2,1] }

sub hsl {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        my($h, $s, $l) = @_;
        $class->rgb(hls2rgb($h, $l/100, $s/100));
    } else {
        my @hsl = rgb2hsl($self->rgb);
        map int, ($hsl[0], $hsl[1] * 100, $hsl[2] * 100);
    }
}

sub yiq {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        my($y, $i, $q) = @_;
        $class->rgb(yiq2rgb($y/100, $i/100, $q/100));
    } else {
        my($y, $i, $q) = rgb2yiq($self->rgb);
        map int, ($y*100, $i*100, $q*100);
    }
}

sub luminance {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        my($y, $i, $q) = $self->yiq;
        my @yiq = $self->yiq;
        $class->yiq($_[0], $yiq[1], $yiq[2]);
    } else {
        ($self->yiq)[0];
    }
}

1;
