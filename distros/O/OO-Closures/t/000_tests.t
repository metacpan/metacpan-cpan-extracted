# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use OO::Closures;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub dice {
    my (%methods, %ISA, $self);
    $self = create_object (\%methods, \%ISA, !@_);

    my $faces = 6;

    $methods {set}   = sub {$faces = shift;};
    $methods {roll}  = sub {1 + int rand $faces};
    $methods {faces} = \$faces;

    $self;
}

(my $die = dice) -> (set => 10);
my $faces = $die -> ('faces');
my $roll  = $die -> ('roll');

print $faces == 10 ? "ok 2\n" : "not ok 2\n";

print +(defined $roll && $roll !~ /\D/ && 1 <= $roll && $roll <= 10) 
      ? "ok 3\n" : "not ok 3\n";


sub simple_dice {
    my (%methods, %ISA, $self);
    $self = create_object (\%methods, \%ISA, !@_);
    my $this_object = shift || $self;

    my $faces = 6;

    $methods {set}   = sub {$faces = shift};
    $methods {roll}  = sub {1 + int rand $faces};
    $methods {faces} = sub {$faces};

    $self;
}

sub multi_dice {
    my (%methods, %ISA, $self);
    $self = create_object (\%methods, \%ISA, !@_);
    my $this_object = shift || $self;

    %ISA  = (dice => simple_dice $this_object);

    my $amount = 1;

    $methods {amount} = sub {$amount = shift};
    $methods {roll}   = sub {
        my $sum = 0;
        foreach (1 .. $amount) {$sum += $self -> ('dice::roll')}
        $sum;
    };

    $self;
}

my $mdie = multi_dice;
$mdie -> (set    => 7);
$mdie -> (amount => 4);
my $mroll = $mdie -> ('roll');
print +(defined $mroll && $mroll !~ /\D/ && 4 <= $mroll && $mroll <= 28)
      ? "ok 4\n" : "not ok 5\n";


sub base {
    my (%methods, %ISA, $self);
    $self = create_object (\%methods, \%ISA, !@_);
    my $this_object = shift || $self;

    $methods {test}    = sub {wantarray ? "array" : "scalar"};
    $methods {feature} = \"feature";

    $self;
}

sub derived {
    my (%methods, %ISA, $self);
    $self = create_object (\%methods, \%ISA, !@_);
    my $this_object = shift || $self;

    %ISA  = (base => base $this_object);

    $methods {error1} = [1, 2, 3];
    $methods {error2} =  1;

    $self;
}

my $test = derived;
my @a = $test -> ('test');
print +(1 == @a && $a [0] eq 'array') ? "ok 5\n" : "not ok 5\n";
my $a = $test -> ('test');
print +($a eq 'scalar') ? "ok 6\n" : "not ok 6\n";

eval {$test -> ('error1')};
print $@ =~ /^Illegal method/ ? "ok 7\n" : "not ok 7\n";
eval {$test -> ('error2')};
print $@ =~ /^Illegal method/ ? "ok 8\n" : "not ok 8\n";

# This seems to be necessary due to weirdness with eval in a 'make test'.
eval {0};

print +("feature" eq $test -> ('feature')) ? "ok 9\n" : "not ok 9\n";

__END__
