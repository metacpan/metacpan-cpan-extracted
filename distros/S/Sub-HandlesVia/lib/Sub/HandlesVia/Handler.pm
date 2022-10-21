use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Handler;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.038';

use Sub::HandlesVia::Mite -all;

has name => (
	is => ro,
	isa => 'Str',
);

has template => (
	is => ro,
	isa => 'Str',
);

has lvalue_template => (
	is => ro,
	isa => 'Str',
);

has args => (
	is => ro,
	isa => 'Int|Undef',
	default => undef,
);

has [ 'min_args', 'max_args' ] => (
	is => lazy,
	isa => 'Int|Undef',
	builder => sub { shift->args },
);

# Not proper predicates because they check definedness
sub has_min_args { defined shift->min_args }
sub has_max_args { defined shift->max_args }

has signature => (
	is => ro,
	isa => 'ArrayRef|Undef',
);

has usage => (
	is => lazy,
	isa => 'Str',
	builder => true,
);

has curried => (
	is => ro,
	isa => 'ArrayRef',
);

has [ 'is_chainable', 'no_validation_needed' ] => (
	is => ro,
	isa => 'Bool',
	coerce => true,
);

has is_mutator => (
	is => lazy,
	isa => 'Bool',
	coerce => true,
	default => sub { defined $_[0]{lvalue_template} or $_[0]{template} =~ /«/ }
);

has allow_getter_shortcuts => (
	is => ro,
	isa => 'Bool',
	coerce => true,
	default => true,
);

has prefer_shift_self => (
	is => ro,
	isa => 'Bool',
	coerce => true,
	default => false,
);

has additional_validation => (
	is => ro,
	isa => 'CodeRef|Str|Undef',
);

has default_for_reset => (
	is => ro,
	isa => 'CodeRef',
);

has documentation => (
	is => ro,
	isa => 'Str',
);

has _examples => (
	is => ro,
	isa => 'CodeRef',
);

sub _build_usage {
	no warnings 'uninitialized';
	my $self = shift;
	if ($self->has_max_args and $self->max_args==0) {
		return '';
	}
	elsif ($self->min_args==0 and $self->max_args==1) {
		return '$arg?';
	}
	elsif ($self->min_args==1 and $self->max_args==1) {
		return '$arg';
	}
	elsif ($self->min_args > 0 and $self->max_args > 0) {
		return sprintf('@min_%d_max_%d_args', $self->min_args, $self->max_args);
	}
	elsif ($self->max_args > 0) {
		return sprintf('@max_%d_args', $self->max_args);
	}
	return '@args';
}

sub curry {
	my ($self, @curried) = @_;
	if ($self->has_max_args and @curried > $self->max_args) {
		die "too many arguments to curry";
	}
	my %copy = %$self;
	delete $copy{usage};
	ref($self)->new(
		%copy,
		name         => sprintf('%s[curried]', $self->name),
		max_args     => $self->has_max_args ? $self->max_args - @curried : undef,
		min_args     => $self->has_min_args ? $self->min_args - @curried : undef,
		signature    => $self->signature ? do { my @sig = @{$self->{signature}}; splice(@sig,0,scalar(@curried)); \@sig } : undef,
		curried      => \@curried,
	);
}

sub loose {
	my $self = shift;
	ref($self)->new(%$self, signature => undef);
}

sub chainable {
	my $self = shift;
	ref($self)->new(%$self, is_chainable => 1);
}

sub _real_additional_validation {
	my $me = shift;
	my $av = $me->additional_validation;
	return $av if ref $av;
	
	my ($lib) = split /:/, $me->name;
	return sub {
		my $self = shift;
		my ($sig_was_checked, $callbacks) = @_;
		my $ti = "Sub::HandlesVia::HandlerLibrary::$lib"->_type_inspector($callbacks->{isa});
		if ($ti and $ti->{trust_mutated} eq 'always') {
			return { code => '1;', env => {} };
		}
		if ($ti and $ti->{trust_mutated} eq 'maybe') {
			return { code => '1;', env => {} };
		}
		return;
	} if $av eq 'no incoming values';

	return;
}

sub lookup {
	my $class = shift;
	my ($method, $traits) = map { ref($_) eq 'ARRAY' ? $_ : [$_] } @_;
	my ($method_name, @curry) = @$method;
	
	my $handler;
	my $make_chainable = 0;
	my $make_loose = 0;

	if (ref $method_name eq 'CODE') {
		$handler = Sub::HandlesVia::Handler::CodeRef->new(
			name              => '__ANON__',
			delegated_coderef => $method_name,
		);
	}
	else {
		if ($method_name =~ /\s*\.\.\.$/) {
			$method_name =~ s/\s*\.\.\.$//;
			++$make_chainable;
		}
		if ($method_name =~ /^\~\s*/) {
			$method_name =~ s/^\~\s*//;
			++$make_loose;
		}
		if ($method_name =~ /^(.+?)\s*\-\>\s*(.+?)$/) {
			$traits = [$1];
			$method_name = $2;
		}
	}
	
	if (not $handler) {
		SEARCH: for my $trait (@$traits) {
			my $class = $trait =~ /:/
				? $trait
				: "Sub::HandlesVia::HandlerLibrary::$trait";
			if ( $class ne $trait ) {
				local $@;
				eval "require $class; 1"
					or warn $@;
			}
			if ($class->isa('Sub::HandlesVia::HandlerLibrary') and $class->can($method_name)) {
				$handler = $class->$method_name;
			}
		}
	}
	
	if (not $handler) {
		$handler = Sub::HandlesVia::Handler::Traditional->new(name => $method_name);
	}
	
	$handler = $handler->curry(@curry)   if @curry;
	$handler = $handler->loose           if $make_loose;
	$handler = $handler->chainable       if $make_chainable;
	
	return $handler;
}

sub install_method {
	my ( $self, %arg ) = @_;
	my $gen = $arg{code_generator} or die;
	
	$gen->generate_and_install_method( $arg{method_name}, $self );
	
	return;
}

sub code_as_string {
	my ($self, %arg ) = @_;
	my $gen = $arg{code_generator} or die;

	my $eval = $gen->_generate_ec_args_for_handler( $arg{method_name}, $self );
	my $code = join "\n", @{$eval->{source}};
	if ($arg{method_name}) {
		$code =~ s/sub/sub $arg{method_name}/xs;
	}
	if (eval { require Perl::Tidy }) {
		my $tidy = '';
		Perl::Tidy::perltidy(
			source      => \$code,
			destination => \$tidy,
		);
		$code = $tidy;
	}
	$code;
}

sub _tweak_env {}

use Exporter::Shiny qw( handler );
sub _generate_handler {
	my $me = shift;
	return sub {
		my (%args) = @_%2 ? (template=>@_) : @_;
		$me->new(%args);
	};
}

package Sub::HandlesVia::Handler::Traditional;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.038';

use Sub::HandlesVia::Mite -all;
extends 'Sub::HandlesVia::Handler';

has '+name' => ( required => true );

sub is_mutator { 0 }

sub template {
	my $self = shift;
	require B;
	my $q_name = B::perlstring( $self->name );
	return sprintf(
		'$GET->${\\ '.$q_name.'}( @ARG )',
	);
}

package Sub::HandlesVia::Handler::CodeRef;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.038';

use Sub::HandlesVia::Mite -all;
extends 'Sub::HandlesVia::Handler';

has delegated_coderef => (
	is => 'ro',
	isa => 'CodeRef',
	required => true,
);

sub is_mutator { 0 }

sub BUILD {
	$_[1]{delegated_coderef} or die 'delegated_coderef required';
}

sub _tweak_env {
	my ( $self, $env ) = @_;
	$env->{'$shv_callback'} = \($self->delegated_coderef);
}

sub template {
	return '$shv_callback->(my $shvtmp = $GET, @ARG)';
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::HandlesVia::Handler - template for a method that can be delegated to

=head1 DESCRIPTION

B<< This module is part of Sub::HandlesVia's internal API. >>
It is mostly of interest to people extending Sub::HandlesVia.

This module works in conjunction with L<Sub::HandlesVia::CodeGenerator>
and subclasses of L<Sub::HandlesVia::Toolkit> to build a string of Perl
code which can be compiled into a method to install into your class.

=head1 CONSTRUCTORS

=head2 C<< new( %attributes ) >>

Standard Moose-like constructor.

=head2 C<< lookup( $method, $trait ) >>

Looks up a method from existing handler libraries.

  my $h = Sub::HandlesVia::Handler->lookup( 'get', 'Array' );

Curried version:

  my $h = Sub::HandlesVia::Handler->lookup( [ 'get', 0 ], 'Array' );

The C<< $trait >> may be an arrayref of possible traits.

=head1 EXPORTS

Nothing is exported by default.

=head2 C<< handler %attributes >>

Shortcut for the C<new> constructor.

  use Sub::HandlesVia::Handler 'handler';
  
  my $h = handler( %attr );
  # is the same as
  my $h = Sub::HandlesVia::Handler->new( %attr );

=head1 ATTRIBUTES

=head2 C<< name >> B<< Str >>

The name of the function being delegated to.

=head2 C<< is_mutator >> B<Bool>

Indicates whether this handler might mutate an attribute value.
The default is to try to detect it based on analysis of the templates.

=head2 C<< template >> B<< Str >>

Specially formatted string (see section below) containing the Perl code
to implement the method.

=head2 C<< lvalue_template >> B<< Maybe[Str] >>

If defined, a shortcut for implementing it when the attribute slot
value can be used as an lvalue.

=head2 C<< args >> B<< Maybe[PositiveOrZeroInt] >>

The number of arguments which the method being generated expects
(does not include the attibute value itself).

=head2 C<< min_args >> and C<< max_args >> B<< Maybe[PositiveOrZeroInt] >>

For methods which take a variable number of arguments. If omitted, default
to C<args>.

=head2 C<< signature >> B<< Maybe[ArrayRef[TypeTiny]] >>

A signature for said arguments.

=head2 C<< usage >> B<< Str >>

A signature to show in documentation, like C<< '$index, $value' >>.
If not provided, will be generated magically from C<args>, C<min_args>,
and C<max_args>.

=head2 C<< curried >> B<< Maybe[ArrayRef[Item]] >>

An arrayref of curried arguments.

=head2 C<< is_chainable >> B<Bool>

Whether to force the generated method to be chainable.

=head2 C<< no_validation_needed >> B<Bool>

Whether to do less validation of input data.

=head2 C<< default_for_reset >> B<< Maybe[Str] >>

If this handler has to "reset" an attribute value to its default,
and the attribute doesn't have a default, this string of Perl code
is evaluated to provide a default. An example might be C<< "[]" >>.

=head2 C<< prefer_shift_self >> B<Bool>

Indicates this handler would prefer the code generator to shift
C<< $self >> off C<< @_ >>.

=head2 C<< documentation >> B<< Maybe[Str] >>

String of pod to describe the handler.

=head2 C<< _examples >> B<< Maybe[CodeRef] >>

This coderef, if called with parameters C<< $class >>, C<< $attr >>, and
C<< $method >>, will generate a code example to insert into the pod.

=head2 C<< additional_validation >> B<< Maybe[CodeRef] >>

Coderef providing a slightly annoying API. To be described later.

=head2 C<< allow_getter_shortcuts >> B<Bool>

Defaults to true. Rarely useful to override.

=head1 METHODS

=head2 C<< has_min_args() >> and C<< has_max_args() >>

Indicate whether this handler has a defined min or max args.

=head2 C<< install_method( %args ) >>

The required arguments are C<method_name> and C<code_generator>.
Installs the delegated method into the target class (taken from
the code generator).

=head2 C<< code_as_string( %args ) >>

Same required arguments as C<install_method>, but returns the Perl
code for the method as a string.

=head2 C<< curry( @args ) >>

Pseudo-constructor.

Creates a new Sub::HandlesVia::Handler object like this one, but
with the given arguments curried.

=head2 C<< loose >>

Pseudo-constructor.

Creates a new Sub::HandlesVia::Handler object like this one, but
with looser argument validation.

=head2 C<< chainable >>

Pseudo-constructor.

Creates a new Sub::HandlesVia::Handler object like this one, but
chainable.

=head1 TEMPLATE FORMAT

The template is a string of Perl code, except if the following special
things are found in it, they are substituted.

=over

=item C<< $SELF >>

The invocant.

=item C<< $SLOT >>

Direct hashref access for the attribute.

=item C<< $GET >>

The current value of the attribute.

=item C<< @ARG >>

Any additional arguments passed to the delegated method.

C<< $ARG[$n] >> will also work.

=item C<< #ARG >>

The number of additional arguments passed to the delegated method.

=item C<< $ARG >>

The first element in C<< @ARG >>.

=item C<< $DEFAULT >>

The attribute's default value, if known.

=item C<< « EXPR » >>

An expression in double angled quotes sets the attribute's value to the
expression.

=back

For example, a handler to halve the value of a numeric attribute might be:

  'Sub::HandlesVia::Handler'->new(
    name => 'MyNumber:halve',
    args => 0,
    template => '« $GET / 2 »',
    lvalue_template => '$GET /= 2',
  );

=head1 SUBCLASSES

Sub::HandlesVia::Handler::Traditional and Sub::HandlesVia::Handler::CodeRef
are provided. See source code for this module for more info.

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

