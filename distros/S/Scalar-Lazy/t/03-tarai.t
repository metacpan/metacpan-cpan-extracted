#!perl -T
#
# $Id: 03-tarai.t,v 0.1 2008/06/01 16:22:31 dankogai Exp $
#
# http://blog.livedoor.jp/dankogai/archives/50447103.html
# http://blog.livedoor.jp/dankogai/archives/50829735.html

use strict;
use warnings;
use Test::More tests => 1;
use Scalar::Lazy;

=pod

sub ltak {
    no warnings 'recursion';
    my ( $x, $y, $z ) = @_;
    return $y->() if $x->() <= $y->();
    ltak( sub{ ltak( sub { $x->() - 1 }, $y, $z ) },
          sub{ ltak( sub { $y->() - 1 }, $z, $x ) },
          sub{ ltak( sub { $z->() - 1 }, $x, $y ) });
}

sub tak{
    my ($x, $y, $z) = @_;
    ltak(sub{$x}, sub{$y}, sub{$z})
}

=cut


sub ltak{
    no warnings 'recursion';
    my ( $x, $y, $z ) = @_;
    return $y if $x <= $y;
    ltak( lazy{ ltak( lazy { $x - 1 }, $y, $z ) },
          lazy{ ltak( lazy { $y - 1 }, $z, $x ) },
          lazy{ ltak( lazy { $z - 1 }, $x, $y ) });
}

sub tak{
    my ($x, $y, $z) = @_;
    ltak(lazy{$x}, lazy{$y}, lazy{$z})
}

is tak(12, 6, 0), 12, 'tak(12, 6, 0) = 12';
