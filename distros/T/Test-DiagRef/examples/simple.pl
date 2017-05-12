#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

{
    package MyClass;
    sub new
    {
	my $class = shift;
	my $self;
	# Self-reference : this is a bug that we want to detect!
	$self = bless \$self, $class
    }
}


use Test::More tests => 1;
use Test::DiagRef;
use Scalar::Util 'weaken';


note 'This is a demo of Test::DiagRef. The test is expected to fail.';

my $obj = MyClass->new;

# $ref is a weak reference to the object
weaken(my $ref = $obj);

# If MyClass was ok, this would destroy the object, and so $ref would become
# undef.
undef $obj;

# This test is expected to fail: this is a demo of Test::DiagRef!
is($ref, undef, 'no leak') or diag_ref($ref);
