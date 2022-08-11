package Mooish::AttributeBuilder;
$Mooish::AttributeBuilder::VERSION = '0.001';
use v5.10;
use strict;
use warnings;

use Exporter qw(import);
use Carp qw(croak);
use Scalar::Util qw(blessed);

our @EXPORT = qw(
	field
	param
	option
	extended
);

our $PROTECTED_PREFIX = '';
our %PROTECTED_METHODS = map { $_ => 1 } qw(builder trigger);
our %METHOD_PREFIXES = (
	reader => 'get',
	writer => 'set',
	clearer => 'clear',
	predicate => 'has',
	builder => 'build',
	trigger => 'trigger',
	init_arg => undef,
);

sub field
{
	my ($name, %args) = @_;

	%args = (
		is => 'ro',
		init_arg => undef,
		%args,
	);

	return ($name, expand_shortcuts($name, %args));
}

sub param
{
	my ($name, %args) = @_;

	%args = (
		is => 'ro',
		required => 1,
		%args,
	);

	return ($name, expand_shortcuts($name, %args));
}

sub option
{
	my ($name, %args) = @_;

	return param $name,
		required => 0,
		predicate => 1,
		%args;
}

sub extended
{
	my ($name, %args) = @_;

	return ("+$name", expand_shortcuts($name, %args));
}

# Helpers - not part of the interface

sub check_and_replace
{
	my ($hash_ref, $name, $key, $value) = @_;

	croak "$key already exists for $name"
		if exists $hash_ref->{$key};

	$hash_ref->{$key} = $value;
}

sub expand_shortcuts
{
	my ($name, %args) = @_;
	my $normalized_name = $name;
	$normalized_name =~ s/^_//;

	my $protected_field = $name ne $normalized_name;

	# merge lazy + default / lazy + builder
	if ($args{lazy}) {
		my $lazy = $args{lazy};
		$args{lazy} = 1;

		if (ref $lazy eq 'CODE') {
			check_and_replace \%args, $name, default => $lazy;
		}
		else {
			check_and_replace \%args, $name, builder => $lazy;
		}
	}

	# merge coerce + isa
	if (blessed $args{coerce}) {
		check_and_replace \%args, $name, isa => $args{coerce};
		$args{coerce} = 1;
	}

	# make sure params with defaults are not required
	if ($args{required} && (exists $args{default} || $args{builder})) {
		delete $args{required};
	}

	# inflate names from shortcuts
	for my $method_type (keys %METHOD_PREFIXES) {
		next unless defined $args{$method_type};
		next if ref $args{$method_type};
		next unless grep { $_ eq $args{$method_type} } '1', -public, -hidden;

		my $is_protected =
			$args{$method_type} eq -hidden
			|| (
				$args{$method_type} eq '1'
				&& ($protected_field || $PROTECTED_METHODS{$method_type})
			);

		$args{$method_type} = join '_', grep { defined }
			($is_protected ? $PROTECTED_PREFIX : undef),
			$METHOD_PREFIXES{$method_type},
			$normalized_name;
	}

	# special treatment for trigger
	if ($args{trigger} && !ref $args{trigger}) {
		my $trigger = $args{trigger};
		$args{trigger} = sub {
			return shift->$trigger(@_);
		};
	}

	return %args;
}

1;

# ABSTRACT: build Mooish attribute definitions with less boilerplate

