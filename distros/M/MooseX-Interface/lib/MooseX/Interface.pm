use 5.010;
use strict;
use warnings;
use utf8;
use Moose::Exporter 0 ();
use Moose::Role 2.00 ();
use Moose::Util 0 ();
use Moose::Util::MetaRole 0 ();
use constant 1.01 ();
use Class::Load 0 ();

{
	package MooseX::Interface;
	
	BEGIN {
		$MooseX::Interface::AUTHORITY = 'cpan:TOBYINK';
		$MooseX::Interface::VERSION   = '0.008';
		
		*requires = \&Moose::Role::requires;
		*excludes = \&Moose::Role::excludes;
	}
	
	sub test_case (&;$)
	{
		Class::MOP::class_of( (scalar caller)[0] )->add_test_case(@_);
	}
	
	sub const
	{
		my ($meta, $name, $value) = @_;
		$meta->add_constant($name, $value);
	}
	
	sub extends
	{
		my ($meta, $other) = @_;
		Class::Load::load_class($other);
		confess("Tried to extent $other, but $other is not an interface; died")
			unless $other->meta->can('is_interface') && $other->meta->is_interface;
		Moose::Util::ensure_all_roles($meta->name, $other);
	}
	
	sub one ()
	{
		my $meta = shift || Class::MOP::class_of( (scalar caller)[0] );
		$meta->check_interface_integrity;
		return 1;
	}
	
	my ($import, $unimport) = Moose::Exporter->build_import_methods(
		with_meta => [qw( extends excludes const requires one )],
		as_is     => [qw( test_case )],
	);
	
	sub unimport
	{
		goto $unimport;
	}
	
	sub import
	{
#		my $caller = caller;
#		Hook::AfterRuntime::after_runtime {
#			$caller->meta->check_interface_integrity;
#		};
		goto $import;
	}

	sub init_meta
	{
		my $class   = shift;
		my %options = @_;
		
		my $iface = $options{for_class};
		Moose::Role->init_meta(%options);
		
		Moose::Util::MetaRole::apply_metaroles(
			for            => $iface,
			role_metaroles => {
				role => ['MooseX::Interface::Trait::Role'],
			}
		);
		
		Class::MOP::class_of($iface)->is_interface(1);
	}
}

{
	package MooseX::Interface::Meta::Method::Constant;
	use Moose;
	extends 'Moose::Meta::Method';
	
	BEGIN {
		$MooseX::Interface::Meta::Method::Constant::AUTHORITY = 'cpan:TOBYINK';
		$MooseX::Interface::Meta::Method::Constant::VERSION   = '0.008';
	}
}

{
	package MooseX::Interface::Meta::Method::Required;
	use Moose;
	extends 'Moose::Meta::Role::Method::Required';
	
	BEGIN {
		$MooseX::Interface::Meta::Method::Required::AUTHORITY = 'cpan:TOBYINK';
		$MooseX::Interface::Meta::Method::Required::VERSION   = '0.008';
	}
}

{
	package MooseX::Interface::Meta::Method::Required::WithSignature;
	use Moose;
	use Moose::Util::TypeConstraints ();
	extends 'MooseX::Interface::Meta::Method::Required';
	
	BEGIN {
		$MooseX::Interface::Meta::Method::Required::WithSignature::AUTHORITY = 'cpan:TOBYINK';
		$MooseX::Interface::Meta::Method::Required::WithSignature::VERSION   = '0.008';
	}
	
	has signature => (
		is       => 'ro',
		isa      => 'ArrayRef',
		required => 1,
	);
	
	sub check_signature
	{
		my ($meta, $args) = @_;
		my $sig = $meta->signature;
		
		for my $i (0 .. $#{$sig})
		{
			my $tc = Moose::Util::TypeConstraints::find_type_constraint($sig->[$i]);
			return 0 unless $tc->check($args->[$i]);
		}
		
		return 1;
	}
}

{
	package MooseX::Interface::Meta::TestReport;
	use Moose;
	use namespace::clean;
	
	BEGIN {
		$MooseX::Interface::Meta::TestReport::AUTHORITY = 'cpan:TOBYINK';
		$MooseX::Interface::Meta::TestReport::VERSION   = '0.008';
	}
	
	use overload
		q[bool]  => sub { my $self = shift; !scalar(@{ $self->failed }) },
		q[0+]    => sub { my $self = shift;  scalar(@{ $self->failed }) },
		q[""]    => sub { my $self = shift;  scalar(@{ $self->failed }) ? 'not ok' : 'ok' },
		q[@{}]   => sub { my $self = shift;            $self->failed    },
		fallback => 1,
	;
	
	has [qw/ passed failed /] => (
		is        => 'ro',
		isa       => 'ArrayRef',
		required  => 1,
	);
}

{
	package MooseX::Interface::Meta::TestCase;
	use Moose;
	use namespace::clean;
	
	BEGIN {
		$MooseX::Interface::Meta::TestCase::AUTHORITY = 'cpan:TOBYINK';
		$MooseX::Interface::Meta::TestCase::VERSION   = '0.008';
	}
	
	has name => (
		is        => 'ro',
		isa       => 'Str',
		required  => 1,
	);
	
	has code => (
		is        => 'ro',
		isa       => 'CodeRef',
		required  => 1,
	);
	
	has associated_interface => (
		is        => 'ro',
		isa       => 'Object',
		predicate => 'has_associated_interface',
	);
	
	sub test_instance
	{
		my ($self, $instance) = @_;
		local $_ = $instance;
		$self->code->(@_);
	}
}

{
	package MooseX::Interface::Trait::Role;
	use Moose::Role;
	use namespace::clean;
	use overload ();
	
	BEGIN {
		$MooseX::Interface::Trait::Role::AUTHORITY = 'cpan:TOBYINK';
		$MooseX::Interface::Trait::Role::VERSION   = '0.008';
	}
	
	requires qw(
		name
		calculate_all_roles
		get_method_list
		add_method
		add_required_methods
		get_after_method_modifiers_map
		get_before_method_modifiers_map
		get_around_method_modifiers_map
		get_override_method_modifiers_map
	);
	
	has is_interface => (
		is      => 'rw',
		isa     => 'Bool',
		default => 0,
	);
	
	has test_cases => (
		is      => 'ro',
		isa     => 'ArrayRef[MooseX::Interface::Meta::TestCase]',
		default => sub { [] },
	);
	
	has integrity_checked => (
		is      => 'rw',
		isa     => 'Bool',
		default => 0,
	);
	
	has installed_modifiers => (
		is      => 'ro',
		isa     => 'HashRef[Int]',
		default => sub { +{} },
	);
	
	before apply => sub
	{
		my $meta = shift;
		$meta->check_interface_integrity
			unless $meta->integrity_checked;
	};
	
	around add_required_methods => sub 
	{
		my $orig = shift;
		my $meta = shift;
		my @required;
		
		while (@_)
		{
			my $meth = shift;
			my $sign = ( ref $_[0] or not defined $_[0] ) ? shift : undef;
			push @required, $sign
				? 'MooseX::Interface::Meta::Method::Required::WithSignature'->new(name => $meth, signature => $sign)
				: 'MooseX::Interface::Meta::Method::Required'->new(name => $meth)
		}
		
		foreach my $r (@required)
		{
			next unless $r->can('check_signature');
			
			my $modifier = sub {
				my ($self, @args) = @_;
				$r->check_signature(\@args) or die sprintf(
					"method call '%s' on object %s did not conform to signature defined in interface %s",
					$r->name,
					overload::StrVal($self),
					$meta->name,
				);
			};
			
			$meta->installed_modifiers->{$r->name} = Scalar::Util::refaddr($modifier);
			$meta->add_before_method_modifier($r->name, $modifier);
		}
		
		return $meta->$orig(@required);
	};
	
	sub add_constant
	{
		my ($meta, $name, $value) = @_;
		$meta->add_method(
			$name => 'MooseX::Interface::Meta::Method::Constant'->wrap(
				sub () { $value },
				name         => $name,
				package_name => $meta->name,
			),
		);
	}
	
	sub add_test_case
	{
		my ($meta, $coderef, $name) = @_;
		if (blessed $coderef)
		{
			push @{ $meta->test_cases }, $coderef;
		}
		else
		{
			$name //= sprintf("%s test case %d", $meta->name, 1 + @{ $meta->test_cases });
			push @{ $meta->test_cases }, 'MooseX::Interface::Meta::TestCase'->new(
				name                 => $name,
				code                 => $coderef,
				associated_interface => $meta,
			);
		}
	}
	
	sub test_implementation
	{
		my ($meta, $instance) = @_;
		confess("Parameter is not an object that implements the interface; died")
			unless blessed($instance) && $instance->DOES($meta->name);
		
		my @cases = map {
			$_->can('test_cases') ? @{$_->test_cases} : ()
		} $meta->calculate_all_roles;
		
		my (@failed, @passed);
		foreach my $case (@cases)
		{
			$case->test_instance($instance)
				? push(@passed, $case)
				: push(@failed, $case)
		}
		
		return 'MooseX::Interface::Meta::TestReport'->new(
			failed => \@failed,
			passed => \@passed,
		);
	}
	
	sub find_problematic_methods
	{
		my $meta = shift;
		my @problems;
		
		foreach my $m ($meta->get_method_list)
		{
			# These shouldn't show up anyway.
			next if $m =~ qr(isa|can|DOES|VERSION|AUTHORITY);
			
			my $M = $meta->get_method($m);
			
			# skip Interface->meta (that's allowed!)
			next if $M->isa('Moose::Meta::Method::Meta');
			
			# skip constants defined by constant.pm
			next if $constant::declared{ $M->fully_qualified_name };
			
			# skip constants defined by MooseX::Interface
			next if $M->isa('MooseX::Interface::Meta::Method::Constant');
			
			push @problems, $m;
		}
		
		return @problems;
	}

	sub find_problematic_method_modifiers
	{
		my $meta = shift;
		my @problems;
		
		foreach my $type (qw( after around before override ))
		{
			my $has = "get_${type}_method_modifiers_map";
			my $map = $meta->$has;
			foreach my $subname (sort keys %$map)
			{
				if (
					$type eq 'before' &&
					defined $meta->installed_modifiers->{$subname}
				) {
					# It would be nice to check the refaddr of the
					# modifier was the one we created, but Moose
					# seems to wrap it or something.
					#
					next;
				}
				push @problems, "$type($subname)";
			}
		}
		
		return @problems;
	}

	sub check_interface_integrity
	{
		my $meta = shift;
		
		my @checks = (
			[ find_problematic_methods           => 'Method' ],
			[ find_problematic_method_modifiers  => 'Method modifier' ],
		);
		
		while (my ($check_method, $check_text) = @{ +shift(@checks) || [] })
		{
			if (my @problems = $meta->$check_method)
			{
				my $iface    = $meta->name;
				my $problems = Moose::Util::english_list(@problems);
				my $s        = (@problems==1 ? '' : 's');
				
				confess(
					"${check_text}${s} defined within interface ${iface} ".
					"(try Moose::Role instead): ${problems}; died"
				);
			}
		}
		
		$meta->integrity_checked(1);
	}
}

1;

__END__

=head1 NAME

MooseX::Interface - Java-style interfaces for Moose

=head1 SYNOPSIS

  package DatabaseAPI::ReadOnly
  {
    use MooseX::Interface;
    requires 'select';
    one;
  }
  
  package DatabaseAPI::ReadWrite
  {
    use MooseX::Interface;
    extends 'DatabaseAPI::ReadOnly';
    requires 'insert';
    requires 'update';
    requires 'delete';
    one;
  }
  
  package Database::MySQL
  {
    use Moose;
    with 'DatabaseAPI::ReadWrite';
    sub insert { ... }
    sub select { ... }
    sub update { ... }
    sub delete { ... }
  }
  
  Database::MySQL::->DOES('DatabaseAPI::ReadOnly');   # true
  Database::MySQL::->DOES('DatabaseAPI::ReadWrite');  # true

=head1 DESCRIPTION

MooseX::Interface provides something similar to the concept of interfaces
as found in many object-oriented programming languages like Java and PHP.

"What?!" I hear you cry, "can't this already be done in Moose using roles?"

Indeed it can, and that's precisely how MooseX::Interface works. Interfaces
are just roles with a few additional restrictions: 

=over

=item * You may not define any methods within an interface, except:

=over

=item * Moose's built-in C<meta> method, which will be defined for you;

=item * You may override methods from L<UNIVERSAL>; and

=item * You may define constants using the L<constant> pragma.

=back

=item * You may not define any attributes. (Attributes generate methods.)

=item * You may not define method modifiers.

=item * You can extend other interfaces, not normal roles.

=back

=head2 Functions

=over

=item C<< extends $interface >>

Extends an existing interface.

Yes, the terminology "extends" is used rather than "with".

=item C<< excludes $role >>

Prevents classes that implement this interface from also composing with
this role.

=item C<< requires $method >>

The name of a method (or attribute) that any classes implementing this
interface I<must> provide.

=item C<< requires $method => \@signature >>

Declares a signature for the given method. This effectively creates an
C<around> method modifier for the method to check the signature.

As an example:

  requires log_message => [qw( Str )];

If the C<log_message> method above were called with multiple arguments,
then the additional arguments would be tolerated; the only check is that
the first argument is a string.

=item C<< const $name => $value >>

Experimental syntactic sugar for declaring constants. It's probably not a
good idea to use this yet.

=item C<< test_case { BLOCK } $name >>

Experimental syntactic sugar for embedded test cases. This extends the idea
that an interface is a contract for classes to fulfil.

The block will be called with an instance of a class claiming to implement
the interface in C<< $_ >> and should return true if the instance passes the
test and false if it fails.

  package CalculatorAPI
  {
    use MooseX::Interface;
    
    requires 'add';
    test_case { $_->add(8, 2) == 10 };
    
    requires 'subtract';
    test_case { $_->subtract(8, 2) == 6 };
    
    requires 'multiply';
    test_case { $_->multiply(8, 2) == 16 };
    
    requires 'divide';
    test_case { $_->divide(8, 2) == 4 };
  }
  
  package Calculator
  {
    use Moose;
    with 'CalculatorAPI';
    sub add      { $_[1] + $_[2] }
    sub subtract { $_[1] - $_[2] }
    sub multiply { $_[1] * $_[2] }
    sub divide   { $_[1] / $_[2] }
  }
  
  my $result = CalculatorAPI->meta->test_implementation(
    Calculator->new,
  );

The result of C<test_implementation> is an overloaded object which indicates
success when evaluated in boolean context; indicates the number of
failures in numeric context; and provides TAP-like "ok" or "not ok" in
string context. You can call methods C<passed> and C<failed> on this object
to return arrayrefs of failed test cases. Each test case is itself an
object, with C<name>, C<code> and C<associated_interface> attributes.

Do not rely on test cases being run in any particular order, or maintaining
any state between test cases. (Theoretically each test case could be run with
a separate instance of the implementing class.)

=item C<< one >>

This function checks the integrity of your role, making sure it doesn't do
anything that interfaces are not supposed to do, like defining methods.

While you don't need to call this function at all, your interface's integrity
will get checked anyway when classes implement the interface, so calling
C<one> will help you catch potential problems sooner. C<one> helpfully returns
'1', so it can be used as the magical return value at the end of a Perl
module.

(Backwards compatibility note: in MooseX::Interface versions 0.005 and below,
this was performed automatically using L<Hook::AfterRuntime>. From 0.006, the
C<one> function was introduced instead.)

=back

=begin private

=item C<< init_meta >>

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Interface>.

=head1 SEE ALSO

L<MooseX::Interface::Tutorial>,
L<MooseX::Interface::Internals>.

L<Moose::Role>, L<MooseX::ABCD>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

