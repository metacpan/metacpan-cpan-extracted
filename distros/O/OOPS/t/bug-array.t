#!/usr/bin/perl

print "1..1\n";

my $x = [ 'a', 'b', 'c', 'd', 'e' ];

tie @$x, 'OverArray', $x;

#print "3,2 = ".join(' ', @$x[3, 2])."\n";

splice(@$x, 2, 2, @$x[3, 2]);
#splice(@$x, 2, 2, $x->[3], $x->[2]);

#print "x = @$x\n";

print ($x->[3] eq 'c' ? "ok 1\n" : "not ok 1 # TODO Bug in perl: cannot slice tied arrays\n");

package OverArray;

sub UNTIE
{
}

sub DESTROY
{
}

sub TIEARRAY
{
	my $pkg = shift;
	my $orig = shift;
	my $self = bless [ [ @$orig ], $orig ], $pkg;
	return $self;
}

sub FETCH
{
	my $self = shift;
	my ($fake, $real) = @$self;
	my $index = shift;
	return $fake->[$index];
}

sub STORE
{
	my $self = shift;
	my ($fake, $real) = @$self;
	my ($index, $value) = @_;
	$fake->[$index] = $value;
}

sub FETCHSIZE
{
	my $self = shift;
	my ($fake, $real) = @$self;
	return scalar(@$fake);
}


sub STORESIZE
{
	my $self = shift;
	my ($fake, $real) = @$self;
	my $count = shift;
	$self->SPLICE($count - scalar(@$fake))
		if $count < @$fake;
	$#$fake = $count-1;
}

sub EXTEND
{
	my $self = shift;
	my ($fake, $real) = @$self;
	my $count = shift;
	$#$fake = $count-1 if $count > @$fake;
}

sub EXISTS
{
	my $self = shift;
	my ($fake, $real) = @$self;
	my $index = shift;
	return exists($fake->[$index]);
}

sub DELETE
{
	my $self = shift;
	my $index = shift;
	my ($fake, $real) = @$self;
	delete $fake->[$index];
}

sub CLEAR
{
	my $self = shift;
	my ($fake, $real) = @$self;
	$fake->STORESIZE(0);
}

sub PUSH
{
	my $self = shift;
	my ($fake, $real) = @$self;
	push(@$fake, @_);
}

sub POP
{
	my $self = shift;
	return $self->SPLICE(-1,1);
}

sub SHIFT
{
	my $self = shift;
	return $self->SPLICE(0,1);
}

sub UNSHIFT
{
	my $self = shift;
	return $self->SPLICE(0,0,@_);
}

sub SPLICE
{
	my $self = shift;
	my ($fake, $real) = @$self;
	my $offset = shift || 0;
	my $length = shift;
	$offset += @$fake if $offset < 0;
	$length = $#$fake - $offset
		unless defined $length;
	my (@rv) = splice(@$fake, $offset, $length, @_);
	return @rv;
}

1;
