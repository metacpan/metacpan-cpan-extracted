package Parse::YALALR::Vector;

use strict;
use Carp;

# Translates between three types:
# call them bitvec, symname, symnum

sub new {
    my ($class) = @_;
    return bless { numvals => 0 }, ref $class || $class;
}

# add_value : symname -> symnum
#
# Register a symname, return its symnum
sub add_value {
    my ($self, $val) = @_;
    if ($self->{len_used}) { # DEBUGGING
        confess "Parse::YALALR::Vector expanded to include $val after vec used, ".
                "len would be wrong";
    }
    $self->{values}->[$self->{numvals}] = $val;
    $self->{indices}->{$val} = $self->{numvals}++;
}

# get_index : symname -> symnum
sub get_index {
    my ($self, $val, $nocreate) = @_;
    croak("Huh? get_index(number)??")
      if $val =~ /^\d+$/;
    my $i = $self->{indices}->{$val};
    if (defined $i) { return $i; }
    elsif (!$nocreate) { return $self->add_value($val); }
    else { return undef; }
}

# get_value : symnum -> symname
sub get_value {
    my ($self, $i) = @_;
    return $self->{values}->[$i];
}

# get_onevec : symname -> bitvec
sub get_onevec {
    my ($self, $val) = @_;
    my $i = $self->get_index($val);
    my $vec = "";
    vec($vec, $i, 1) = 1;
    $self->{len_used} = 1; # DEBUGGING
    return $vec;
}

# make_onevec : symnum -> bitvec
sub make_onevec {
    my ($self, $i) = @_;
    my $vec = '';
    vec($vec, $self->{numvals} - 1, 1) = 0; # Set the length
    vec($vec, $i, 1) = 1;
    $self->{len_used} = 1; # DEBUGGING
    return $vec;
}

# make_nullvec : () -> bitvec
sub make_nullvec {
    my ($self) = @_;
    my $vec = '';
    vec($vec, $self->{numvals} - 1, 1) = 0; # Set the length
    $self->{len_used} = 1; # DEBUGGING
    return $vec;
}


sub dump_bits {
    my ($self, $vec) = @_;
    return unpack("b*", $vec);
}

# get_values : bitvec -> ( symname )
sub get_values {
    my ($self, $vec) = @_;
    my @result;
    for (my $i = 0; $i < 8 * length($vec); $i++) {
	push(@result, $self->{values}->[$i])
	  if vec($vec, $i, 1);
    }
    return @result;
}

# get_indices : bitvec -> ( symnum )
sub get_indices {
    my ($self, $vec) = @_;
    my @result;
    for (my $i = 0; $i < 8 * length($vec); $i++) {
	push(@result, $i) if vec($vec, $i, 1);
    }
    return @result;
}

sub dump_vals {
    my ($self, $vec) = @_;
    my @vals;

    if (defined $vec) {
	for my $i (0 .. length($vec) * 8) {
	    push(@vals, $self->get_value($i)) if (vec($vec, $i, 1));
	}
    } else {
	for my $i (0 .. $self->{numvals} - 1) {
	    push(@vals, $self->get_value($i)) if (vec($vec, $i, 1));
	}
    }

    return @vals;
}

1;
