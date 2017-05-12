package MooseX::Contract;

use warnings;
use strict;

use Moose ();
use Carp qw(croak);
use Moose::Exporter;
use Moose::Util::TypeConstraints;
use Moose::Util qw(add_method_modifier find_meta);

Moose::Exporter->setup_import_methods(
	with_caller => [ qw(invariant contract) ],
	as_is => [qw(check assert accepts returns void with_context)],
	also        => 'Moose',
);

=head1 NAME

MooseX::Contract - Helps you avoid Moose-stakes!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 WARNING

This module should be considered EXPERIMENTAL and should not be used in
critical applications unless you're willing to deal with all the typical
bugs that young, under-tested software has to offer!

=head1 SYNOPSIS

This module provides "Design by Contract" functionality using Moose
method hooks.

For example, in your Moose-built class:

	package MyEvenInt;

    use MooseX::Contract; # imports Moose for you!
	use Moose::Util::TypeConstraints;

	my $even_int = subtype 'Int', where { $_ % 2 == 0 };

	invariant assert { shift->{value} % 2 == 0 } '$self->{value} must be an even integer';

	has value => (
		is       => 'rw',
		isa      => $even_int,
		required => 1,
		default  => 0
	);

	contract 'add'
		=> accepts [ $even_int ]
		=> returns void,
		with_context(    # very contrived...
			pre => sub {
				my $self = shift;
				my $add  = shift;
				return [ $self->{value}, $add ];
			},
			post => assert {
				my $pre = shift;
				$pre->[0] + $pre->[1] == shift->{value};
			}
		);
	sub add {
		my $self = shift;
		my $incr = shift;
		$self->{value} += $incr;
		return;
	}

	contract 'get_multiple'
		=> accepts ['Int'],
		=> returns [$even_int];
	sub get_multiple {
		return shift->{value} * shift;
	}

	no MooseX::Contract;

=head1 DESCRIPTION

The Design by Contract (DbC) method of programming could be seen as
simply baking some simple unit test or assertions right into your regular
code path.  The set of assertions or tests for a given class is considered
that class' contract - a guarantee of how any instance of that class will
behave and appear.  This implementation of DbC provides three types of
assertions (referred to here as "contract clauses") when defining your
class' contract:

=over 4

=item C<pre> clause

This clause is attached to a specific method and is executed before
control is passed to the original method.  Typically, these could be
used to validate incoming parameters but one might also validate state
of the object itself in this type of clause.

=item C<post> clause

This clause is also attached to a specific method and is executed after
the original method has been called.  This type of DbC clause has the
opportunity to validate return values (or lack thereof) as well as the
state of the object following the method.

=item C<invariant> clause

This is a special type of DbC clause that makes assertions about the
ongoing state of the object.  These clauses are invoked after each
public method (subs that don't begin with an underscore) is called.
Unlike C<post> clauses, however, these clauses are only allowed to
inspect the object's state (not the return values of the method).

=back

The contract clauses are created using a declarative syntax as inspired
by the Moose syntax.

One item worht noting: there's no guaranteed safe way to resume execution
after a contract clause validation failure.  For instance, if a method does
something naughty and causes a C<post> or C<invariant> clause to fail,
the object in question may be irreperably broken.  Catching these errors
and ignoring them (or in some cases, trying to handle them) is not
advisable and makes the use of this module pointless.  These contract
errors should be allowed to die an ugly death.  If you're concerned
about the end user experience, you should disable all MooseX::Contract
functionality in your production code and plan to have enough coverage
in your development and test environments that you're comfortable with
the checks not being in effect.


=head1 EXPORT

The following subs are exported by default and will be removed from
the caller's namespace using C<no MooseX::Contract>.

=head2 contract

This is the core method of the module.  It sets up a contract clause for a
specific method (or methods) and uses Moose's C<around> hook to execute
the C<pre> and C<post> clauses that are specified.  Some of the "sugar"
listed below help with building up the contract that you want to express.

The first argument to C<contract> is always the method name.  Following
the method name, you must pass pairs of arguments (type => CodeRef).  The
C<type> indicates the clause of the contract (pre or post) that the CodeRef
should be applicable to.  Another special C<invar> type of clause is
very similar to the C<post> type except that it doesn't receive the return
values to verify (demonstrated below).

Typically you will only want to use C<pre> and C<post> with the C<contract>
method.

For instance (using none of the sugar supplied below):

	contract 'some_method',
		pre => sub {
			my($self,@params) = @_;
			# do some validation here, dieing if validation fails
		}
		post => sub {
			my($self, @return_values) = @_;
			# do some validation here, dieing if validation fails
		};

You can provide as many C<pre> and C<post> hook but each of them must
be preceded in the list by the lable (C<pre> or C<post>). They will be
executed in the order they are listed and the first one that fails will
result in the operation dieing.

As noted below in the PERFORMANCE section, you can short circuit all
functionality provided by this module by setting the NO_MOOSEX_CONTRACT
environment variable.  That essentially makes the C<contract> sub a no-op.

=head2 invariant

This is a special kind of contract clause that adds a C<post> clause to all
public method calls.  Typically you would use this to assert a specific
characteristic about the object itself.

=head2 check

This is pure sugar and simply returns the CodeRef that is passed in.

=head2 assert

This helper method creates a wrapper clause that will C<croak> if the
underlying anonymous sub does not return a true value.

	contract 'some_method'
		pre => assert { 
			
		};

=head2 accepts

This helper method takes an ArrayRef of Moose type constraints and creates
a C<pre> clause that verifies the type of the value or values passed
in to the method by the caller.  Any extra arguments passed to the method 
that don't have explicit restrictions given to C<accepts> will be passed
without validation (this may change in the future)

	# method_a accepts at least two Int arguments
	contract method_a => accepts ['Int', 'Int'];

	# method_b accepts no arguments
	contract method_b => accepts void;

	# works with any type that Moose will recognize
	my $cheezey = subtype 'Str', where { m/cheese/ };
	contract method_c => accepts ['MyClass', 'ArrayRef[Str]', $cheezey];

=head2 returns

This helper method creates a C<post> clause that looks at the value
or values returned by the method it's affecting.  PLEASE NOTE: these
checks only have a chance to evaluate the values that are actually
returned to the caller.  If the caller is using scalar context, then this
validation will get the value that is returned when in scalar context.
More importantly (surprisingly?)  if the caller is executing the statement
in void context, these checks won't receive any return values to evaluate
but may still validate the state of $self (the first argument received by
the post hook).

=head2 void

A simple helper method that asserts zero items were passed (useful in
specifying C<accepts> and C<returns> clauses).

=head2 with_context

This helper method wraps a C<pre> and C<post> clause with closures that allow
a values to be compared between the two clauses.  The C<SYNOPSIS> above shows
an example of how to use this functionality.

=cut

our @CARP_NOT = qw(Class::MOP::Method::Wrapped);

sub assert(&;$);
sub void() { return assert { shift; @_ == 0 } "too many values (expected 0)" }

sub invariant {
	my $caller = shift;
	my %packages = map { $_ => 1 } ($caller, grep { ! ref($_) } @_);
	my @checks = map { (invar => $_) } grep { ref($_) eq 'CODE' } @_;
	contract(
		$caller,
		[
			map { $_->name }
			grep { $_->name ne 'meta' && $_->name !~ m/^_/ && exists( $packages{ $_->original_package_name } ) }
					find_meta($caller)->get_all_methods
		],
		@checks
	);
}

sub contract {
	return if($ENV{NO_MOOSEX_CONTRACT}); # bail if contracts are turned off
	my $caller = shift;
	my $method = shift; # could be a regex or ARRAY or scalar
	my %args = (pre => [], post => [], invar => []);
	if(@_ % 2){
		croak "contract must have even pairs of arguments: @_";
	}
	while(@_){
		my($type, $code) = splice(@_,0,2);
		if(!exists($args{$type})){
			croak "unknown contract type $type";
		}
		if(ref($code) ne 'CODE'){
			croak "invalid argument $code (should be a CodeRef";
		}
		push(@{ $args{ $type } }, $code);
	}
	add_method_modifier(
		$caller, 'around',
		[
			ref($method) eq 'ARRAY' ? @$method : $method,
			sub {
				my $next = shift;
				my ($self, @params) = @_;
				foreach my $m ( @{ $args{pre} } ) {
					eval { $m->($self, @params) };
						croak "pre contract error for $method: $@" if $@;
				}
				my @retval;
				# contortions to maintain calling context
				if(defined wantarray){
					if(wantarray){
						@retval = $next->(@_);
					} else {
						$retval[0] = $next->(@_);
					}
				} else {
					# no return values available in this case...
					$next->(@_);
				}

				foreach my $m ( @{ $args{post} } ) {
					eval { $m->($self, @retval) };
					croak "post contract error for $method: $@" if $@;
				}

				foreach my $m( @{ $args{invar} } ){
						eval { $m->($self) };
						croak "invariant contract error for $method: $@" if $@;
				}
				return defined(wantarray) ? wantarray ? @retval : $retval[0] : ();
			},
		]
	);
}

sub accepts($) {
	return if(!@_);
	my $accepts = shift;
	if(ref($accepts) eq 'ARRAY'){
		return pre => _make_type_validator( "accepts", $accepts);
	} elsif(ref($accepts) eq 'CODE'){
		return pre => $accepts;
	} else {
		croak "invalid parameter to accepts: $accepts";
	}
}

sub _make_type_validator {
	my $mode = shift;
	my @expected = map { Moose::Util::TypeConstraints::find_or_parse_type_constraint($_) } @{ $_[0] };
	return sub {
		my $self = shift;
		if ( $mode eq 'accepts' && @_ < @expected ) {
			croak "$mode contract expects at least " . @expected . " values, only " . @_ . " parameters passed";
		}
		for ( my $i = 0 ; $i < @_ && $i < @expected ; $i++ ) {
			my $error = $expected[$i]->validate( $_[$i] );
			croak $error if $error;
		}
		return 1;
	};
}

sub returns($) {
	return if(!@_);
	my $returns = shift;
	if(ref($returns) eq 'ARRAY'){
		return post => _make_type_validator( "returns", $returns);
	} elsif(ref($returns) eq 'CODE') {
		return post => $returns;
	} else {
		croak "invalid parameter to accepts: $returns";
	}
}

sub check(&) { return @_ };

sub with_context {
	my %args = @_;
	if(!exists($args{pre}) || !exists($args{post})){
		croak "both 'pre' and 'post' clauses must be specified when using context";
	}
	my $context;
	return (
		pre => sub { $context = $args{pre}->(@_) },
		post => sub { $args{post}->( $context, @_ ) }
	);
}

sub assert(&;$) {
	my($code, $message) = @_;
	$message ||= "assertion failed";
	return sub {
		$code->(@_) or croak $message;
	}
}

=head1 PERFORMANCE

As the saying goes, you never get something for nothing.  That is
definitely the case with this module (or indeed any usage of Moose's
method hooks).  At the time of this writing, L<Class::MOP> claims that an
C<around> method hook is ~5x slower than a standard method invocation.
This facter doesn't include any of the actual checks that are run as
part of validating the contract so (short of doing actual profiling)
I would guess using MooseX::Contract could slow your method calls down
by up to 10x.

That is a pretty considerable drawback to using the features of this
module.  However, to mitigate this, MooseX::Contract allows you to
turn off all method wrapping if it detects the C<NO_MOOSEX_CONTRACT>
environment variable.  If you are about performance but wish to use some
of the features of this module, you might want to enable these features
only in your development or testing environment and let things run fast
and free in production.

=head1 A WORD OF CAUTION

This module is by no means a comprehensive approach to DbC.  I have
very limited experience with this style of programming and wrote this
module more as a learning project than anything.

=head1 SEE ALSO

=over 4

=item L<Sub::Contract>

=item L<Class::Contract>

=back

=head1 AUTHOR

Brian Phillips, C<< <bphillips at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-contract at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Contract>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Contract


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Contract>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Contract>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Contract>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Contract/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Brian Phillips

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MooseX::Contract
