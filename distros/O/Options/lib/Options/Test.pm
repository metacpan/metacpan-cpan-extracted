#!/usr/bin/env perl

##################################################################
# TestOptions.pm
# 
# Tests for the Options.pm perl module
# 
# Copyright (C) 2005-2007 by Phil Christensen
##################################################################

use strict;
use warnings;

use Options;
package Options::Test;
use base qw(Test::Unit::TestCase);

sub new {
	my $self = shift()->SUPER::new(@_);
	return $self;
}

sub set_up {
	my $self = shift;
	$self->{'options'} = new Options(params => [
							['port', 'p', undef, 'The port to connect to.'],
							['host', 'h', 'localhost', 'The host to connect to.']
							],
							flags =>  [
							['secure', 's', 'Use SSL for encryption.'],
							['quit', 'q', 'Quit after connecting.']
							]);
	
	$self->{'options'}->{'exit'} = undef;
	
	$self->{'options'}->{'usage_fh_variable'} = '';
	open STRINGIO, '+>', \$self->{'options'}->{'usage_fh_variable'} or die $!;
	$self->{'options'}->{'usage_fh'} = \*STRINGIO;
}

sub tear_down {
	my $self = shift;
	close($self->{'options'}->{'usage_fh'});
	$self->{'options'} = undef;
}

sub test_simple {
	my $self = shift;
	my @args = ('options.t', '--port', '8080');
	my %result = $self->{'options'}->get_options(@args);
	
	$self->assert_equals('localhost', $result{'host'}, "Didn't get back correct 'host' value");
	$self->assert_equals('8080', $result{'port'}, "Didn't get back correct 'port' value");
	$self->assert_null($result{'something'}, 'Secure should not have been found.');
}

sub test_group_flags {
	my $self = shift;
	my @args = ('options.t', '--port', '8080', '-sq');
	my %result = $self->{'options'}->get_options(@args);
	
	$self->assert($result{'secure'}, "'secure' was not selected properly");
	$self->assert($result{'quit'}, "'quit' was not selected properly");
}

sub test_broken_group_flags {
	my $self = shift;
	my @args = ('options.t', '--port', '8080', '-sqh');
	
	my %result = eval{
		my %results = $self->{'options'}->get_options(@args);
	};

	$self->assert_not_null($@, 'Improperly grouped parameter did not kill the script.');
	$self->assert_not_equals('', $self->{'options'}->{'usage_fh_variable'},
					"No usage information found after improperly grouped parameter.");
}

sub test_broken_group_flags2 {
	my $self = shift;
	my @args = ('options.t', '--port', '8080', '-sqx');
	
	my %result = eval{
		return $self->{'options'}->get_options(@args);
	};

	my $usage_fh = $self->{'options'}->{'usage_fh'};
	seek($usage_fh, 0, 0);
	my @usage = <$usage_fh>;
	my $usage = join("\n", @usage);
	
	$self->assert_not_null($@, 'Unknown grouped flag did not kill the script.');
	$self->assert_not_equals('', $usage, "No usage information found after unknown grouped flag.");
}

sub test_required {
	my $self = shift;
	my @args = ('options.t');
	
	my %result = eval{
		return $self->{'options'}->get_options(@args);
	};
	
	my $usage_fh = $self->{'options'}->{'usage_fh'};
	seek($usage_fh, 0, 0);
	my @usage = <$usage_fh>;
	my $usage = join("\n", @usage);
	
	$self->assert_null($result{'host'}, "Shouldn't have gotten a 'host' value.");
	$self->assert_null($result{'secure'}, "Shouldn't have gotten a 'secure' value.");
	$self->assert_not_null($@, 'Missing required options did not kill the script.');
	$self->assert_not_equals('', $usage, "No usage information found after missing required argument.");
}

sub test_handler {
	my $self = shift;
	my @args = ('options.t', '-s', '-h', 'somehost');
	
	$self->{'options'}->{'error_handler'} = sub {
		return 1;
	};
	
	my %result = eval{
		return $self->{'options'}->get_options(@args);
	};
	
	$self->assert_equals('somehost', $result{'host'}, "Didn't get back correct 'host' value");
	$self->assert($result{'secure'}, "'secure' was not selected properly");
	# I don't know why this doesn't come back null here:
	#$self->assert_null($@, "Custom handler failed, missing required options killed the script.");
	$self->assert_equals("$@", '', "Custom handler failed, missing required options killed the script.");
}

1;