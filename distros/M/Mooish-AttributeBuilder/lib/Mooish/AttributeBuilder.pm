package Mooish::AttributeBuilder;
$Mooish::AttributeBuilder::VERSION = '1.000';
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

	my $extended_name;
	if (ref $name eq 'ARRAY') {
		$extended_name = [map { "+$_" } @{$name}];
	}
	else {
		$extended_name = "+$name";
	}

	return ($extended_name, expand_shortcuts($name, %args));
}

# Helpers - not part of the interface

sub check_and_replace
{
	my ($hash_ref, $name, $key, $value) = @_;

	croak "Could not expand shortcut: $key already exists for $name"
		if exists $hash_ref->{$key};

	$hash_ref->{$key} = $value;
}

sub get_normalized_name
{
	my ($name, $for) = @_;

	croak "Could not use attribute shortcut with array fields: $for is not supported"
		if ref $name;

	$name =~ s/^_//;
	return $name;
}

sub expand_method_names
{
	my ($name, %args) = @_;

	# initialized lazily
	my $normalized_name;
	my $protected_field;

	# inflate names from shortcuts
	for my $method_type (keys %METHOD_PREFIXES) {
		next unless defined $args{$method_type};
		next if ref $args{$method_type};
		next unless grep { $_ eq $args{$method_type} } '1', -public, -hidden;

		$normalized_name //= get_normalized_name($name, $method_type);
		$protected_field //= $name ne $normalized_name;

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

sub expand_shortcuts
{
	my ($name, %args) = @_;

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

	# method names from shortcuts
	%args = expand_method_names($name, %args);

	# literal parameters (prepended with -)
	for my $literal (keys %args) {
		if ($literal =~ m{\A - (.+) \z}x) {
			$args{$1} = delete $args{$literal};
		}
	}

	return %args;
}

1;

# ABSTRACT: build Mooish attribute definitions with less boilerplate

