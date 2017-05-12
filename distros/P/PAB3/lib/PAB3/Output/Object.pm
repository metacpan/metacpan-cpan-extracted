package PAB3::Output::Object;

use strict;
no strict 'refs';

use vars qw($VERSION);

BEGIN {
	$VERSION = '1.0.0';
}

sub TIEHANDLE {
    my $class = shift;
    my $obj = shift;
    my $sub = shift;
    my $call = ref( $obj ) . '::' . $sub;
	bless [ $call, $obj ], $class;
}

sub PRINT {
	my $self = shift;
	&{"$self->[0]"}( $self->[1], @_ );
}

sub UNTIE {
}

1;
