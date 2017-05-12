use 5.008;
use strict;
use warnings;

package Role::Commons::Tap;

use Carp qw[croak];

BEGIN {
	use Moo::Role;
	$Role::Commons::Tap::AUTHORITY = 'cpan:TOBYINK';
	$Role::Commons::Tap::VERSION   = '0.104';
}

our $setup_for_class = sub {
	my ($role, $package, %args) = @_;
	return 0;
};

sub tap
{
	my $self = shift;
	my %flags;
	
	PARAM: while (@_)
	{
		my $next = shift;
		
		if (ref($next) eq 'CODE' or not ref $next)
		{
			my $args = ref($_[0]) eq 'ARRAY' ? shift : [];
			my $code = ref $next ? $next : sub { $self->$next(@_) };
			
			if ($flags{ EVAL })
			{
				local $_ = $self;
				eval { $code->(@$args) }
			}
			else
			{
				local $_ = $self;
				do { $code->(@$args) }
			}
			next PARAM;
		}
		
		if (ref($next) eq 'SCALAR')
		{
			if ($$next =~ m{^(no_?)?(.+)$}i)
			{
				$flags{ uc $2 } = $1 ? 0 : 1;
				next PARAM;
			}
		}
		
		croak qq/Unsupported parameter to tap: $next/;
	}
	
	return $self;
}

1;

__END__

=head1 NAME

Role::Commons::Tap - an object method which helps with chaining, inspired by Ruby

=head1 SYNOPSIS

   # This fails because the "post" method doesn't return
   # $self; it returns an HTTP::Request object.
   #
   LWP::UserAgent
      -> new
      -> post('http://www.example.com/submit', \%data)
      -> get('http://www.example.com/status');
   
   # The 'tap' method runs some code and always returns $self.
   #
   LWP::UserAgent
      -> new
      -> tap(post => [ 'http://www.example.com/submit', \%data ])
      -> get('http://www.example.com/status');
   
   # Or use a coderef...
   #
   LWP::UserAgent
      -> new
      -> tap(sub { $_->post('http://www.example.com/submit', \%data) })
      -> get('http://www.example.com/status');

=head1 DESCRIPTION

B<< DO NOT USE THIS MODULE! >> Use L<Object::Tap> or L<Object::Util>
instead. They are not drop-in replacements, but a far more sensible way
to have a C<tap> method.

This module has nothing to do with the Test Anything Protocol (TAP, see
L<Test::Harness>).

This module is a role for your class, providing it with a C<tap> method.
The C<tap> method is an aid to chaining. You can do for example:

   $object
      ->tap( sub{ $_->foo(1) } )
      ->tap( sub{ $_->bar(2) } )
      ->tap( sub{ $_->baz(3) } );

... without worrying about what the C<foo>, C<bar> and C<baz> methods
return, because C<tap> always returns its invocant.

The C<tap> method also provides a few shortcuts, so that the above can
actually be written:

   $object->tap(foo => [1], bar => [2], baz => [3]);

... but more about that later. Anyway, this module provides one
method for your class - C<tap> - which is described below.

=head2 C<< tap(@arguments) >>

This can be called as an object or class method, but is usually used as
an object method.

Each argument is processed in the order given. It is processed differently,
depending on the kind of argument it is.

=head3 Coderef arguments

An argument that is a coderef (or a blessed argument that overloads
C<< &{} >> - see L<overload>) will be executed in a context where
C<< $_ >> has been set to the invocant of the tap method C<tap>. The
return value of the coderef is ignored. For example:

   {
      package My::Class;
      use Role::Commons qw(Tap);
   }
   print My::Class->tap(
      sub { warn uc $_; return 'X' },
   );

... will warn "MY::CLASS" and then print "My::Class".

Because each argument to C<tap> is processed in order, you can provide
multiple coderefs:

   print My::Class->tap(
      sub { warn uc $_; return 'X' },
      sub { warn lc $_; return 'Y' },
   );

=head3 String arguments

A non-reference argument (i.e. a string) is treated as a shortcut
for a method call on the invocant. That is, the following two taps
are equivalent:

   $object->tap( sub{$_->foo(@_)} );
   $object->tap( 'foo' );

=head3 Arrayref arguments

An arrayref is dereferenced yielding a list. This list is passed as
an argument list when executing the previous coderef argument (or
string argument). The following three taps are equivalent:

   $object->tap(
      sub { $_->foo('bar', 'baz') },
   );
   $object->tap(
      sub { $_->foo(@_) },
      ['bar', 'baz'],
   );
   $object->tap(
      foo => ['bar', 'baz'],
   );

=head3 Scalar ref arguments

There are a handful of special scalar ref arguments that are supported:

=over

=item C<< \"EVAL" >>

This indicates that you wish for all subsequent coderefs to be wrapped in
an C<eval>, making any errors that occur within it non-fatal.

   $object->tap(\"EVAL", sub {...});

=item C<< \"NO_EVAL" >>

Switches back to the default behaviour of not wrapping coderefs in
C<eval>.

   $object->tap(
      \"EVAL",
      sub {...},   # any fatal errors will be caught and ignored
      \"NO_EVAL",
      sub {...},   # fatal errors are properly fatal again.
   );

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Role-Commons>.

=head1 SEE ALSO

L<Object::Tap>, L<Object::Util>.

L<Role::Commons>.

L<http://tea.moertel.com/articles/2007/02/07/ruby-1-9-gets-handy-new-method-object-tap>,
L<http://prepan.org/module/3Yz7PYrBLN>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

