use strict;
use warnings;
use utf8;
use open qw( :std :utf8 );
use Test::More;
use Test::Exception;
use Test::Mock::Time;

use Sub::Throttler::Limit;

use EV;

my (@Start,@End);

my @t;

package Class;
use Sub::Throttler qw( :ALL );
sub new { bless {}, shift }
sub method {
    my $done = &throttle_me || return;
    my ($self, @p) = @_;
    $self->_start(@p);   # crash if $self isn't object/class
    push @t, EV::timer 0.01, 0, done_cb($done, $self, '_end', @p);
    return;
}
sub _start {
    my ($self, @p) = @_;
    push @Start, $p[0];
}
sub _end {
    my ($self, @p) = @_;
    push @End, $p[0];
}
package Class::SubClass;
use base qw( Class );
package main;

# Sub::Throttler handle subclass methods as functions.
# Sub::Throttler doesn't handle Class methods.

my $Timeout;
push @t, EV::timer 1, 0, sub { $Timeout = 1 };

Sub::Throttler::Limit->new(limit => 2)->apply_to_methods('Class');

# - $obj

(@Start,@End) = ();
my $obj = Class->new;
$obj->method(10);
$obj->method(20);
$obj->method(30);
is_deeply \@Start, [10,20],
    'throttled';
EV::run EV::RUN_ONCE until 3==@End || $Timeout;
is_deeply \@Start, [10,20,30],
    '$obj methods';

# - $subobj

(@Start,@End) = ();
my $subobj = Class::SubClass->new;
$subobj->method(10);
$subobj->method(20);
$subobj->method(30);
is_deeply \@Start, [10,20],
    'throttled';
EV::run EV::RUN_ONCE until 3==@End || $Timeout;
is_deeply \@Start, [10,20,30],
    '$subobj methods';

# - Class

(@Start,@End) = ();
Class->method(10);
Class->method(20);
Class->method(30);
is_deeply \@Start, [10,20],
    'throttled';
EV::run EV::RUN_ONCE until 3==@End || $Timeout;
is_deeply \@Start, [10,20,30],
    'Class methods';

# - Class::SubClass

(@Start,@End) = ();
Class::SubClass->method(10);
Class::SubClass->method(20);
Class::SubClass->method(30);
is_deeply \@Start, [10,20],
    'throttled';
EV::run EV::RUN_ONCE until 3==@End || $Timeout;
is_deeply \@Start, [10,20,30],
    'Class::SubClass methods';


done_testing();
