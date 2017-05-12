#! perl -Tw

# These are the tests of tainting tied variables.

BEGIN {
    unshift @INC, '..' if -d '../t' and -e '../Taint.pm';
    unshift @INC, '.' if -d 't' and -e 'Taint.pm';
}

BEGIN { $|=1; print "1..11\n"; }
use strict;
my @warnings;

END { print "not ok\n", @warnings if @warnings }

BEGIN {
    $SIG{'__WARN__'} = sub { push @warnings, @_ };
    $^W = 1;
}

use Taint qw(:ALL);

sub test ($$;$) {
    my($num, $bool, $diag) = @_;
    if ($bool) {
	print "ok $num\n";
	return;
    }
    print "not ok $num\n";
    return unless defined $diag;
    $diag =~ s/\Z\n?/\n/;	# unchomp
    print map "# $num : $_", split m/^/m, $diag;
}

{
    package MagicScalar;

    # A MagicScalar may be assigned any number of values.
    # When evaluated, it returns one of them at random, with
    # the most likely ones being the least recently returned.
    #
    # Because its values can't be set in the usual
    # way, we need to taint it "natively".

    use Taint qw/:ALL/;
    use vars qw/$DEBUGGING/;
    $DEBUGGING = 0;

    sub TIESCALAR {
	warn "TIESCALAR: " . join(" ", map "'$_'", @_) if $DEBUGGING;
	my $class = shift;
	my $self = {
	    list  => [ map [$_, 0], @_ ],
	};
	bless $self, $class;
    }

    sub STORE {
	warn "STORE: " . join(" ", map "'$_'", @_) if $DEBUGGING;
	my $self = shift;
	my $data = shift;
	my($copy) = $data =~ /^(.*)$/s;	# Taint-free copy
	$self->{'taint'} = is_tainted $data
	    unless $self->{'taint'};
	push @{ $self->{list} }, [ $copy, 0 ];
	$data;
    }

    sub FETCH {
	warn "FETCH: " . join(" ", map "'$_'", @_) if $DEBUGGING;
	my $self = shift;
	return unless @{ $self->{list} };	# undef
	my $so_far = 0;
	my $choice;
	for (@{ $self->{list} }) {
	    $choice = $_
		if rand($so_far += ++$_->[1]) <= $_->[1];
	}
	$choice->[1] = 0;	# reset the count
	return $choice->[0] unless
	    $self->{'taint'};
	$choice->[0] . tainted_null ;		# return value
    }

    sub DESTROY {
	warn "DESTROY: " . join(" ", map "'$_'", @_) if $DEBUGGING;
	my $self = shift;
	undef $$self;
    }

    sub TAINT {
	warn "TAINT: " . join(" ", map "'$_'", @_) if $DEBUGGING;
	my $self = shift;
	my $tainted = (@_ ? shift : 1);
	$self->{'taint'} = $tainted;
    }
}

my $foo;
tie $foo, 'MagicScalar';
test 1, not defined $foo;
my $bar;
tie $bar, 'MagicScalar', 0..3;
test 2, not tainted $bar;
taint $bar;
test 3, tainted $bar;

# Currently, the only way to untaint one of these
tied($bar)->can('TAINT')->(tied $bar, 0);
test 4, not tainted $bar;

for (1..3) {
    $foo = $_;
}
test 5, not tainted $foo;
taint $foo;
test 6, tainted $foo;

my $baz;
tie $baz, 'MagicScalar';
$baz = 1;
test 7, not tainted $baz;
$baz = 17 + tainted_zero;

# There's a bug in 5.004_03 and earlier which doesn't
# pass taintedness to tied scalars and hashes. :-(
# That's why the version numbers on tests 8 & 9.
my $biz;
{ redo unless ($biz = $baz) > 1 }
test 8, (tainted $biz) || ($] < 5.00404);
{ redo unless ($biz = $baz) == 1 }
test 9, (tainted $biz) || ($] < 5.00404);
tied($baz)->can('TAINT')->(tied $baz, 0);
test 10, not tainted $baz;

test 11, not @warnings;
exit;
