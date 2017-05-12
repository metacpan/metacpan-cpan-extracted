package Object::Stash;

use 5.010;
use strict;
use utf8;

BEGIN {
	$Object::Stash::AUTHORITY = 'cpan:TOBYINK';
	$Object::Stash::VERSION   = '0.006';
}

use base qw/Object::Role/;

use Carp qw/croak/;
use Hash::FieldHash qw/fieldhashes/;
use Scalar::Util qw/blessed/;
use Sub::Name qw/subname/;

my %known_stashes;
my %Stashes;
BEGIN {
	fieldhashes \%known_stashes, \%Stashes;
}

sub import
{
	my ($invocant, @args) = @_;
	
	my ($caller, %args) = __PACKAGE__->parse_arguments(-method => @args);
	$args{-method} //= ['stash'];
	$args{-type}   //= 'hashref';
	
	croak sprintf("Stash type '%s' is unknown.", $args{-type})
		unless $args{-type} =~ m{^ hashref | object $}ix;
	
	__PACKAGE__->register_consumer($caller);
	
	for my $method (@{$args{-method}})
	{
		no strict 'refs';
		my $name = "$caller\::$method";
		*$name = my $ref = subname($name, sub { unshift @_, $name, lc $args{-type}; goto &_internals; });
		$known_stashes{ $ref } = $name;

		if (lc $args{-type} eq 'object')
		{
			my $name_autoload = $name . '::AUTOLOAD';
			my $autoload = sub :lvalue
			{
				my ($func) = (${$name_autoload} =~ /::([^:]+)$/);
				my $self = shift;
				$self->{$func} = shift if @_;
				$self->{$func};
			};
			*$name_autoload = subname($name_autoload, $autoload);			
		}
	}
}

sub is_stash
{
	shift if (!ref $_[0] and $_[0]->isa(__PACKAGE__));
	my ($name) = @_;
	
	return $known_stashes{ $name } if exists $known_stashes{ $name };
	return;
}

{	
	sub _internals
	{
		my ($stashname, $type, $self, @args) = @_;
		
		my (%set, @retrieve);
		if (scalar @args == 1 and ref $args[0] eq 'HASH')
		{
			%set = %{ $args[0] };
		}
		elsif (scalar @args == 1 and ref $args[0] eq 'ARRAY')
		{
			@retrieve = @{ $args[0] };
		}
		elsif (scalar @args % 2 == 0)
		{
			%set = @args;
		}
		elsif (@args)
		{
			croak "$stashname expects to be passed a hash, hash reference, or nothing.";
		}
		
		return unless (defined wantarray or @args);
		
		my $stash = $Stashes{ $self }{ $stashname };
		unless (defined $stash)
		{
			$stash = $Stashes{ $self }{ $stashname } 
			       = ($type eq 'object' ? (bless {}, $stashname) : {});
		}
			
		while (my ($k, $v) = each %set)
		{
			$stash->{$k} = $v;
		}
		
		if (@retrieve)
		{
			my @return = map { $stash->{$_} } @retrieve;
			return wantarray ? @return : \@return;
		}
		
		return $stash;
	}
}

'Secret stash';

__END__

=head1 NAME

Object::Stash - provides a Catalyst-like "stash" method for your class

=head1 SYNOPSIS

 {
   package MyClass;
   use Object::New;
   use Object::Stash 'data';
 }
 
 use feature 'say';
 use Data::Printer qw(p);
 my $obj = MyClass->new;
 p $obj->data;                     # an empty hashref
 $obj->data(foo => 1, bar => 2);   # sets values in the 'data' stash
 $obj->data({foo => 1, bar => 2}); # same
 p $obj->data;                     # hashref with keys 'foo', 'bar'
 say $obj->data->{foo};            # says '1'
 
 # Retrieve multiple values
 my @values = $obj->data(['foo', 'bar']);
 say $values[0];                   # says '1'
 say $values[1];                   # says '2'
 
 # Or in scalar context
 my $values = $obj->data(['foo', 'bar']);
 say $values->[0];                 # says '1'
 say $values->[1];                 # says '2'

=head1 DESCRIPTION

The L<Catalyst> context object has a method called stash, that provides a
hashref for storing arbitrary data associated with the object. This is
arguably a little hackish - the proper solution might be to create a slot
for each piece of information you wish to store, with appropriate accessor
methods. But often hackish will do.

(And there are non-hackish ways of using Object::Stash. Take a look at
L<Web::Magic> which uses a private stash - named with a leading underscore -
and provides public methods for accessing various things stored inside it.)

Object::Stash sets up one or more stash methods for your class. How these
methods are named depends on how Object::Stash is imported. Object::Stash
is a role, like L<Object::New> or L<Object::ID>. This means you import it,
but don't inherit from it.

=head2 Default method name

 package MyClass;
 use Object::Stash;

Creates a single method for MyClass objects. The method is called "stash".

=head2 Custom method name

 package MyClass;
 use Object::Stash 'data';

Creates a single method for MyClass objects. The method is called "data".

=head2 Multiple methods

 package MyClass;
 use Object::Stash qw/important trivial/;

Creates two stashes for MyClass objects, called "important" and "trivial".
Adding data to one stash will not affect the other stash. You could
alternatively write:

 package MyClass;
 use Object::Stash 'important'
 use Object::Stash 'trivial';

=head2 Adding stashes to other classes

 package MyClass;
 use Object::Stash -package => 'YourClass', 'my_stash';

Creates a stash called "my_stash" for YourClass objects.

=head2 Utility Functions

=over

=item C<< Object::Stash->is_stash( $coderef ) >>

Returns true if the method is a stash. For example:

  my $method = MyClass->can('trivial');
  if (Object::Stash->is_stash($method))
  {
    $method->(foo => 1, bar => 2);
  }

Can also be called as C<< Object::Stash::is_stash($coderef) >>.

=back

=head2 Stash Storage

Stashes are stored "inside-out", meaning that they will work not only with
objects which are blessed hashrefs, but also with any other type of object
internals. Dumping your object with L<Data::Dumper> or similar will not
display the contents of the stashes. (A future release of this module may
introduce other storage options, but the current inside-out storage is
likely to remain the default.)

Thanks to L<Hash::FieldHash>, an object's stashes I<should> get automatically
garbage collected once the object itself is destroyed, unless you've
maintained your own references to the stashes.

=head2 Stash Objects

While stashes are usually hashrefs, there is also an option to make stashes
themselves blessed objects. It's best to illustrate this with an example

 {
   package MyClass;
   use Object::New;
   use Object::Stash 'data', -type => 'object';
 }
 
 # All this stuff from SYNOPSIS still works...
 use feature 'say';
 use Data::Printer qw(p);
 my $obj = MyClass->new;
 p $obj->data;                     # an empty hashref
 $obj->data(foo => 1, bar => 2);   # sets values in the 'data' stash
 $obj->data({foo => 1, bar => 2}); # same
 say $obj->data->{foo};            # says '1'
 
 my @values = $obj->data(['foo', 'bar']);
 say $values[0];                   # says '1'
 say $values[1];                   # says '2'
 
 my $values = $obj->data(['foo', 'bar']);
 say $values->[0];                 # says '1'
 say $values->[1];                 # says '2'
 
 # But now you can retrieve data using accessor methods...
 say $obj->data->foo;              # says '1'
 
 # The accessors work as not just getters, but setters...
 $obj->data->foo(99);
 
 # The accessors can be treated as lvalues...
 $obj->data->foo = 100;
 $obj->data->foo++;
 
 # Cool, huh?
 say $obj->data->{foo};            # says '101'
 
 # In case you were wondering...
 say ref $obj->data;               # says 'Object::Stash::data'

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Object-Stash>.

=head1 SEE ALSO

L<Object::New>, L<Object::ID>.

L<Object::Stash::Util>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

