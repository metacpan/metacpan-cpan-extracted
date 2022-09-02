use 5.006;    # for us
use 5.008008; # for Sentinel
use strict;
use warnings;

package Object::Properties;

our $VERSION = '1.003';

use Sentinel ();

sub _make_init {
	my @field  = @{ $_[0] };
	my @setter = @{ $_[1] };
	return sub {
		my $self = shift;
		my ( $hash ) = @_;
		my ( @v, @s );
		for my $i ( 0 .. $#field ) {
			next unless exists $hash->{ $field[ $i ] };
			push @s, $setter[ $i ];
			push @v, delete $hash->{ $field[ $i ] };
		}
		delete @$self{ @field } if $hash != $self;
		for my $i ( 0 .. $#v ) { $self->$_( $v[$i] ) for $s[$i] }
	};
}

sub _make_getter {
	my ( $prop ) = @_;
	return sub { $_[0]{ $prop } };
}

sub _make_getter_setter {
	my ( $prop ) = @_;
	return sub : lvalue { $_[0]{ $prop } };
}

sub _make_setter {
	my ( $prop, $munger ) = @_;
	return sub {
		local $Carp::Internal{ (__PACKAGE__) } = 1;
		$_[0]{ $prop } = $_, return for &$munger;
	};
}

sub _make_accessor {
	my ( $getter, $setter ) = @_;
	return sub : lvalue { Sentinel::sentinel get => $getter, set => $setter, obj => $_[0] };
}

sub import {
	my $class = shift;
	my $pkg = caller;

	my ( @prop, %ro, %setter );
	for ( @_ ) {
		if ( @prop and 'CODE' eq ref ) {
			$setter{ $prop[-1] } = _make_setter $prop[-1], $_;
			next;
		}
		die "Invalid accessor name '$_'" unless /\A([+]?)([^\W\d]\w*)\z/;
		$ro{ $2 } = 1 unless $1;
		push @prop, $2;
	}

	for my $prop ( @prop ) {
		my $getter = _make_getter $prop;
		my $setter = $setter{ $prop };
		my $accessor
			= $ro{ $prop } ? $getter
			: $setter      ? _make_accessor $getter, $setter
			: _make_getter_setter $prop;
		{ no strict 'refs'; *{ $pkg.'::'.$prop } = $accessor }
	}

	if ( my @sprop = grep { exists $setter{ $_ } } @prop ) {
		my $init = _make_init \@sprop, [ @setter{ @sprop } ];
		{ no strict 'refs'; *{ $pkg.'::PROPINIT' } = $init }
	}

	my $ISA = do { no strict 'refs'; \@{ $pkg.'::ISA' } };
	@$ISA = __PACKAGE__ . '::Base' unless @$ISA;

	return 1;
}

package Object::Properties::Base;

our $VERSION = '1.003';

use NEXT ();

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	local $Carp::Internal{ (__PACKAGE__) } = 1;
	$self->EVERY::LAST::PROPINIT( $self );
	return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Object::Properties - minimal-ceremony class builder

=head1 SYNOPSIS

 package SomeClass;
 use Object::Properties qw( foo +bar ), '+baz' => \&_check_baz;
 
 sub _check_baz {
     my ( $self, $value ) = @_;
     ref $value ? croak 'SomeClass->baz must not be a ref' : $value;
 }

Meanwhile, elsewhere:

 my $obj = SomeClass->new( foo => 7 );
 say $obj->foo;  # outputs 7
 $obj->foo = 42; # dies -- cannot be assigned to
 $obj->bar = 42; # no problemo; and any value goes
 say $obj->bar;  # outputs 42
 $obj->baz = ''; # no problemo encore -- except:
 $obj->baz = \1; # nope, _check_baz croaks

=head1 DESCRIPTION

This is a class builder with a minimal API that can be used as a drop-in
upgrade for L<Object::Tiny>. It adds support support for field validation and
read-write fields, realised as lvalue methods. Validation for lvalue writes
will be efficient in XS-capable environments but will still function, slowly,
in other situations.

=head1 INTERFACE

=head2 Declaring properties

The module's C<import> method accepts a list of field names and sets up an
accessor for each of them in the package it was invoked from:

 use Object::Properties qw( foo bar );

Fields are read-only by default but you can request read-write fields by
preceding them with a plus sign:

 use Object::Properties qw( readonly +readwrite );

By default, fields accept any value whatsoever, but any field name (read-only
or read-write) may be followed by a reference to a validation function:

 use Object::Properties '+hostname' => \&_munge_hostname;

Any write to such a field will invoke its validation function, with the object
instance and the new value for the field as its arguments. The return value of
this function will then be stored as the field value:

 sub _munge_hostname { lc $_[1] }

You can return an empty list from a validation function, in which case nothing
will be stored at all. This allows you to take over the entire handling of the
value if needed. (You can also return more than one value, in which case only
the first value will be stored, so that's generally a silly thing to do.)

=head2 Constructing instances

If you declare any validated fields, a method called C<PROPINIT> will be added
to your package along with the accessors. When called, it clears the values of
whatever validated fields may already have been stored in the instance, then
sets them from a hashref it expects to be passed as its only parameter. It also
deletes every key it has used from this hashref:

 my $arg = { page => 5, max_page => 20 };
 $self->PROPINIT( $arg );
 # now $arg is {} and $self->page == 5 and $self->max_page == 20

It is valid to pass the instance itself as its parameter hash:

 my $self = bless { page => 5, max_page => 20 }, $class;
 $self->PROPINIT( $self );

You will probably want to call all the C<PROPINIT>s in your inheritance chain
from your constructor (with aid from L<NEXT>):

 sub new {
     my $class = shift;
     my $self = bless { @_ }, $class;
     $self->EVERY::LAST::PROPINIT( $self );
     return $self;
 }

But if that is all your constructor would do, you will not need to write it:
C<Object::Properties::Base> contains such a C<new> method and will be added to
your C<@ISA> as your superclass if that is empty.

=head2 Inter-field depencencies

B<NOTE> that you have to take care of data dependencies. During construction,
validated fields will be set in the order you declare them, so be sure that
none of your validation functions depend on validated fields listed I<after>
them in the B<declaration> order:

 use Object::Properties
     '+max_page' => \&_munge_max_page,
     '+page'     => \&_munge_page;

 # make sure it's always a number
 sub _munge_page {
     my ( $self, $value ) = @_;
     no warnings 'numeric';
     $value > $self->max_page ? croak 'Cannot go past last page' : 0+$value;
 }

 sub _munge_max_page {
     my ( $self, $value ) = @_;
     { no warnings 'numeric'; $value = 0+$value; }
     croak 'Cannot shrink below current page' if $value < ( $self->page // 0 );
     $value;
 }

In this example, C<max_page> is I<declared> first and the function is written
to deal with the case of C<page> being uninitialized. Then, C<page> can just
depend on C<max_page> already being initialized.

Reversing the order of declarations here would make it impossible to properly
construct a new object with an initial C<page> value E<ndash> or to construct
one at all, almost. It would always cause a warning due to C<max_page> being
undefined during the comparison in C<_munge_page>, and any value other than
0 would trigger the C<croak>.

=head1 SEE ALSO

=over 4

=item * L<Object::Tiny>

=item * L<Object::Tiny::RW>

=item * L<Object::Tiny::Lvalue>

=item * L<Class::Tiny>

=item * L<Moo>

=item * L<MooX::LvalueAttribute>

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
