package Scalar::Does;

use 5.008;
use strict;
use warnings;
use if $] < 5.010, 'UNIVERSAL::DOES';

METADATA:
{
	$Scalar::Does::AUTHORITY = 'cpan:TOBYINK';
	$Scalar::Does::VERSION   = '0.203';
}

UTILITY_CLASS:
{
	package Scalar::Does::RoleChecker;
	$Scalar::Does::RoleChecker::AUTHORITY = 'cpan:TOBYINK';
	$Scalar::Does::RoleChecker::VERSION   = '0.203';
	use base "Type::Tiny";
	sub new {
		my $class = shift;
		my ($name, $coderef);
		for my $p (@_)
		{
			if (Scalar::Does::does($p, 'CODE'))  { $coderef = $p }
			if (Scalar::Does::does($p, 'HASH'))  { $coderef = $p->{where} }
			if (Scalar::Does::does($p, 'Regexp')){ $coderef = sub { $_[0] =~ $p } }
			if (not ref $p)                      { $name    = $p }
		}
		Carp::confess("Cannot make role without checker coderef or regexp") unless $coderef;
		$class->SUPER::new(display_name => $name, constraint => $coderef);
	}
	sub code { shift->constraint };
}

PRIVATE_STUFF:
{
	sub _lu {
		require lexical::underscore;
		goto \&lexical::underscore;
	}
	
	use constant MISSING_ROLE_MESSAGE => (
		"Please supply a '-role' argument when exporting custom functions, died"
	);
	
	use Carp 0 qw( confess );
	use Types::Standard 0.004 qw( -types );
}

use namespace::clean 0.19;

DEFINE_CONSTANTS:
{
	our %_CONSTANTS = (
		BOOLEAN    => q[bool],
		STRING     => q[""],
		NUMBER     => q[0+],
		REGEXP     => q[qr],
		SMARTMATCH => q[~~],
		map {; $_ => $_ } qw(
			SCALAR ARRAY HASH CODE REF GLOB
			LVALUE FORMAT IO VSTRING
		)
	);
	require constant;
	constant->import(\%_CONSTANTS);
}

EXPORTER:
{
	use base "Exporter::Tiny";
	
	our %_CONSTANTS;
	our @EXPORT    = ( "does" );
	our @EXPORT_OK = (
		qw( does overloads blessed reftype looks_like_number make_role where custom ),
		keys(%_CONSTANTS),
	);
	our %EXPORT_TAGS = (
		constants      => [ "does", keys(%_CONSTANTS) ],
		only_constants => [ keys(%_CONSTANTS) ],
		make           => [ qw( make_role where ) ],
	);
	
	sub _exporter_validate_opts
	{
		require B;
		my $class = shift;
		$_[0]{exporter} ||= sub {
			my $into = $_[0]{into};
			my ($name, $sym) = @{ $_[1] };
			for (grep ref, $into->can($name))
			{
				B::svref_2object($_)->STASH->NAME eq $into
					and _croak("Refusing to overwrite local sub '$name' with export from $class");
			}
			"namespace::clean"->import(-cleanee => $_[0]{into}, $name);
			no strict qw(refs);
			no warnings qw(redefine prototype);
			*{"$into\::$name"} = $sym;
		}
	}
}

ROLES:
{
	no warnings;
	
	my $io = "Type::Tiny"->new(
		display_name => "IO",
		constraint   => sub { require IO::Detect; IO::Detect::is_filehandle($_) },
	);
	
	our %_ROLES = (
		SCALAR   => ( ScalarRef() | Ref->parameterize('SCALAR')  | Overload->parameterize('${}') ),
		ARRAY    => ( ArrayRef()  | Ref->parameterize('ARRAY')   | Overload->parameterize('@{}') ),
		HASH     => ( HashRef()   | Ref->parameterize('HASH')    | Overload->parameterize('%{}') ),
		CODE     => ( CodeRef()   | Ref->parameterize('CODE')    | Overload->parameterize('&{}') ),
		REF      => ( Ref->parameterize('REF') ),
		GLOB     => ( GlobRef()   | Ref->parameterize('GLOB')    | Overload->parameterize('*{}') ),
		LVALUE   => ( Ref->parameterize('LVALUE') ),
		FORMAT   => ( Ref->parameterize('FORMAT') ),
		IO       => $io,
		VSTRING  => ( Ref->parameterize('VSTRING') ),
		Regexp   => ( RegexpRef() | Ref->parameterize('Regexp')  | Overload->parameterize('qr') ),
		bool     => ( Value() | Overload->complementary_type | Overload->parameterize('bool') ),
		q[""]    => ( Value() | Overload->complementary_type | Overload->parameterize('""') ),
		q[0+]    => ( Value() | Overload->complementary_type | Overload->parameterize('0+') ),
		q[<>]    => ( Overload->parameterize('<>') | $io ),
		q[~~]    => ( Overload->parameterize('~~') | Object->complementary_type ),
		q[${}]   => 'SCALAR',
		q[@{}]   => 'ARRAY',
		q[%{}]   => 'HASH',
		q[&{}]   => 'CODE',
		q[*{}]   => 'GLOB',
		q[qr]    => 'Regexp',
	);
	
	while (my ($k, $v) = each %_ROLES) { $_ROLES{$k} = $_ROLES{$v} unless ref $v }
}

PUBLIC_FUNCTIONS:
{
	use Scalar::Util 1.24 qw( blessed reftype looks_like_number );
	
	sub overloads ($;$)
	{
		unshift @_, ${+_lu} if @_ == 1;
		return unless blessed $_[0];
		goto \&overload::Method;
	}
	
	sub does ($;$)
	{
		unshift @_, ${+_lu} if @_ == 1;
		my ($thing, $role) = @_;
		
		no warnings;
		our %_ROLES;
		if (my $test = $_ROLES{$role})
		{
			return !! $test->check($thing);
		}
		
		if (blessed $role and $role->can('check'))
		{
			return !! $role->check($thing);
		}
		
		if (blessed $thing && $thing->can('DOES'))
		{
			return !! 1 if $thing->DOES($role);
		}
		elsif (UNIVERSAL::can($thing, 'can') && $thing->can('DOES'))
		{
			my $class = $thing;
			return '0E0' if $class->DOES($role);
		}
		
		return;
	}
	
	sub _generate_custom
	{
		my ($class, $name, $arg) = @_;
		my $role = $arg->{ -role } or confess MISSING_ROLE_MESSAGE;
		
		return sub (;$) {
			push @_, $role;
			goto \&does;
		}
	}
	
	sub make_role
	{
		return "Scalar::Does::RoleChecker"->new(@_);
	}
	
	sub where (&)
	{
		return +{ where => $_[0] };
	}
}

"it does"
__END__

=pod

=encoding utf8

=for stopwords vstring qr numifies

=head1 NAME

Scalar::Does - like ref() but useful

=head1 SYNOPSIS

  use Scalar::Does qw( -constants );
  
  my $object = bless {}, 'Some::Class';
  
  does($object, 'Some::Class');   # true
  does($object, '%{}');           # true
  does($object, HASH);            # true
  does($object, ARRAY);           # false

=head1 DESCRIPTION

It has long been noted that Perl would benefit from a C<< does() >> built-in.
A check that C<< ref($thing) eq 'ARRAY' >> doesn't allow you to accept an
object that uses overloading to provide an array-like interface.

=head2 Functions

=over

=item C<< does($scalar, $role) >>

Checks if a scalar is capable of performing the given role. The following
(case-sensitive) roles are predefined:

=over

=item * B<SCALAR> or B<< ${} >>

Checks if the scalar can be used as a scalar reference.

Note: this role does not check whether a scalar is a scalar (which is
obviously true) but whether it is a reference to another scalar.

=item * B<ARRAY> or B<< @{} >>

Checks if the scalar can be used as an array reference.

=item * B<HASH> or B<< %{} >>

Checks if the scalar can be used as a hash reference.

=item * B<CODE> or B<< &{} >>

Checks if the scalar can be used as a code reference.

=item * B<GLOB> or B<< *{} >>

Checks if the scalar can be used as a glob reference.

=item * B<REF>

Checks if the scalar can be used as a ref reference (i.e. a reference to
another reference).

=item * B<LVALUE>

Checks if the scalar is a reference to a special lvalue (e.g. the result
of C<< substr >> or C<< splice >>).

=item * B<IO> or B<< <> >>

Uses L<IO::Detect> to check if the scalar is a filehandle or file-handle-like
object.

(The C<< <> >> check is slightly looser, allowing objects which overload
C<< <> >>, though overloading C<< <> >> well can be a little tricky.)

=item * B<VSTRING>

Checks if the scalar is a vstring reference.

=item * B<FORMAT>

Checks if the scalar is a format reference.

=item * B<Regexp> or B<< qr >>

Checks if the scalar can be used as a quoted regular expression.

=item * B<bool>

Checks if the scalar can be used as a boolean. (It's pretty rare for this
to not be true.)

=item * B<< "" >>

Checks if the scalar can be used as a string. (It's pretty rare for this
to not be true.)

=item * B<< 0+ >>

Checks if the scalar can be used as a number. (It's pretty rare for this
to not be true.)

Note that this is far looser than C<looks_like_number> from L<Scalar::Util>.
For example, an unblessed arrayref can be used as a number (it numifies to
its reference address); the string "Hello World" can be used as a number (it
numifies to 0).

=item * B<< ~~ >>

Checks if the scalar can be used on the right hand side of a smart match.

=back

If the given I<role> is blessed, and provides a C<check> method, then
C<< does >> delegates to that.

Otherwise, if the scalar being tested is blessed, then
C<< $scalar->DOES($role) >> is called, and C<does> returns true if
the method call returned true.

If the scalar being tested looks like a Perl class name, then 
C<< $scalar->DOES($role) >> is also called, and the string "0E0" is
returned for success, which evaluates to 0 in a numeric context but
true in a boolean context.

=item C<< does($role) >>

Called with a single argument, tests C<< $_ >>. Yes, this works with lexical
C<< $_ >>.

  given ($object) {
     when(does ARRAY)  { ... }
     when(does HASH)   { ... }
  }

Note: in Scalar::Does 0.007 and below the single-argument form of C<does>
returned a curried coderef. This was changed in Scalar::Does 0.008.

=item C<< overloads($scalar, $role) >>

A function C<overloads> (which just checks overloading) is also available.

=item C<< overloads($role) >>

Called with a single argument, tests C<< $_ >>. Yes, this works with lexical
C<< $_ >>.

Note: in Scalar::Does 0.007 and below the single-argument form of C<overloads>
returned a curried coderef. This was changed in Scalar::Does 0.008.

=item C<< blessed($scalar) >>, C<< reftype($scalar) >>, C<< looks_like_number($scalar) >>

For convenience, this module can also re-export these functions from
L<Scalar::Util>. C<looks_like_number> is generally more useful than
C<< does($scalar, q[0+]) >>.

=item C<< make_role $name, where { BLOCK } >>

Returns an anonymous role object which can be used as a parameter to
C<does>. The block is arbitrary code which should check whether $_[0]
does the role.

=item C<< where { BLOCK } >>

Syntactic sugar for C<make_role>. Compatible with the C<where> function
from L<Moose::Util::TypeConstraints>, so don't worry about conflicts.

=back

=head2 Constants

The following constants may be exported for convenience:

=over

=item C<SCALAR>

=item C<ARRAY>

=item C<HASH>

=item C<CODE>

=item C<GLOB>

=item C<REF>

=item C<LVALUE>

=item C<IO>

=item C<VSTRING>

=item C<FORMAT>

=item C<REGEXP>

=item C<BOOLEAN>

=item C<STRING>

=item C<NUMBER>

=item C<SMARTMATCH>

=back

=head2 Export

By default, only C<does> is exported. This module uses L<Exporter::Tiny>, so
functions can be renamed:

  use Scalar::Does does => { -as => 'performs_role' };

Scalar::Does also plays some tricks with L<namespace::clean> to ensure that
any functions it exports to your namespace are cleaned up when you're finished
with them. This ensures that if you're writing object-oriented code C<does>
and C<overloads> will not be left hanging around as methods of your classes.
L<Moose::Object> provides a C<does> method, and you should be able to use
Scalar::Does without interfering with that.

You can import the constants (plus C<does>) using:

  use Scalar::Does -constants;

The C<make_role> and C<where> functions can be exported like this:

  use Scalar::Does -make;

Or list specific functions/constants that you wish to import:

  use Scalar::Does qw( does ARRAY HASH STRING NUMBER );

=head2 Custom Role Checks

  use Scalar::Does
    custom => { -as => 'does_array', -role => 'ARRAY' },
    custom => { -as => 'does_hash',  -role => 'HASH'  };
  
  does_array($thing);
  does_hash($thing);

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Scalar-Does>.

=head1 SEE ALSO

L<Scalar::Util>.

L<http://perldoc.perl.org/5.10.0/perltodo.html#A-does()-built-in>.

=head2 Relationship to Moose roles

Scalar::Does is not dependent on Moose, and its role-checking is not specific
to Moose's idea of roles, but it does work well with Moose roles.

Moose::Object overrides C<DOES>, so Moose objects and Moose roles should
"just work" with Scalar::Does.

  {
    package Transport;
    use Moose::Role;
  }
  
  {
    package Train;
    use Moose;
    with qw(Transport);
  }
  
  my $thomas = Train->new;
  does($thomas, 'Train');          # true
  does($thomas, 'Transport');      # true
  does($thomas, Transport->meta);  # not yet supported!

L<Mouse::Object> should be compatible enough to work as well.

See also:
L<Moose::Role>,
L<Moose::Object>,
L<UNIVERSAL>.

=head2 Relationship to Moose type constraints

L<Moose::Meta::TypeConstraint> objects, plus the constants exported by
L<MooseX::Types> libraries all provide a C<check> method, so again, should
"just work" with Scalar::Does. Type constraint strings are not supported
however.

  use Moose::Util::TypeConstraints qw(find_type_constraint);
  use MooseX::Types qw(Int);
  use Scalar::Does qw(does);
  
  my $int = find_type_constraint("Int");
  
  does( "123", $int );     # true
  does( "123", Int );      # true
  does( "123", "Int" );    # false

L<Mouse::Meta::TypeConstraint>s and L<MouseX::Types> should be compatible
enough to work as well.

See also:
L<Moose::Meta::TypeConstraint>,
L<Moose::Util::TypeConstraints>,
L<MooseX::Types>,
L<Scalar::Does::MooseTypes>.

=head2 Relationship to Type::Tiny type constraints

Types built with L<Type::Tiny> and L<Type::Library> can be used exactly as
Moose type constraint objects above.

  use Types::Standard qw(Int);
  use Scalar::Does qw(does);
  
  does(123, Int);   # true

In fact, L<Type::Tiny> and related libraries are used extensively in the
internals of Scalar::Does 0.200+.

See also:
L<Type::Tiny>,
L<Types::Standard>.

=head2 Relationship to Role::Tiny and Moo roles

Roles using Role::Tiny 1.002000 and above provide a C<DOES> method, so
should work with Scalar::Does just like Moose roles. Prior to that release,
Role::Tiny did not provide C<DOES>.

Moo's role system is based on Role::Tiny.

See also:
L<Role::Tiny>,
L<Moo::Role>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

