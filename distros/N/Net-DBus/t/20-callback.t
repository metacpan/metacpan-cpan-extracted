# -*- perl -*-
use Test::More tests => 5;

use strict;
use warnings;

BEGIN {
    use_ok('Net::DBus::Callback');
};

my $doneit = 0;

my $doer = Doer->new;

my $callback = Net::DBus::Callback->new(
					object => $doer,
					method => "doit",
					args => [4, 3, 5]
					);

$callback->invoke();
ok($doer->doneit == 12, "object callback");

$callback->invoke();
ok($doer->doneit == 24, "object callback");

$callback = Net::DBus::Callback->new(
				     method => \&doit,
				     args => [5,1,2]
				     );

$callback->invoke();
ok($doneit == 8, "subroutine callback");

$callback->invoke();
ok($doneit == 16, "subroutine callback");

sub doit {
    foreach (@_) {
	$doneit += $_;
    }
}

package Doer;


sub new {
    my $class = shift;
    my $self = {};
    
    $self->{doneit} = 0;

    bless $self, $class;
    
    return $self;
}

sub doit {
    my $self = shift;
    
    foreach (@_) {
	$self->{doneit} += $_;
    }
}

sub doneit {
    my $self = shift;
    return $self->{doneit};
}
