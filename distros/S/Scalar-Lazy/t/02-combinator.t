#!perl -T
#
# $Id: 02-combinator.t,v 0.1 2008/06/01 16:22:31 dankogai Exp $
#
# http://blog.livedoor.jp/dankogai/archives/50458503.html

use strict;
use warnings;
use Test::More tests => 1;
use Scalar::Lazy;

=pod

my $FORCE = sub { shift };
my $ZM    = sub { my $f = shift;
               sub { my $x = shift; 
                     sub { my $y = shift;
                           $f->($x->($x))
                     }
                 }->(sub { my $x = shift; 
                           sub { my $y = shift; 
                                 $f->($x->($x)) 
                           }
                     })
         };

our $FACT = $ZM->(
    sub {
        my $f = shift;
        sub {
            my $n = shift;
            $n < 2
              ? 1
              : $n * $f->($FORCE)( $n - 1 );
          }
    }
)->($FORCE);

warn $FACT->(10);

=cut

my $zm = sub { my $f = shift;
               sub { my $x = shift; 
                     lazy { $f->($x->($x)) }
                 }->(sub { my $x = shift; 
                           lazy { $f->($x->($x)) }
		       }) };

my $fact = $zm->(sub { my $f = shift;
		       sub { my $n = shift;
			     $n < 2  ? 1 : $n * $f->($n - 1) } });

is $fact->(10), 3628800, '$fact->(10) == 3628800';

