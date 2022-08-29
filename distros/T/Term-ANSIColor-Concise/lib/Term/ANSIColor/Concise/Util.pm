package #
ToggleValue {

    use v5.14;
    use warnings;

    sub new {
	my $class = shift;
	my $obj = bless {}, $class;
	my %opt = @_;
	$obj->{VALUE} = $opt{value} // 1;
	$obj->{CURRENT} = $obj->{INIT} = $opt{init} // 0;
	$obj;
    }

    sub toggle {
	my $obj = shift;
	my $prev = $obj->{CURRENT};
	$obj->{CURRENT} ^= $obj->{VALUE};
	$prev;
    }

    sub value {
	my $obj = shift;
	$obj->{CURRENT};
    }

    sub reset {
	my $obj = shift;
	$obj->{CURRENT} = $obj->{INIT};
    }

}

1;
