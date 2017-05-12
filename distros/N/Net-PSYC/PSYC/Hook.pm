package Net::PSYC::Hook;

sub trigger {
    my $self = shift;
    my $hook = shift;

    return 1 if (!exists $self->{'hooks'}->{$hook});
    foreach (@{$self->{'hooks'}->{$hook}}) {
	unless ($_->[0]->(@_)) {
	    return 0;
	}
    }
    return 1;
}

sub hook {
    my $self = shift;
    my $hook = shift;
    my $obj = shift;
    my $prio = shift;
    
    unless (ref $obj) {
	$obj = eval "$hook->new(\$self);";
	return 0 if (!ref $obj);
    }
    return 0 unless ($obj->can($hook));
    unless (exists $self->{'hooks'}->{$hook}) {
	$self->{'hooks'}->{$hook} = [];
    }
    my $sub = eval "sub { \$obj->$hook(\@_) }";
    return 0 unless $sub;

    if ($prio > 0) {
	unshift(@{$self->{'hooks'}->{$hook}}, [$sub, $obj]);
    } else {
	push(@{$self->{'hooks'}->{$hook}}, [$sub, $obj] );
    }
    return 1;
}

sub rmhook {
    my $self = shift;
    my $hook = shift;
    my $obj = shift;
    my $i = 0;
    return 1 unless (exists $self->{'hooks'}->{$hook});

    foreach (@{$self->{'hooks'}->{$hook}}) {
	if ($_->[1] eq $obj) {
	    splice(@{$self->{'hooks'}->{$hook}}, $i, 1);
	    return 1;
	}
	$i++;
    }
    return 0;
}


1;
