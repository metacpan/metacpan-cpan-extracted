package Object::AutoAccessor;

require 5.004;
use strict;
use Carp;		# require 5.004

use vars qw($VERSION $AUTOLOAD);

$VERSION = '0.06';

sub new {
	my $obj = shift;
	my $class = ref($obj) || $obj;
	
	unless (@_ % 2 == 0) {
		croak "Odd number of argumentes for $class->new()";
	}
	
	my %args = @_;
	my $options = { autoload => 1 };
	$options->{$_} = $args{$_} for keys %args;
	bless $options, $class;
}

sub renew {
	my $obj = shift;
	my $class = ref($obj) || $obj;
	
	unless (@_ % 2 == 0) {
		croak "Odd number of argumentes for $class->renew()";
	}
	
	my %args = @_;
	if (ref($obj) and UNIVERSAL::isa($obj, __PACKAGE__)) {
		%args = map { $_ => $obj->{$_} } grep !/^params$/, keys %$obj;
	}
	$class->new(%args);
}

sub renew_node { shift->renew(@_) }

sub new_node {
	my $self = shift;
	
	unless (@_) {
		croak "Not enough arguments for " . ref($self) . "->new_node()";
	}
	
	my $label = shift;
	my $child = $self->renew(@_);
	$self->param($label => $child);
	$child;
}

sub node {
	my $self = shift;
	
	unless (@_) {
		return grep { $self->is_node($_) } keys(%{ $self->{params} });
	}
	
	my $first = shift;
	
	if (@_) {
		my @children = ();
		for my $label ($first,@_) {
			if ($self->is_node($label)) {
				push(@children, $self->{params}->{$label});
			}
			else {
				push(@children, undef);
			}
		}
		return wantarray ? @children : [@children];
	}
	else {
		if ($self->is_node($first)) {
			return $self->{params}->{$first};
		}
		else {
			return undef;
		}
	}
}

sub has_node { scalar shift->node() }

sub is_node {
	my $self = shift;
	
	unless (@_) {
		croak "Not enough arguments for " . ref($self) . "->is_node()";
	}
	
	my $label = shift;
	return (ref($self->{params}->{$label}) and UNIVERSAL::isa($self->{params}->{$label}, __PACKAGE__));
}

sub param {
	my $self = shift;
	
	unless (@_) {
		return grep { !$self->is_node($_) } keys(%{ $self->{params} });
	}
	
	my $first = shift;
	
	if (@_) {
		croak "Odd number of argumentes for " . ref($self) . "->param()" unless ((@_ % 2) == 1);
		
		my %hash = ($first,@_);
		
		for my $key (keys %hash) {
			my $ref = ( ref $hash{$key} );
			
			if ($ref eq 'HASH') {
				%{ $self->{params}->{$key} } = %{ $hash{$key} };
			}
			elsif ($ref eq 'ARRAY') {
				@{ $self->{params}->{$key} } = @{ $hash{$key} };
			}
			elsif ($ref eq 'SCALAR') {
				$self->{params}->{$key} = $hash{$key};
			}
			else {
				$self->{params}->{$key} = $hash{$key};
			}
		}
		
		if (@_ == 1) {
			return $self->{params}->{$first};
		}
	}
	else {
		if ($self->is_node($first)) {
			return undef;
		}
		
		my $type = ( ref $self->{params}->{$first} );
		
		if ($type eq 'HASH') {
			return \%{ $self->{params}->{$first} };
		}
		elsif ($type eq 'ARRAY') {
			return \@{ $self->{params}->{$first} };
		}
		elsif ($type eq 'SCALAR') {
			return $self->{params}->{$first};
		}
		else { # CODEREF, IO, GLOB, OBJECT
			return $self->{params}->{$first};
		}
	}
}

sub defined {
	my $self = shift;
	
	unless (@_) {
		croak "Not enough arguments for " . ref($self) . "->defined()";
	}
	
	my $label = shift;
	return CORE::defined($self->{params}->{$label});
}

sub exists {
	my $self = shift;
	
	unless (@_) {
		croak "Not enough arguments for " . ref($self) . "->exists()";
	}
	
	my $label = shift;
	return CORE::exists($self->{params}->{$label});
}

sub delete {
	my $self = shift;
	
	unless (@_) {
		croak "Not enough arguments for " . ref($self) . "->delete()";
	}
	
	my $label = shift;
	return CORE::delete($self->{params}->{$label});
}

sub undef {
	my $self = shift;
	
	unless (@_) {
		croak "Not enough arguments for " . ref($self) . "->undef()";
	}
	
	my $label = shift;
	return CORE::undef($self->{params}->{$label});
}

sub build {
	my $obj = shift;
	my $class = ref($obj) || $obj;
	
	unless (@_) {
		croak "Not enough arguments for " . $class . "->build()";
	}
	
	my $hashref = shift;
	
	unless (UNIVERSAL::isa($hashref, 'HASH')) {
		croak $class . "->build(): Cannot build: argument is not a HASH reference";
	}
	
	my $self = $class->new(@_);
	
	$self->_build($hashref);
	
	$self;
}

sub _build {
	my $self = shift;
	my $struct = shift;
	
	for my $key (keys %$struct) {
		if (UNIVERSAL::isa($struct->{$key}, 'HASH')) {
			$self->new_node($key)->_build($struct->{$key});
		}
		else {
			$self->param( $key => $struct->{$key} );
		}
	}
}

sub as_hashref {
	my $self = shift;
	
	my $hashref = {};
	
	$self->_as_hashref($hashref);
}

sub _as_hashref {
	my $self = shift;
	my $hashref = shift;
	
	for my $key (keys %{ $self->{params} }) {
		if (UNIVERSAL::isa($self->{params}->{$key}, __PACKAGE__)) {
			$hashref->{$key} = $self->node($key)->_as_hashref($hashref->{$key});
		}
		else {
			$hashref->{$key} = $self->param($key);
		}
	}
	
	$hashref;
}

sub autoload {
	my $self = shift;
	$self->{autoload} = shift if @_;
	$self->{autoload};
}

sub AUTOLOAD {
	my $self = shift;
	
	return if $AUTOLOAD =~ /::DESTROY$/;
	
	my ($method) = ($AUTOLOAD =~ /.*::(.*?)$/);
	
	if ( $self->{autoload} ) {
		if ( $self->can( $method ) ) {
			return $self->$method( @_ );
		}
		elsif ($method =~ /^([sg]et_)(.*)$/) {
			my($prefix, $name) = ($1, $2);
			if ($prefix eq 'set_') {
				return $self->param($name => @_);
			}
			else {
				carp "Too many arguments for " . ref($self) . "->get_$name\()" if @_;
				return $self->param($name);
			}
		}
		else {
			if ($self->is_node($method)) {
				if (@_) {
					undef $self->{params}->{$method};
					return $self->param($method => @_);
				}
				else {
					return $self->{params}->{$method};
				}
			}
			else {
				return $self->param($method => @_);
			}
		}
	}
	else {
		croak(ref($self) . "->$method\() : this method is not implimented");
	}
	
	return;
}

sub DESTROY {}

1;
__END__

=head1 NAME

Object::AutoAccessor - Accessor class by using AUTOLOAD

=head1 SYNOPSIS

  use Object::AutoAccessor;
  
  my $struct = {
      foo => {
          bar => {
              baz => 'BUILD OK',
          },
      },
  };
  
  # Now let's easily accomplish it.
  my $obj = Object::AutoAccessor->build($struct);
  
  print $obj->foo->bar->baz; # prints 'BUILD OK'
  
  # OK, now reverse it!
  $obj->foo->bar->baz('TO HASHREF');
  my $hashref = $obj->as_hashref;
  print $hashref->{foo}->{bar}->{baz}; # prints 'TO HASHREF';
  
  # Of course, new() can be used.
  $obj = Object::AutoAccessor->new();
  
  # setter methods
  $obj->foo('bar');
  $obj->set_foo('bar');
  $obj->param(foo => 'bar');
  
  # getter methods
  $obj->foo();
  $obj->get_foo();
  $obj->param('foo');
  
  # $obj->param() is compatible with HTML::Template->param()
  my @keywords = $obj->param();
  my $val = $obj->param('hash');
  $obj->param(key => 'val');
  
  my $tmpl = HTML::Template->new(..., associate => [$obj], ...);

=head1 DESCRIPTION

Object::AutoAccessor is a Accessor class to get/set values by
AUTOLOADed method automatically.
Moreover, param() is compatible with C<HTML::Template> module,
so you can use Object::AutoAccessor object for C<HTML::Template>'s
C<associate> option.

=head1 METHODS

=over 4

=item new ( [ OPTIONS ] )

Create a new Object::AutoAccessor object. Then you can use several options to
control object's behavior.

=item build ( HASHREF, [ OPTIONS ] )

Create a new object and accessors easily from given hashref structure.
Then you can use several options to control object's behavior.

=item as_hashref ( )

Reconstruct and returns hashref from Object::AutoAccessor object.

=item new_node ( NAME, [ OPTIONS ] )

Create a new Object::AutoAccessor object as child instance by renew() .

=item node ( NAME, [ NAME, ... ] )

An accessor method for child instance of Object::AutoAccessor object.

=item has_node ( NAME )

If object has child instance then it return TRUE.

=item renew ( [ OPTIONS ] )

Create a new Object::AutoAccessor object to remaining current options.

=item KEY ( [ VALUE ] )

This method provides an accessor that methodname is same as keyname
by using AUTOLOAD mechanism.

  # setter methods
  $obj->foo('bar');
  $obj->set_foo('bar');
  $obj->param(foo => 'bar');
  
  # getter methods
  $obj->foo();
  $obj->get_foo();
  $obj->param('foo');

=item param ( [ KEY => VALUE, ... ] )

This method is compatible with param() method of HTML::Template module.

  # set value
  $obj->param(foo => 'bar');
  $obj->param(
    foo => 'bar',
    bar => [qw(1 2 3)],
    baz => { one => 1, two => 2, three => 3 }
  );
  
  # get value
  $obj->param('foo'); # got 'bar'
  
  # get list keys of parameters
  @keys = $obj->param();

=item autoload ( BOOLEAN )

This is the method to switch behavior of the AUTOLOADed-accessor-method.
If set to 0, the object cannot use the AUTOLOADed-accessor-method such as
foo() , set_foo() and get_foo() but param() .

  $obj->new_node('foo')->param(bar => 'baz');
  
  $obj->autoload(1);
  $baz = $obj->foo->bar; # OK
  
  $obj->autoload(0);
  $baz = $obj->node('foo')->param('bar'); # OK
  $baz = $obj->foo->bar;                  # NG

=back

=head1 AUTHOR

Copyright 2005-2006 Michiya Honda, E<lt>pia@cpan.orgE<gt> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::Template>.

=cut
