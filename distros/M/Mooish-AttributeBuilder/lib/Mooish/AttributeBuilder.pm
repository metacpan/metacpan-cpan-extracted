package Mooish::AttributeBuilder;
$Mooish::AttributeBuilder::VERSION = '1.002';
use v5.10;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);

my $set_subname;
BEGIN {
	if (eval { require Sub::Util } && Sub::Util->VERSION >= 1.40) {
		$set_subname = \&Sub::Util::set_subname;
	}
}

### These subs can be extended in subclasses

# List of available attribute types. May be extended if a custom function will
# call expand_shortcuts
sub attribute_types
{
	return {
		field => {
			is => 'ro',
			init_arg => undef,
		},
		param => {
			is => 'ro',
			required => 1,
		},
		option => {
			is => 'ro',
			required => 0,
			predicate => 1,
		},
		extended => {},
	};
}

# Prefix of hidden methods. Will be joined with the rest of the method name
# with an underscore, so an empty prefix means starting with an underscore
sub hidden_prefix
{
	return '';
}

# The list of methods which are hidden by default
sub hidden_methods
{
	return {
		builder => 1,
		trigger => 1,
	};
}

# The list of method name prefixes. Undef means no prefix at all, just use
# attribute name
sub method_prefixes
{
	return {
		reader => 'get',
		writer => 'set',
		clearer => 'clear',
		predicate => 'has',
		builder => 'build',
		trigger => 'trigger',
		init_arg => undef,
	};
}

### General functions called in sub context

sub import
{
	my ($self, $caller) = (shift, scalar caller);
	state $export_cache = {};

	my %flags = map { $_ => $_ } @_;

	my $cache_key = $self . ($flags{-standard} || '');
	foreach my $type (keys %{$self->attribute_types}) {
		my $function = $export_cache->{$cache_key . $type} //= sub {
			my ($name, %args) = @_;
			return $self->expand_shortcuts($flags{-standard}, $type => $name, %args);
		};

		$set_subname->("${self}::${type}", $function)
			if $set_subname;

		NO_STRICT: {
			no strict 'refs';
			*{"${caller}::${type}"} = $function;
		}
	}
}

my @custom_shortcuts;

sub custom_shortcuts
{
	return [@custom_shortcuts];
}

sub add_shortcut
{
	my ($sub) = @_;

	croak 'Custom shortcut passed to add_shortcut must be a coderef'
		unless ref $sub eq 'CODE';

	push @custom_shortcuts, $sub;
	return;
}

sub standard_shortcuts
{
	my ($self) = @_;

	return [
		# expand attribute type
		sub {
			my ($name, %args) = @_;
			my $type = delete $args{_type};

			if ($type && $self->attribute_types->{$type}) {
				%args = (
					%{$self->attribute_types->{$type}},
					%args,
				);
			}

			return %args;
		},

		# merge lazy + default / lazy + builder
		sub {
			my ($name, %args) = @_;

			if ($args{lazy}) {
				my $lazy = $args{lazy};
				$args{lazy} = 1;

				if (ref $lazy eq 'CODE') {
					check_and_set(\%args, $name, default => $lazy);
				}
				else {
					check_and_set(\%args, $name, builder => $lazy);
				}
			}

			return %args;
		},

		# merge coerce + isa
		sub {
			my ($name, %args) = @_;

			if (blessed $args{coerce}) {
				check_and_set(\%args, $name, isa => $args{coerce});
				$args{coerce} = 1;
			}

			return %args;
		},

		# make sure params with defaults are not required
		sub {
			my ($name, %args) = @_;

			if ($args{required} && (exists $args{default} || $args{builder})) {
				delete $args{required};
			}

			return %args;
		},

		# method names from shortcuts
		sub {
			my ($name, %args) = @_;

			# initialized lazily
			my $normalized_name;
			my $hidden_field;

			# inflate names from shortcuts
			my %prefixes = %{$self->method_prefixes};
			foreach my $method_type (keys %prefixes) {
				next unless defined $args{$method_type};
				next if ref $args{$method_type};
				next unless grep { $_ eq $args{$method_type} } '1', -public, -hidden;

				$normalized_name //= get_normalized_name($name, $method_type);
				$hidden_field //= $name ne $normalized_name;

				my $is_hidden =
					$args{$method_type} eq -hidden
					|| (
						$args{$method_type} eq '1'
						&& ($hidden_field || $self->hidden_methods->{$method_type})
					);

				$args{$method_type} = join '_', grep { defined }
					($is_hidden ? $self->hidden_prefix : undef),
					$prefixes{$method_type},
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
		},

		# literal parameters (prepended with -)
		sub {
			my ($name, %args) = @_;

			foreach my $literal (keys %args) {
				if ($literal =~ m{\A - (.+) \z}x) {
					$args{$1} = delete $args{$literal};
				}
			}

			return %args;
		},
	];
}

sub expand_shortcuts
{
	my ($self, $standard, $attribute_type, $name, %args) = @_;

	$args{_type} = $attribute_type;

	# NOTE: don't use custom shortcuts if we stick to the standard
	my @filters;
	push @filters, @{$self->custom_shortcuts} unless $standard;
	push @filters, @{$self->standard_shortcuts};

	# NOTE: builtin shortcuts are executed after custom shortcuts
	foreach my $sub (@filters) {
		%args = $sub->($name, %args);
	}

	# TODO: dirty hack for 'extended' attribute. Can be done better?
	if ($attribute_type eq 'extended') {
		if (ref $name eq 'ARRAY') {
			$name = [map { "+$_" } @{$name}];
		}
		else {
			$name = "+$name";
		}
	}

	return ($name, %args);
}

### Helpers - not called in pkg context

sub check_and_set
{
	my ($hash_ref, $name, %pairs) = @_;

	foreach my $key (keys %pairs) {
		croak "Could not expand shortcut: $key already exists for $name"
			if exists $hash_ref->{$key};

		$hash_ref->{$key} = $pairs{$key};
	}

	return;
}

sub get_normalized_name
{
	my ($name, $for) = @_;

	croak "Could not use attribute shortcut with array fields: $for is not supported"
		if ref $name;

	$name =~ s/^_//;
	return $name;
}

1;

# ABSTRACT: build Mooish attribute definitions with less boilerplate

