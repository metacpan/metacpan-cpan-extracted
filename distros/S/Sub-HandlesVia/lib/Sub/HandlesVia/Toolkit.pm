use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.036';

use Sub::HandlesVia::Mite;

use Type::Params qw(compile_named_oo);
use Types::Standard qw( ArrayRef HashRef Str Num Int CodeRef Bool Item );
use Types::Standard qw( assert_HashRef is_ArrayRef is_CodeRef is_Str );

my $sig;
sub install_delegations {
	$sig ||= compile_named_oo(
		target      => Str,
		attribute   => ArrayRef->of(Str|CodeRef)->plus_coercions(Str|CodeRef, '[$_]'),
		handles_via => ArrayRef->of(Str)->plus_coercions(Str, '[$_]'),
		handles     => HashRef->plus_coercions(ArrayRef, '+{map(+($_,$_),@$_)}'),
	);
	
	my $me = shift;
	my $arg = &$sig;

	my $gen = $me->code_generator_for_attribute(
		$arg->target,
		$arg->attribute,
	);
	
	use Sub::HandlesVia::Handler;
	my %handles = %{ $arg->handles };
	for my $h (sort keys %handles) {
		
		my $handler = 'Sub::HandlesVia::Handler'->lookup(
			$handles{$h},
			$arg->handles_via,
		);
		
		$handler->install_method(
			method_name    => $h,
			code_generator => $gen,
		);
	}
}

my %native = qw(
	Array           1
	Bool            1
	Code            1
	Counter         1
	Hash            1
	Number          1
	Scalar          1
	String          1
);

sub known_handler_libraries {
	sort keys %native;
}

my %default_type = (
	Array     => ArrayRef,
	Hash      => HashRef,
	String    => Str,
	Number    => Num,
	Counter   => Int,
	Code      => CodeRef,
	Bool      => Bool,
	Scalar    => Item,
);

sub clean_spec {
	my ($me, $target, $attr, $spec) = (shift, @_);

	delete $spec->{no_inline};

	# Clean our stuff out of traits list...
	if (ref $spec->{traits} and not $spec->{handles_via}) {
		my @keep = grep !$native{$_}, @{$spec->{traits}};
		my @cull = grep  $native{$_}, @{$spec->{traits}};
		delete $spec->{traits};
		if (@keep) {
			$spec->{traits} = \@keep;
		}
		if (@cull) {
			$spec->{handles_via} = \@cull;
		}
	}

	return unless $spec->{handles_via};
	
	my @handles_via = ref($spec->{handles_via}) ? @{$spec->{handles_via}} : $spec->{handles_via};
	my $joined      = join('|', @handles_via);

	if ($default_type{$joined} and not exists $spec->{isa}) {
		$spec->{isa}    = $default_type{$joined};
		$spec->{coerce} = 1 if $default_type{$joined}->has_coercion;
	}
	
	$spec->{handles} = { map +($_ => $_), @{ $spec->{handles} } }
		if is_ArrayRef $spec->{handles};
	assert_HashRef $spec->{handles};

	return {
		target       => $target,
		attribute    => $attr,
		handles_via  => delete($spec->{handles_via}),
		handles      => delete($spec->{handles}),
	};
}

sub code_generator_for_attribute {
	my ($me, $target, $attr) = (shift, @_);
	
	my ($get_slot, $set_slot, $default) = @$attr;
	$set_slot = $get_slot if @$attr < 2;
	
	my $captures = {};
	my ($get, $set, $slot, $get_is_lvalue) = (undef, undef, undef, 0);
	
	require B;
	
	if (ref $get_slot) {
		$get = sub { shift->generate_self . '->$shv_reader' };
		$captures->{'$shv_reader'} = \$get_slot;
	}
	elsif ($get_slot =~ /\A \[ ([0-9]+) \] \z/sx) {
		my $index = $1;
		$get = sub { shift->generate_self . "->[$index]" };
		$slot = $get;
		++$get_is_lvalue;
	}
	elsif ($get_slot =~ /\A \{ (.+) \} \z/sx) {
		my $key = B::perlstring($1);
		$get = sub { shift->generate_self . "->{$key}" };
		$slot = $get;
		++$get_is_lvalue;
	}
	else {
		my $method = B::perlstring($get_slot);
		$get = sub { shift->generate_self . "->\${\\ $method}" };
	}
	
	if (ref $set_slot) {
		$set = sub {
			my ($gen, $val) = @_;
			$gen->generate_self . "->\$shv_writer($val)";
		};
		$captures->{'$shv_writer'} = \$set_slot;
	}
	elsif ($set_slot =~ /\A \[ ([0-9]+) \] \z/sx) {
		my $index = $1;
		$set = sub {
			my ($gen, $val) = @_;
			my $self = $gen->generate_self;
			"($self\->[$index] = $val)";
		};
	}
	elsif ($set_slot =~ /\A \{ (.+) \} \z/sx) {
		my $key = B::perlstring($1);
		$set = sub {
			my ($gen, $val) = @_;
			my $self = $gen->generate_self;
			"($self\->{$key} = $val)";
		};
	}
	else {
		my $method = B::perlstring($set_slot);
		$set = sub {
			my ($gen, $val) = @_;
			my $self = $gen->generate_self;
			"$self\->\${\\ $method}($val)";
		};
	}
	
	if (is_CodeRef $default) {
		$captures->{'$shv_default_for_reset'} = \$default;
	}

	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		toolkit               => $me,
		target                => $target,
		attribute             => $attr,
		env                   => $captures,
		coerce                => !!0,
		generator_for_get     => $get,
		generator_for_set     => $set,
		get_is_lvalue         => $get_is_lvalue,
		set_checks_isa        => !!1,
		set_strictly          => !!1,
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			if ( !$default and $handler ) {
				return $handler->default_for_reset->();
			}
			elsif ( is_CodeRef $default ) {
				return sprintf(
					'(%s)->$shv_default_for_reset',
					$gen->generate_self,
				);
			}
			elsif ( is_Str $default ) {
				require B;
				return sprintf(
					'(%s)->${\ %s }',
					$gen->generate_self,
					B::perlstring( $default ),
				);
			}
			return;
		},
		( $slot ? ( generator_for_slot => $slot ) : () ),
	);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::HandlesVia::Toolkit - integration with OO frameworks for Sub::HandlesVia

=head1 DESCRIPTION

B<< This module is part of Sub::HandlesVia's internal API. >>
It is mostly of interest to people extending Sub::HandlesVia.

Detect what subclass of Sub::HandlesVia::Toolkit is suitable for a class:

  my $toolkit = Sub::HandlesVia->detect_toolkit($class);

Extract handles_via information from a C<has> attribute spec hash:

  my $shvdata = $toolkit->clean_spec($class, $attrname, \%spec);

This not only returns the data that Sub::HandlesVia needs, it also cleans
C<< %spec >> so that it can be passed to a Moose-like C<has> function
without it complaining about unrecognized options.

  $toolkit->install_delegations($shvdata) if $shvdata;

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-handlesvia/issues>.

=head1 SEE ALSO

L<Sub::HandlesVia>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020, 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

