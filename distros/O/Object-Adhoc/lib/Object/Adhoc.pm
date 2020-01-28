use 5.008;
use strict;
use warnings;

package Object::Adhoc;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Hash::Util qw(lock_ref_keys);
use Digest::MD5 qw(md5_hex);
use Exporter::Shiny qw( object make_class );
our @EXPORT = qw( object );

BEGIN {
	*USE_XS = eval 'use Class::XSAccessor 1.19 (); 1'
		? sub () { !!1 }
		: sub () { !!0 };
};

sub object {
	my ($data, $keys) = @_;
	$keys ||= [ keys %$data ];
	bless $data, make_class($keys);
	lock_ref_keys($data, @$keys);
	$data;
}

my %made;
sub make_class {
	my ($keys) = @_;
	my $joined = join "|", sort(@$keys);
	return $made{$joined} if $made{$joined};
	
	my $class  = sprintf('%s::__ANON__::%s', __PACKAGE__, md5_hex($joined));
	
	my %getters     = map(+($_ => $_), @$keys);
	my %predicates  = map(+((/^_/?"_has$_":"has_$_")=> $_), @$keys);
	
	for my $key (@$keys) {
		if (exists $predicates{$key}) {
			delete $predicates{$key};
			require Carp;
			Carp::carp("Ambiguous method $key is getter, not predicate");
		}
		if ($key !~ /^[^\W0-9]\w*$/s) {
			require Carp;
			Carp::carp("Key $key would be bad method name, not generating methods");
			my $predicate = ($key =~ /^_/) ? "_has$key" : "has_$key";
			delete $getters{$key};
			delete $predicates{$predicate};
		}
	}
	
	if (USE_XS) {
		'Class::XSAccessor'->import(
			class             => $class,
			getters           => \%getters,
			exists_predicates => \%predicates,
		);
	}
	else {
		require B;
		my $code = "package $class;\n";
		while (my ($predicate, $key) = each %predicates) {
			my $qkey = B::perlstring($key);
			$code .= "sub $predicate :method { &Object::Adhoc::_usage if \@_ > 1; exists \$_[0]{$qkey} }\n";
		}
		while (my ($getter, $key) = each %getters) {
			my $qkey = B::perlstring($key);
			$code .= "sub $getter :method { &Object::Adhoc::_usage if \@_ > 1; \$_[0]{$qkey} }\n";
		}
		$code .= "1;\n";
		eval($code) or do { require Carp; Carp::croak($@) };
	}
	
	$made{$joined} = $class;
}

sub _usage {
	my $caller = (caller(1))[3];
	require Carp;
	local $Carp::CarpLevel = 1 + $Carp::CarpLevel;
	Carp::croak("Usage: $caller\(self)"); # mimic XS usage message
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Object::Adhoc - make objects without the hassle of defining a class first

=head1 SYNOPSIS

 use Object::Adhoc;
 
 my $object = object { name => 'Alice' };
 
 if ($object->has_name) {
   print $object->name, "\n";
 }

=head1 DESCRIPTION

Object::Adhoc is designed to be an alternative to returning hashrefs
from functions and methods. It's similar to L<Object::Anon> but doesn't
do anything special with references or overloading.

=head2 Functions

=over

=item C<< object(\%data, \@keys) >>

Returns a blessed object built from the given arrayref.

For each key in the list of keys, a getter (C<name> in the SYNOPSIS) and
predicate (C<has_name> in the SYNOPSIS) method are created.

Objects are read-only.

Note that Object::Adhoc does not make a clone of C<< %data >> before
blessing it; it is blessed directly.

=item C<< object(\%data) >>

If C<< @keys >> is not supplied, Object::Adhoc will do this:

  @keys = keys(%data);

If there are some keys that will not always be present in your data,
passing Object::Adhoc a full list of every possible key is strongly
recommended!

=item C<< make_class(\@keys) >>

Just makes the class, but doesn't bless a hashref into it. Returns a string
which is the name of the class. If called repeatedly with the same keys,
will return the same class name.

The class won't have a C<new> method; if you need to create objects, just
directly bless hashrefs into it.

It is possible to use this in an C<< @ISA >>, though that's not really
the intention of Object::Adhoc.

  package My::Class {
    use Object::Adhoc qw(make_class);
    our @ISA = make_class[qw/ foo bar baz /];
    sub new {
      my ($class, $data) = (shift, @_);
      bless $data, $class;
    }
    sub foobar {
      my ($self) = (shift);
      $self->foo . $self->bar;
    }
  }

C<make_class> is not exported by default.

=back

=head2 Diagnostics

=head3 Ambiguous method %s is getter, not predicate

Given the following:

  my $object = object {
    name     => 'Alice',
    has_name => 1,
  };

Object::Adhoc doesn't know if you want the C<has_name> method to be a
getter for the "has_name" attribute, or a predicate for the "name" attribute.
The getter wins, but it will issue a warning.

=head3 Key %s would be bad method name, not generating methods

You've got a key with a name that cannot be called as a method.
For example:

  my $alice = object { 'given name' => 'Alice' };

Perl methods cannot contain spaces, so Object::Adhoc refuses to
create the method and gives you a warning. (Technically it is possible
to create and call methods containing spaces, but it's fiddly.)

=head3 Usage %s(self)

The methods defined by Object::Adhoc expect to be invoked with
a blessed object and no other parameters.

  my $alice = object { 'name' => 'Alice' };
  $alice->name(1234);   # error

This throws an exception rather than just printing a warning.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Object-Adhoc>.

=head1 SEE ALSO

L<Object::Anon>, L<Object::Result>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

