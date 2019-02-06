# PiFlash::Hook - named dispatch/hook library for PiFlash
# by Ian Kluft

use strict;
use warnings;
use v5.18.0; # require 2014 or newer version of Perl
use PiFlash::State;

package PiFlash::Hook;
$PiFlash::Hook::VERSION = '0.0.6';
use Carp qw(confess);
use autodie; # report errors instead of silently continuing ("die" actions are used as exceptions - caught & reported)

# ABSTRACT: named dispatch/hook library for PiFlash


# initialize hooks hash as empty
## no critic (ProhibitPackageVars)
our %hooks;
## use critic

# use AUTOLOAD to call a named hook as if it were a class method
our $AUTOLOAD;
sub AUTOLOAD {
	my $self = shift;

	# Remove qualifier from original method name...
	my $called =  $AUTOLOAD =~ s/.*:://r;

	# differentiate between class and instance methods
	if (defined $self and ref $self eq "PiFlash::Hook") {
		# handle instance accessor
		# if likely to be used a lot, optimize this by creating accessor function upon first access
		if (exists $self->{$called}) {
			return $self->{$called};
		}
		return;
	} else {
		# handle class methods

		# Is there a hook of that name?
		if (!exists $hooks{$called}) {
			if (PiFlash::State::verbose()) {
				say "PiFlash::Hook dispatch: no such hook $called - ignored";
			}
			return;
		}

		# call all functions registered in the list for this hook
		my @result;
		if (ref $hooks{$called} eq "ARRAY") {
			foreach my $hook (@{$hooks{$called}}) {
				my @hook_return = $hook->run();
				push @result, [@hook_return];
			}
		}
		return @result;
	}
}

# add a code reference to a named hook
sub add
{
	my $name = shift;
	my $coderef = shift;
	if (ref $coderef ne "CODE") {
		confess "PiFlash::Hook::add_hook(): can't add $name hook with non-code reference";
	}
	if (!exists $hooks{$name}) {
		$hooks{$name} = [];
	}
	push @{$hooks{$name}}, PiFlash::Hook::new({name => $name, code => $coderef, origin => [caller]});
}

# new() - internal function to instantiate hook object, should be called from add() with coderef & caller parameters
sub new
{
	my $class = shift;
	my $params = shift;

	my $self = {};
	bless $self, $class;

	# initialize
	foreach my $key (keys %$params) {
		$self->{$key} = $params->{$key};
	}
	my @missing;
	foreach my $required ("name", "code", "origin") {
		exists $self->{$required} or push @missing, $required;
	}
	if (@missing) {
		confess "PiFlash::Hook::new() missing required parameters: ".join(" ", @missing);
	}

	return $self;
}

# run the hook code
sub run
{
	# TODO
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PiFlash::Hook - named dispatch/hook library for PiFlash

=head1 VERSION

version 0.0.6

=head1 SYNOPSIS

 PiFlash::Hook::add( "hook1", sub { ... code ... });
 PiFlash::Hook::hook1();
 PiFlash::Hook::add( "hook2", \&function_name);
 PiFlash::Hook::hook2();

=head1 DESCRIPTION

=head1 SEE ALSO

L<piflash>, L<PiFlash::Command>, L<PiFlash::Inspector>, L<PiFlash::MediaWriter>, L<PiFlash::State>

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
