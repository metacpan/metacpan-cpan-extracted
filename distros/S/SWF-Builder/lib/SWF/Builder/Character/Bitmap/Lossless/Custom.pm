package SWF::Builder::Character::Bitmap::Lossless::Custom;

use strict;

our @ISA = ('SWF::Builder::Character::Bitmap::Lossless');
our $VERSION = '0.011';

sub new {
    my ($class, $obj) = @_;

    my %self;
    @self{qw/ _width _height _colors _is_alpha _pixsub /} = @$obj;

    bless \%self, $class;
}

1;

