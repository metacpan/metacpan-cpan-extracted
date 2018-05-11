# 
# Test::Conditions.pm
# 
# This module allows you to set and clear an arbitrary set of conditions tagged by an arbitrary
# set of labels.  Its purpose is to facilitate testing large data structures, for example trees
# and lists, without generating enormous numbers of individual tests.  Instead, you can create a
# Test::Conditions instance, and then run through the various nodes in the data structure running
# a series of checks on each node. When you are finished, you can execute a single test which will
# fail if any unexpected conditions were flagged and succeed otherwise.


package Test::Conditions;

use strict;

use Carp qw(croak);
use Test::More;
use Scalar::Util qw(reftype);

our $VERSION = '0.83';


# If the variable $TEST_INVERT is set, then invert all tests. If either $TEST_INVERT or
# $TEST_OUTPUT is set, then direct all diagnostic output to $TEST_DIAG. This is necessary for
# the purpose of testing this module.

our $TEST_INVERT = 0;
our $TEST_OUTPUT = 0;
our $TEST_DIAG = '';


# new ( )
# 
# Create a new Test::Conditions object.

sub new {
    
    my ( $class, $dummy ) = @_;
    
    croak "you may not specify any arguments to this call" if defined $dummy;
    
    my $new = { default_limit => 0,
		max => { },
		expect => { },
		label => { },
		count => { },
		tested => { },
	      };
    
    bless $new, $class;
    
    return $new;
}


# limit_max ( condition => limit )
#
# Set the maximum number of times the specified condition can be flagged before it causes ok_all
# to fail. The default for every condition is zero. If you want to specify limits for more than
# one condition, you can pass in a hash ref whose keys are condition names and whose values are
# nonnegative integers. If the condition name is 'DEFAULT' then this limit will become the default
# for every condition.

sub limit_max {
    
    my ($tc, $condition, $limit) = @_;
    
    # If the first argument is a hashref, set the specified limit for every key. The key values
    # must be nonnegative integers.
    
    if ( ref $condition && reftype $condition eq 'HASH' )
    {
	croak "if the first argument is a hashref you may not specify a second one"
	    if defined $limit && $limit ne '';
	
	foreach my $key ( keys %$condition )
	{
	    croak "invalid condition key '$key'" unless $key ne '' && $key !~ /^\d+$/;
	    croak "the limit value for '$key' must be a nonnegative integer"
		unless defined $condition->{$key} && $condition->{$key} =~ /^\d+$/;
	    
	    if ( $key eq 'DEFAULT' )
	    {
		$tc->{default_limit} = $limit;
	    }
	    
	    else
	    {
		$tc->{max}{$key} = $condition->{$key};
	    }
	}
    }
    
    # Otherwise, the caller must pass a non-empty key and a non-negative integer value.
    
    else
    {
	$condition ||= '';
	croak "invalid condition key '$condition'" unless defined $condition && $condition ne '' && $condition !~ /^\d+$/;
	croak "the limit value must be a nonnegative integer" unless defined $limit && $limit =~ /^\d+$/;
	
	if ( $condition eq 'DEFAULT' )
	{
	    $tc->{default_limit} = $limit;
	}
	
	else
	{
	    $tc->{max}{$condition} = $limit;
	}
    }
}


# get_limit ( key )
# 
# Get the limit if any that was set for the specified key. If there is none, and if a default
# limit was set, return that. Otherwise, return 0.

sub get_limit {
    
    my ($tc, $key) = @_;
    
    return $tc->{max}{$key} if defined $key && defined $tc->{max}{$key};
    return $tc->{default_limit};
}


# expect_min ( condition => limit )
#
# Set the minimum number of times the specified condition must be flagged in order for
# ok_all to succeed. The default for every condition is zero. If you want to specify limits for
# more than one condition, you can pass in a hash ref whose keys are condition names and whose
# values are nonnegative integers.

sub expect_min {

    my ($tc, $condition, $limit) = @_;
    
    # If the first argument is a hashref, set the specified limit for every key. The key values
    # must be nonnegative integers.
    
    if ( ref $condition && reftype $condition eq 'HASH' )
    {
	croak "if the first argument is a hashref you may not specify a second one"
	    if defined $limit && $limit ne '';
	
	foreach my $key ( keys %$condition )
	{
	    croak "invalid condition key '$key'" unless $key ne '' && $key !~ /^\d+$/;
	    croak "the limit value for '$key' must be a nonnegative integer"
		unless defined $condition->{$key} && $condition->{$key} =~ /^\d+$/;
	    
	    $tc->{expect}{$key} = $condition->{$key};
	}
    }
    
    # Otherwise, the caller must pass a non-empty key and a non-negative integer value.
    
    else
    {
	$condition ||= '';
	croak "invalid condition key '$condition'" unless defined $condition && $condition ne '' && $condition !~ /^\d+$/;
	croak "the limit value must be a nonnegative integer" unless defined $limit && $limit =~ /^\d+$/;
	
	$tc->{expect}{$condition} = $limit;
    }
    
    # foreach my $k ( keys %expect )
    # {
    # 	croak "bad key '$k'" unless defined $k && $k ne '';
    # 	croak "odd number of arguments or undefined argument" unless defined $expect{$k};
    # 	croak "expect values must be nonnegative integers" unless $expect{$k} =~ /^\d+$/;
    # }
    
    # foreach my $k ( keys %expect )
    # {
    # 	$tc->{expect}{$k} = $expect{$k};
    # }
}


# expect ( key ... )
#
# The specified condition(s) must all be set in order for ok_all to succeed. This is equivalent to
# calling expect_min( key => 1 ) for each key.

sub expect {
    
    my ($tc, @expect) = @_;

    foreach my $key ( @expect )
    {
	next unless defined $key && $key ne '';
	$tc->expect_min($key, 1);
    }
    
    # my %e = map { $_ => 1 } @expect;
    
    # $tc->expect_min(\%e);
}


# get_expect ( key )
#
# If the specified condition is expected, return its minimum limit. Otherwise, return 0.

sub get_expect {
    
    my ($tc, $key) = @_;
    
    return $tc->{expect}{$key} if defined $key && defined $tc->{expect}{$key};
    return 0;
}


# set ( key )
#
# Set the specified condition. This will cause ok_all to fail unless the condition is expected.

sub set {
    
    my ($tc, $key) = @_;
    
    croak "you must specify a non-empty key" unless defined $key && $key ne '';
    
    # If the condition was previously set and subsequently tested, then reset all of the
    # attributes associated with this key.
    
    if ( $tc->{tested}{$key} )
    {
	delete $tc->{label}{$key};
	delete $tc->{count}{$key};
	delete $tc->{tested}{$key};
    }
    
    # Record that the condition indicated by this key has been set.
    
    $tc->{set}{$key} = 1;
}


# clear ( key )
#
# Clear the specified condition. This will cause ok_all to fail if the condition is expected. If
# the condition is not expected, then it will no longer cause ok_all to fail.

sub clear {
    
    my ($tc, $key) = @_;
    
    croak "you must specify a non-empty key" unless defined $key && $key ne '';
    
    # If the specified condition was previously tested, then reset that attribute.
    
    if ( $tc->{tested}{$key} )
    {
	delete $tc->{tested}{$key};
    }
    
    # Record that this condition has been cleared.
    
    $tc->{set}{$key} = 0;
    
    # Delete all of the other attributes associated with this key.
    
    delete $tc->{count}{$key};
    delete $tc->{label}{$key};
}


# flag ( key, [label] )
#
# This method sets the condition associated with the specified key, and also keeps track of how
# many times it has been called for each key. This provides more accurate information than just
# set/clear. If a label is specified, then it is stored and will later be reported when ok_all is
# called. Only the first label specified for a given key is recorded, but this allows the tester
# to find at least one item for which the condition was flagged.

sub flag {
    
    my ($tc, $key, $label) = @_;
    
    croak "you must specify a non-empty key" unless defined $key && $key ne '';
    
    # Set the specified condition, and also increment the count. If a label is specified, and if
    # no label has been recorded yet for this condition, then record it.
    
    $tc->set($key);
    
    $tc->{count}{$key}++;
    $tc->{label}{$key} = $label if ! defined $tc->{label}{$key} && defined $label && $label ne '';
}


# decrement ( key, [label] )
#
# This method reverses the effect of 'flag'. If the condition has previously been flagged, its
# count will be decremented. If the count reaches zero, the condition will be cleared. If a label
# is given and if it matches the label stored for this condition, then the stored label will be
# cleared.
#
# If the condition was set with 'set' but was never flagged, this method will have no effect.

sub decrement {
    
    my ($tc, $key, $label) = @_;
    
    croak "you must specify a non-empty key" unless defined $key && $key ne '';
    
    # If there is a non-zero count for this condition, decrement it. If the count reaches zero,
    # clear the condition but leave the count as '0'.
    
    if ( defined $tc->{count}{$key} && $tc->{count}{$key} > 0 )
    {
	$tc->{count}{$key}--;
	
	unless ( $tc->{count}{$key} )
	{
	    $tc->{set}{$key} = 0;
	    delete $tc->{label}{$key};
	}
    }
    
    # If a label was given and matches the stored label for this condition, then clear it.
    
    if ( defined $tc->{label}{$key} && defined $label && $tc->{label}{$key} eq $label )
    {
	delete $tc->{label}{$key};
    }
}


# active_conditions ( )
#
# Return a list of all keys which have been set but have not been tested.

sub active_conditions {

    my ($tc) = @_;
    
    return unless ref $tc->{set} eq 'HASH';
    return grep { ! $tc->{tested}{$_} && $tc->{set}{$_} } keys %{$tc->{set}};
}


# expected_conditions ( )
# 
# Return all keys which are currently expected.

sub expected_conditions {
    
    my ($tc) = @_;
    
    return unless ref $tc->{expect} eq 'HASH';
    return grep { $tc->{expect}{$_} } keys %{$tc->{expect}};
}


# all_conditions ( )
#
# Return all keys which have been set or cleared.

sub all_conditions {
    
    my ($tc) = @_;
    
    return unless ref $tc->{set} eq 'HASH';
    return grep { defined $tc->{set}{$_} } keys %{$tc->{set}};
}


# is_set ( key )
#
# Return 1 if the specified condition has been set, 0 if it has been cleared, and undefined if it
# has been neither set nor cleared.

sub is_set {
    
    my ($tc, $key) = @_;
    
    return $tc->{set}{$key};
}


# is_tested ( key )
#
# Return 1 if the specified condition has been tested, false otherwise.

sub is_tested {
    
    my ($tc, $key) = @_;
    
    return $tc->{tested}{$key};
}


# get_count ( key )
#
# Return the number of times this condition has been flagged, undef if it has never been flagged.

sub get_count {

    my ($tc, $key) = @_;
    
    return $tc->{count}{$key};
}


# get_label ( key )
#
# Return the label specified for this condition, or the empty string if there is none.

sub get_label {

    my ($tc, $key) = @_;
    
    return defined $tc->{label}{$key} ? $tc->{label}{$key} : '';
}


# ok_all ( message )
#
# This method generates a TAP event. If any unexpected conditions are set, or if any expected
# conditions are not set, then the event will be a failure. Otherwise, it will be a success. The
# specified message will be reported as the test name.
#
# Each condition that is checked as a result of this call will be marked as 'tested'. Subsequent
# calls to ok_all or ok_condition will disregard this condition, unless it is subsequently
# explicitly set or cleared again. However is_set, get_count, etc. will still return the proper
# results.

sub ok_all {

    my ($tc, $message) = @_;
    
    croak "you must specify a message" unless $message;
    
    # By incrementing the variable indicated below, the result of 'pass' or 'fail' will be
    # reported as occurring on the line in the test file from which this method was called.
    
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    
    my (@fail, @warn, %found);
    
    # Check each condition that was set but has not yet been tested.
    
 KEY:
    foreach my $k ( $tc->active_conditions )
    {
	my $count = $tc->get_count($k) || 0;
	my $limit = $tc->get_limit($k);
	my $expected = $tc->get_expect($k);
	my $label = $tc->get_label($k);
	
	# Mark that this condition has been tested.
	
	$tc->{tested}{$k} = 1;
	$found{$k} = 1;
	
	# If this condition is expected, then we can just skip to the next one. But if the minimum
	# limit was greater than one, then we fail unless the count matches or exceeds that
	# limit. And if there was a maximum limit specified, we fail if the count exceeds that.
	
	if ( $expected && ( $limit == 0 || $count <= $limit ) )
	{
	    next KEY if $expected == 1;
	    next KEY if defined $count && $count >= $expected;
	    
	    my $m = "    Condition '$k': flagged $count instance";
	    $m .= "s" if $count != 1;
	    $m .= ", expected at least $expected";
	    
	    push @fail, $m;
	}
	
	# Otherwise, this condition is not expected. If there is a limit and the count does not exceed
	# it, we add a warning message but do not fail.
	
	elsif ( $limit && $count <= $limit )
	{
	    my $m = "    Condition '$k': flagged $count instance";
	    $m .= "s" if $count > 1;
	    $m .= " [$label]" if defined $label & $label ne '';
	    $m .= " (limit $limit)" if $limit;
	    
	    push @warn, $m;
	}
	
	# If the limit was exceeded, or if no limit was specified, then the condition leads to a failure.
	
	elsif ( $count )
	{
	    my $m = "    Condition '$k': flagged $count instance";
	    $m .= "s" if $count > 1;
	    $m .= " [$label]" if defined $label & $label ne '';
	    $m .= " (limit $limit)" if $limit;
	    
	    push @fail, $m;
	}
	
	# If this condition was set rather than flagged, we generate a simple failure message.
	
	else
	{
	    push @fail, "    Condition '$k'";
	}
    }
    
    # Now go through the conditions we were expecting and fail if we didn't get all of them.
    
    foreach my $k ( $tc->expected_conditions )
    {
	unless ( $found{$k} )
	{
	    my $e = $tc->get_expect($k);
	    
	    if ( $e == 1 )
	    {
		push @fail, "    Condition '$k': not set";
	    }
	    
	    else
	    {
		push @fail, "    Condition '$k': found no instances, expected at least $e";
	    }
	}
    }
    
    # Now, if we have accumulated any failures then fail the entire test with the specified
    # message. Output the individual messages as diagnostics.
    
    if ( @fail )
    {
	ok($TEST_INVERT, $message);
	_diag($_) foreach @fail;
	
	if ( @warn )
	{
	    _diag("This test also generated the following warnings:");
	    _diag($_) foreach @warn;
	}
    }
    
    # If we have warnings but no failures, then we pass the test but emit the individual warnings
    # as diagnostics.
    
    elsif ( @warn )
    {
	ok(!$TEST_INVERT, $message);
	_diag("Passed test '$message' with warnings:");
	_diag($_) foreach @warn;
    }
    
    # Otherwise, we just pass the test.
    
    else
    {
	ok(!$TEST_INVERT, $message);
    }
}


# ok_condition ( key, message )
#
# This method generates a TAP event. If the specified condition was set, or if it was expected but
# not set, then the event will be a failure. Otherwise, it will be a success. The specified
# message will be reported as the test name.
# 
# The specified condition will be marked as 'tested'. Subsequent calls to ok_all or ok_condition
# will disregard this condition, unless it is subsequently explicitly set or cleared
# again. However is_set, get_count, etc. will still return the proper results.

sub ok_condition {

    my ($tc, $key, $message) = @_;
    
    croak "you must specify a message" unless $message;
    
    # By incrementing the variable indicated below, the result of 'pass' or 'fail' will be
    # reported as occurring on the line in the test file from which this method was called.
    
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    
    my $set = $tc->is_set($key);
    my $expected = $tc->get_expect($key);
    my $count = $tc->get_count($key) || 0;
    my $limit = $tc->get_limit($key);
    my $label = $tc->get_label($key);
    my $tested = $tc->is_tested($key);
    
    # If an expected condition has been tested, act as though it has not been set.
    
    $set = 0 if $tested;
    
    # Now mark this condition as having been tested.
    
    $tc->{tested}{$key} = 1;
    
    # If this condition is expected, then we succeed if it is set and fail if it is not. But if the
    # expected count is not met, then we fail anyway and add a diagnostic message.
    
    if ( $expected )
    {
	if ( $set && ( $expected == 1 || $count >= $expected ) && ( $limit == 0 || $count <= $limit ) )
	{
	    ok(!$TEST_INVERT, $message);
	}
	
	elsif ( $count > $limit )
	{
	    ok($TEST_INVERT, $message);
	    my $s = $count == 1 ? '' : 's';
	    _diag("    Condition '$key': flagged $count instance$s, limit $limit");
	}
	
	elsif ( $expected > 1 )
	{
	    ok($TEST_INVERT, $message);
	    my $s = $count == 1 ? '' : 's';
	    _diag("    Condition '$key': flagged $count instance$s, expected at least $expected");
	}
	
	else
	{
	    ok($TEST_INVERT, $message);
	}
    }
    
    # Otherwise, the condition is not expected. If is not set, then we pass.

    elsif ( ! $set )
    {
	ok(!$TEST_INVERT, $message);
    }
    
    # If the condition is set but there is a limit that was not exceeded, then we pass with a
    # warning message.
    
    elsif ( defined $count && defined $limit && $count <= $limit )
    {
	ok(!$TEST_INVERT, $message);
	
	my $m = "    Condition '$key': flagged $count instance";
	$m .= "s" if $count > 1;
	$m .= " [$label]" if defined $label & $label ne '';
	$m .= " (limit $limit)" if $limit;
	
	_diag($m);
    }
    
    # Otherwise, we fail. If there was a limit which was exceeded then we generate a diagnostic
    # message.
    
    else
    {
	ok($TEST_INVERT, $message);
	
	if ( $count && $limit )
	{
	    my $m = "    Condition '$key': flagged $count instance";
	    $m .= "s" if $count > 1;
	    $m .= " [$label]" if defined $label & $label ne '';
	    $m .= " (limit $limit)";
	    
	    _diag($m);
	}
    }
}


# _diag ( line )
#
# This subroutine allows for interception of diagnostic messages for the purpose of running unit
# tests on this module.

sub _diag {
    
    if ( $TEST_INVERT || $TEST_OUTPUT )
    {
	$TEST_DIAG .= "$_[0]\n";
    }

    else
    {
	goto &diag;
    }
}


# reset_conditions ( )
#
# Completely reset the status of every condition, but leave the limits in place so they can be
# used to test a different set of items.

sub reset_conditions {
    
    my ($tc) = @_;
    
    $tc->{set} = { };
    $tc->{label} = { };
    $tc->{count} = { };
    $tc->{tested} = { };
}


# reset_condition ( )
#
# Reset the status of the specified condition.

sub reset_condition {
    
    my ($tc, $key) = @_;
    
    croak "you must specify a non-empty key" unless defined $key && $key ne '';
    
    delete $tc->{set}{$key};
    delete $tc->{label}{$key};
    delete $tc->{count}{$key};
    delete $tc->{tested}{$key};
}


# reset_limits ( )
#
# Remove all limits that were set.

sub reset_limits {
    
    my ($tc) = @_;
    
    $tc->{max} = { };
}


# reset_expects ( )
#
# Remove all expects that were set.

sub reset_expects {
    
    my ($tc) = @_;
    
    $tc->{expect} = { };
}


=head1 NAME

Test::Conditions - test multiple conditions across a large data structure or list in a simple and compact way

=head1 VERSION

Version 0.8

=head1 SYNOPSIS

    $tc = Test::Conditions->new;
    
    foreach my $node ( @list )
    {
        $tc->flag('foo missing', $node->{name})
            unless defined $node->{foo};
        $tc->flag('bar missing', $node->{name})
            unless defined $node->{bar} && $node->{bar} > 0;
    }
    
    $tc->ok_all("all nodes have proper attributes");

=head1 DESCRIPTION

The purpose of this module is to facilitate testing complex data structures such as trees, lists
of hashes, results of database queries, etc. You may want to run certain tests on each node or
row, and report the results in a compact way.  You might, for example, wish to test a list or
other structure with 1,000 nodes and report the result as a single test rather than multiple
thousands of individual tests. This module provides a far more flexible approach than the
C<is_deeply> method of L<Test::More>.

An object of class Test::Conditions can keep track of any number of conditions, and reports a
single event when its C<ok_all> method is called. Under the most common usage, the test fails if
one or more conditions are flagged, and succeeds if none are.  Each condition which has been flagged
is reported as a separate diagnostic message.  Futhermore, if the nodes or other pieces of the
data structure have unique identifiers, you can easily arrange for Test::Conditions to report the
identifier of one of the failing nodes to help you in diagnosing the problem.

=head2 Conditions

Each separate condition that you wish to test is indicated by a key. This can be any non-empty
string that is not a number. You can L</"set"> or L</"clear"> any condition, and you can specify
whether or not this condition is expected to be set. After many set and/or clear operations, you
can execute a single test using L</"ok_all"> that will pass and fail depending on whether any
conditions are set.

=head3 Labels

Instead of just setting a condition, you can L</"flag"> it. This involves specifying some string (a
label) to indicate where in the data that you are testing this condition occurs. This could
represent a database key, or a node name or address, or anything else that will indicate useful
information about where the condition occurred. A condition can be flagged multiple times, and
will be reported only once. The first non-empty label that was flagged will be reported as well.

=head3 Positive and negative conditions

A condition can be a positive or a negative one, depending on whether it is expected or not. If
you specify that a particular condition is expected, then L</"ok_all"> will pass if that condition
has been set and fail if not. If a condition is not expected, then the situation is reversed.

=head1 METHODS

=head3 new

This class method creates a new Test::Conditions instance. This instance can then be used to
record whether some set of conditions has been set or cleared, and to execute a single test
encapsulating this result.

=head2 Setting and clearing of conditions

=head3 set ( key )

Sets the specified condition.  The single argument must be a scalar whose
value is the name (key) of the condition to be set.

=head3 clear ( key )

Clears the specified condition.  The single argument must be a scalar whose
value is the name (key) of the condition to be cleared.

=head3 flag ( key, [ label ] )

Sets the specified condition, and can also record an arbitrary label. This label can be any
non-empty string, but it is best to use some key value or node field that will indicate where in
the set of data being tested the condition occurred. The first non-empty label to be flagged for
any particular condition will be reported when a test fails due to that condition, so that you can
use that information for debugging purposes. The number of times each condition is flagged is also
recorded, and minimum and maximum limits can also be specified. See L</"limit_max"> and
L</"expect_min"> below.

In general, you will want to use either 'set' or 'flag' with any particular condition, and not
both. It is generally best to use 'set' for conditions that reflect a problem with the data
structure as a whole, and 'flag' for conditions that are specific to a particular piece of it.

=head3 decrement ( condition, [ label ] )

This method decrements the count of how many times the specified condition has been flagged. If a
label is specified, and if that label matches the label stored for this condition, it is
cleared. Basically, if this method is called immediately after L</"flag"> and with the same
arguments, the effect of the flag will be undone. This method only exists so that if 'flag' has
been called in error the effect can be reversed.

If a call to this method results in the count reaching zero, the condition is cleared.

=head3 expect ( condition... )

This method marks one or more conditions as B<expected>. Subsequently, L</"ok_all"> will fail unless
all of the expected conditions are set. This is how you specify positive conditions instead of negative
ones. For example:

    $tc = Test::Conditions->new;
    
    $tc->expect('found aaa', 'found bbb');
    
    foreach my $node ( @list )
    {
        $tc->flag('found aaa', $node->{name}) if $node->{key} eq 'aaa';
	$tc->flag('found bbb', $node->{name}) if $node->{key} eq 'bbb';
    }
    
    $tc->ok_all("found both keys");
    
    if ( $tc->is_set('found aaa') )
    {
	my $node_name = $tc->get_label('found aaa');
        diag("    Found key 'aaa' at node '$node_name'");
    }

You can use both positive (expected) and negative (non-expected) conditions together. A call to
L</"ok_all"> will succeed precisely when all of the expected conditions have been set and no
non-expected conditions have.

=head3 expect_min ( condition, n )

This method indicates that the specified condition is expected to be flagged at least I<n>
times. If it is flagged fewer times than that, or not at all, then L</"ok_all"> will fail. Calling
this method with a count of 1 is exactly the same as calling L</"expect"> on the same condition.

=head3 limit_max ( condition, n )

This method indicates that the specified condition should be flagged at most I<n> times. If it is
flagged more times than that, then L</"ok_all"> will fail. You can use this, for example, if you
expect a few nodes in your data structure to be missing particular fields but you want the test to fail
if more than a certain number are.

=head2 Testing

=head3 ok_all ( test_name )

This method will execute a single test, with the specified string as the test name. The test
will pass if all expected (positive) conditions are set, and if no non-expected (negative)
conditions are set.

If a negative condition was flagged rather than set, then a diagnostic message will be printed
indicating the label with which it was first flagged, and the total number of times it was
flagged. If you set these labels based on keys or node names or other indications of where in the
data structure is being tested, this can help you to figure out what is going wrong.

If a minimum and/or maximum limit has been set on a particular condition, then the test will
pass only if the number of times the condition was flagged does not fall outside of these limits.

All conditions that are tested by this method are marked as being tested. Subsequent calls to
'ok_all' or 'ok_condition' will ignore them, unless they have been explicitly set or cleared
afterward. However, methods such as 'is_set', 'get_count', etc. will still work on it.

=head3 ok_condition ( condition, test_name )

This method will test a single condition, and will pass or fail the specified test name. If the
condition is expected, then it will pass only if set. If it is not expected, then it will pass
only if not set.

If a minimum and/or maximum limit has been set on this condition, then the test will pass only if
the number of times the condition was flagged does not fall outside of these limits.

The condition that is tested by this method is marked as being tested. Subsequent calls to
'ok_all' or 'ok_condition' will ignore it, unless it has0 been explicitly set or cleared
afterward. However, methods such as 'is_set', 'get_count', etc. will still work on it.

=head2 Accessors 

The following methods can be used to check the status of any condition

=head3 is_set ( condition )

Returns 1 if the condition is set, 0 if it has been explicitly cleared, and I<undef> if it has
been neither set nor cleared.

=head3 is_tested ( condition )

Returns 1 if L</"ok_all"> or L</"ok_condition"> has been called on this condition, and it has not
been set or cleared since.

=head3 get_count ( condition )

Returns the number of times the condition has been flagged, or I<undef> if it has never been
flagged. 

=head3 get_label ( condition )

Returns the label stored for this condition, or I<undef> if it has never been flagged with a
non-empty label.

=head3 active_conditions ( )

Returns a list of all conditions that are currently set but have not yet been tested.

=head3 expected_conditions ( )

Returns a list of all conditions that are currently expected.

=head3 all_conditions ( )

Returns a list of all conditions that have been set or cleared, regardless of whether or not they
have been tested.

=head2 Resetting

If you have set up expected conditions and/or limits, you may wish to run the same
Test::Conditions instance on more than one data structure. Once you have run L</"ok_all"> on a
given instance, all of the active conditions are marked as "tested" and will be ignored from then
on unless subsequently set or cleared. So you can go ahead and use the same instance to test
multiple bodies of data and the results will be correct. It is okay to call 'ok_all' or
'ok_condition' as many times as needed. At each call, only the status of those conditions that
have been explicitly set or cleared since the last call will be considered.

If you wish to reset some or all conditions without calling 'ok_all' or 'ok_condition', you can use the
following methods:

=head3 reset_conditions ( )

This method resets the status of all conditions, as if they had never been set or cleared. Limits
and expects are preserved.

=head3 reset_condition ( condition )

This method resets the status of a single condition.

=head1 AUTHOR

Michael McClennen

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-conditions at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Conditions>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Michael McClennen.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
