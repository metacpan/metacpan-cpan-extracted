package MooseX::CustomInitArgs;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use 5.008;
use strict;
use warnings;
use Moose::Exporter;

use constant _AttrTrait => do
{
	package MooseX::CustomInitArgs::Trait::Attribute;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	
	use Moose::Role;
	use Moose::Util::TypeConstraints;
	use B 'perlstring';
	
	subtype 'OptList', as 'ArrayRef[ArrayRef]';
	coerce 'OptList',
		from 'ArrayRef' => via {
			require Data::OptList;
			Data::OptList::mkopt $_;
		},
		from 'HashRef' => via {
			my $hash = $_;
			[ map { [ $_ => $hash->{$_} ] } sort keys %$hash ];
		};
	
	has init_args => (
		is        => 'ro',
		isa       => 'OptList',
		predicate => 'has_init_args',
		coerce    => 1,
	);
	
	has _init_args_hashref => (
		is        => 'ro',
		isa       => 'HashRef',
		lazy      => 1,
		default   => sub {
			my $self = shift;
			+{ map { ;$_->[0] => $_->[1] } @{$self->init_args} };
		},
	);
	
	around new => sub
	{
		my $orig  = shift;
		my $class = shift;
		my $self  = $class->$orig(@_);
		
		if ($self->has_init_args and not $self->has_init_arg)
		{
			confess "Attribute ${\$self->name} defined with init_args but no init_arg";
		}
		
		return $self;
	};
	
	sub _inline_param_negotiation
	{
		my ($self, $param) = @_;
		my $init = $self->init_arg;
		
		my $regex        = join '|', map quotemeta, $self->init_arg, map $_->[0], @{$self->init_args||[]};
		my $with_coderef = join '|', map quotemeta, map $_->[0], grep {  defined($_->[1]) } @{$self->init_args||[]};
		my $no_coderef   = join '|', map quotemeta, map $_->[0], grep { !defined($_->[1]) } @{$self->init_args||[]};
		
		return (
			"if (my \@supplied = grep /^(?:$regex)\$/, keys \%${param}) {",
			'  if (@supplied > 1) {',
			'    Carp::confess("Conflicting init_args (@{[join q(, ), sort @supplied]})");',
			'  }',
			"  elsif (grep /^(?:$no_coderef)\$/, \@supplied) { ",
			"    ${param}->{${\perlstring $self->init_arg}} = delete ${param}->{\$supplied[0]};",
			"  }",
			"  elsif (grep /^($with_coderef)\$/, \@supplied) { ",
			"    my \$x = delete ${param}->{\$supplied[0]};",
			"    ${param}->{${\perlstring $self->init_arg}} = \$MxCIA_attrs{${\$self->name}}->_run_init_coderef(\$supplied[0], \$class, \$x);",
			"  }",
			"}",
		);
	}
	
	sub _run_init_coderef
	{
		my ($self, $arg, $class, $value) = @_;
		
		my $code = $self->_init_args_hashref->{$arg};
		ref $code eq 'SCALAR' and $code = $$code;
		
		if (ref $code eq "MooseX::CustomInitArgs::Sub::AfterTC")
		{
			if ($self->should_coerce) {
				$value = $self->type_constraint->assert_coerce($value);
			}
			else {
				$self->type_constraint->assert_valid($value);
			}
		}
		
		local $_ = $value;
		$class->$code($value);
	}
	
	around initialize_instance_slot => sub
	{
		my $orig = shift;
		my $self = shift;
		my ($meta_instance, $instance, $params) = @_;
		
		$self->has_init_args
			or return $self->$orig(@_);
		
		my @supplied = grep { exists $params->{$_->[0]} } @{$self->init_args}
			or return $self->$orig(@_);
		
		if (exists $params->{$self->init_arg})
		{
			push @supplied, [ $self->init_arg => undef ];
		}
		
		if (@supplied > 1)
		{
			confess sprintf(
				'Conflicting init_args (%s)',
				join(', ', sort map $_->[0], @supplied)
			);
		}
		
		if ($supplied[0][1])
		{
			$self->_set_initial_slot_value(
				$meta_instance,
				$instance,
				$self->_run_init_coderef($supplied[0][0], $instance, delete $params->{ $supplied[0][0] }),
			);
		}
		else
		{
			$self->_set_initial_slot_value(
				$meta_instance,
				$instance,
				delete $params->{$supplied[0][0]},
			);
		}
		
		return;
	};
	
	__PACKAGE__;
};

use constant _ClassTrait => do
{
	package MooseX::CustomInitArgs::Trait::Class;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	
	use Moose::Role;
	
	has _mxcia_hash => (
		is      => 'ro',
		isa     => 'HashRef',
		lazy    => 1,
		builder => '_build__mxcia_hash',
	);
	
	sub _build__mxcia_hash
	{
		my $self = shift;
		return +{
			map  { ;$_->name => $_ }
			grep { ;$_->can('does') && $_->does(MooseX::CustomInitArgs->_AttrTrait) }
			$self->get_all_attributes
		};
	}
	
	around _eval_environment => sub
	{
		my $orig = shift;
		my $self = shift;
		my $eval = $self->$orig(@_);
		$eval->{'%MxCIA_attrs'} = $self->_mxcia_hash;
		return $eval;
	};
	
	around _inline_slot_initializer => sub
	{
		my $orig = shift;
		my $self = shift;
		my ($attr, $idx) = @_;
		
		return $self->$orig(@_)
			unless $attr->can('does')
			&&     $attr->does(MooseX::CustomInitArgs->_AttrTrait)
			&&     $attr->has_init_args;
		
		return (
			$attr->_inline_param_negotiation('$params'),
			$self->$orig(@_),
		);
	};
	
	__PACKAGE__;
};

use constant _ApplicationTrait => do
{
	package MooseX::CustomInitArgs::Trait::Application;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	
	use Moose::Role;

	around apply => sub
	{
		my $orig = shift;
		my $self = shift;
		my ($role, $applied_to) = @_;
		$applied_to = Moose::Util::MetaRole::apply_metaroles(
			for             => $applied_to->name,
			class_metaroles => {
				class                => [ MooseX::CustomInitArgs->_ClassTrait ],
			},
			role_metaroles  => {
				application_to_class => [ MooseX::CustomInitArgs->_ApplicationTrait ],
				application_to_role  => [ MooseX::CustomInitArgs->_ApplicationTrait ],
			},
		);
		$self->$orig($role, $applied_to);
	};
	
	__PACKAGE__;
};

sub after_typecheck (&) {
	bless $_[0], "MooseX::CustomInitArgs::Sub::AfterTC";
}

sub before_typecheck (&) { $_[0] }

Moose::Exporter->setup_import_methods(
	as_is => [
		qw( before_typecheck after_typecheck )
	],
	class_metaroles => {
		class     => [ _ClassTrait ],
		attribute => [ _AttrTrait ],
	},
	role_metaroles => {
		application_to_class => [ _ApplicationTrait ],
		application_to_role  => [ _ApplicationTrait ],
		applied_attribute    => [ _AttrTrait ],
	},
);

1;

__END__

=head1 NAME

MooseX::CustomInitArgs - define multiple init args with custom processing

=head1 SYNOPSIS

   package Circle {
      use Moose;
      use MooseX::CustomInitArgs;
      
      has radius => (
         is        => 'ro',
         isa       => 'Num',
         required  => 1,
         init_args => [
            'r',
            'diameter' => sub { $_ / 2 },
         ],
      );
   }
   
   # All three are equivalent...
   my $circle = Circle->new(radius => 1);
   my $circle = Circle->new(r => 1);
   my $circle = Circle->new(diameter => 2);

=head1 DESCRIPTION

C<MooseX::CustomInitArgs> allows Moose attributes to be initialized from
alternative initialization arguments. If you find yourself wishing that
Moose's built-in C<init_arg> option took an arrayref, then this is what
you want.

L<MooseX::MultiInitArg> also does this, but C<MooseX::CustomInitArgs> has
an additional feature: it can optionally pre-process each initialization
argument. This happens prior to type coercian and constraint checks.

(Also at the time of writing, C<MooseX::MultiInitArg> suffers from a bug
where it breaks when a class is immutablized.)

The constructor cannot be called with multiple initialization arguments
for the same attribute. Given the class in the example, this would throw
an error:

   my $circle = Circle->new(radius => 1, diameter => 100);

The following would also throw an error, even though it's slightly more
sensible:

   my $circle = Circle->new(radius => 1, diameter => 2);

The C<init_args> attribute option is conceptually a hash mapping
initialization argument names to methods which pre-process them. The methods
can be given as coderefs, or the names of class methods as strings (or scalar
refs).

You can provide this hash mapping as an actual hashref, or (as in the
L</SYNOPSIS>) as an arrayref suitable for input to L<Data::OptList>. In either
case it will be coerced to C<MooseX::CustomInitArgs>'s internal representation
which is a C<Data::OptList>-style arrayref of arrayrefs.

=head2 Interaction with type constraints and coercion

=begin trustme

=item before_typecheck

=item after_typecheck

=end trustme

Normally, custom init arg coderefs run I<before> the value has been through
type constraint checks and coercions. This allows the coderef to massage
the value into passing its type constraint checks.

However, if you wish to run type constraint checks before the coderef,
use the C<after_typecheck> helper:

   init_args => [
      'r',
      'diameter' => after_typecheck { $_ / 2 },
   ],

(There's a corresponding C<before_typecheck> helper for clarity.)

After the coderef has been run, type constraint checks and coercions will
happen I<again> on the result.

=head1 CAVEATS

C<init_args> cannot be used on attributes with C<< init_arg => undef >>.
C<MooseX::CustomInitArgs> will throw an error if you do.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-CustomInitArgs>.

=head1 SEE ALSO

L<MooseX::MultiInitArg>, L<MooseX::FunkyAttributes>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

