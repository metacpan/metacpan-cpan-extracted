# Copyright (C) 2006, David Muir Sharnoff <muir@idiom.com>

package Plugins::API;

use strict;
use warnings;
use Scalar::Util qw(weaken refaddr);
use Carp qw(cluck confess);

our $VERSION = 0.3;
our $debug = 0;
our $AUTOLOAD;

my $debug_disable = 0;
my $debug_register = 0;

sub new
{
	my $pkg = shift;
	my $flags = ref($_[0]) 
		? shift
		: undef;
	my $self = bless {
		api			=> {},
		handlers		=> {},
		disabled		=> {},
		enabled			=> {},
		handler_class		=> 'Plugins::API::Handler',
	}, $pkg;
	$self->{default_handler} = $self->can('callhandler') or die;
	confess "odd # of elements in @_"
		if @_ % 2 == 1;
	$self->api(@_) if @_;
	return $self unless $flags;
	if ($flags->{autoregister}) {
		$self->autoregister($flags->{autoregister});
	}
	if ($flags->{plugins}) {
		$self->{plugins} = $flags->{plugins};
		weaken($self->{plugins});
	}
	return $self;
}

sub api
{
	my ($self, %api) = @_;
	for my $callback (keys %api) {
		my $v = $api{$callback};
		$v = {} unless ref $v;
		unless ($self->{api}{$callback} && ! $api{$callback}->{override_api}) {
			print "API: $callback ($self)\n" if $debug_register;
			$self->{api}{$callback} = $v;
		}
	}
	return $self->{api};
}

sub autoregister
{
	my ($self, $caller) = @_;
	$caller = caller() unless $caller;
	print STDERR "AUTOREGISTER $caller\n" if $debug_register;
	for my $callback (keys %{$self->{api}}) {
		print STDERR "? $callback\n" if $debug_register;
		my $cref;
		if (($cref = $caller->can($callback))) {
			print STDERR "Autoregister $caller: $callback\n" if $debug_register;
			push(@{$self->{handlers}{$callback}}, $self->newhandler($caller, $cref));
		}
	}
	$self->{enabled} = {};
}

sub register
{
	my $self = shift;
	my $caller = shift;
	my $options = {};
	if (ref $_[0]) {
		$options = shift;
	}
	my (%handlers) = @_;
	for my $callback (keys %handlers) {
		my $handler = $self->newhandler($caller, $handlers{$callback});
		if ($options->{first}) {
			unshift(@{$self->{handlers}{$callback}}, $handler);
		} elsif ($options->{replace}) {
			@{$self->{handlers}{$callback}} = ($handler);
		} else {
			push(@{$self->{handlers}{$callback}}, $handler);
		}
	}
	$self->{enabled} = {};
}

sub newhandler
{
	my ($self, $caller, $cref) = @_;
	my $handler = bless [ $caller, $cref ], $self->{handler_class};
	weaken($handler->[0])
		if ref $caller;
	return $handler;
}

sub handlers
{
	my ($self, $callback) = @_;
	my $api = $self->{api}{$callback};
	my $found;
	my $handlers;
	if ($self->{plugins}) {
		for my $plugin ($self->{plugins}->plugins) {
			my $f = $plugin->can($callback);
			next unless $f;
			$found = 1;
			next if $self->{disabled}{refaddr($plugin)};
			next if $self->{disabled}{ref($plugin)};
			printf STDERR "Not disabled: %s / %s / %s\n", $plugin, refaddr($plugin), ref($plugin) if $debug_disable;
			push(@$handlers, $self->newhandler($plugin, $f));
		}
	}
	unless ($self->{handlers}{$callback} || $found) {
		unless ($api) {
			cluck "Call to unregistered api: '$callback'";
			return;
		}
		unless ($api->{optional}) {
			cluck "No handler for call to '$callback'";
			return;
		}
	}
	if ($self->{enabled}{$callback}) {
		$handlers = $self->{enabled}{$callback};
	} else {
		for my $h (@{$self->{handlers}{$callback}}) {
			my $obj = $h->object;
			next if ref($obj) && ($self->{disabled}{ref($obj)} || $self->{disabled}{refaddr($obj)}); 
			printf STDERR "Not disabled: %s / %s / %s\n", $obj, refaddr($obj), ref($obj) if $debug_disable && ref($obj);
			push(@$handlers, $h);
		}
		$self->{enabled}{$callback} = $handlers;
	}
	print STDERR "HANDLERS: ".join(", ",map { refaddr($_) } @$handlers), "\n" if $debug_disable;
	return $handlers;
}

sub invoke
{
	my ($self, $callback, @args) = @_;
	my $api = $self->{api}{$callback};
	my $handlers = $self->handlers($callback);
	my $callhandler = ($api && $api->{callhandler}) 
		? $api->{callhandler}
		: $self->{default_handler};
	return &$callhandler($self, $callback, $api, \@args, $handlers);
}

sub callhandler
{
	my ($self, $callback, $api, $args, $handlers) = @_;
	my @rrr;
	my @rr;
	my @r;
	for my $handler (@$handlers) {
		if ($api->{first_only}) {
			return $handler->call(@$args);
		}
		if (wantarray) {
			@r = $handler->call(@$args);
		} else {
			$r[0] = $handler->call(@$args);
		}
		return $r[0] if defined($r[0]) and $api->{first_defined};
		if ($api->{exit_test}) {
			my $t = $api->{exit_test};
			my ($q, @rv) = &$t(\@r, \@rr, \@rrr, wantarray);
			return @rv if $q;
		}
		push(@rr, \@r);
		push(@rrr, @r);
	}
	return @rrr if $api->{combine_returns};
	return @rr if $api->{array_return};
	return @r if wantarray;
	return $r[0];
}

sub disable
{
	my ($self, $plugin) = @_;
	my $addr = ref($plugin)
		? refaddr($plugin)
		: $plugin;
	print STDERR "Disabling $addr\n" if $debug_disable;
	$self->{disabled}{$addr} = caller;
	$self->{enabled} = {};
}

sub plugins
{
	my ($self, $plugins) = @_;
	my $old = $self->{plugins};
	$self->{plugins} = $plugins if @_ > 1;
	return $old;
}

sub DESTROY {}

sub AUTOLOAD
{
	my $self = shift;

	my $auto = $AUTOLOAD;
	my $ref = ref($self);
	my $p = __PACKAGE__;
	$auto =~ s/^${ref}::// or $auto =~ s/^${p}:://;
	if ($self->{plugins} || $self->{api}{$auto} || $self->{handlers}{$auto}) {
		return $self->invoke($auto, @_);
	}
	cluck "No api or handler for '$auto'";
}

package Plugins::API::Handler;

use strict;
use warnings;
use Carp;

sub call
{
	my ($self, @args) = @_;
	my (@obj) = $self->[0] || ();
	my $method = $self->[1];
	&$method(@obj, @args);
}

sub object
{
	my $self = shift;
	$self->[0] or ();
}

sub method
{
	my $self = shift;
	return $self->[1];
}


1;
